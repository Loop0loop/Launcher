import AppKit
import Dispatch
import ImageIO
import LaunchpadCore
import SwiftUI

/// 아이콘 로드를 메인 스레드에서 분리한다. 각 아이콘 뷰(`LoadedIcon`)가 자기 아이콘만
/// `.task`로 로드하므로, 한 아이콘이 로드돼도 그리드 전체가 아니라 그 뷰 하나만 갱신된다.
/// (1) 메모리 LRU hit → 즉시 반환, (2) miss → 백그라운드(디스크 캐시 → `NSWorkspace.icon`).
@MainActor
final class IconCache: ObservableObject {
    private let memory = NSCache<NSString, NSImage>()
    private let diskDir: URL
    private var memoryPressureSource: (any DispatchSourceMemoryPressure)?

    init() {
        memory.countLimit = 35
        memory.totalCostLimit = 6 * 1024 * 1024
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("Launch/icons", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.diskDir = dir

        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
        source.setEventHandler { [weak self] in self?.clear() }
        source.resume()
        memoryPressureSource = source
    }

    deinit {
        memoryPressureSource?.cancel()
    }

    /// 메모리 히트는 즉시, 미스는 백그라운드 로드 후 반환. 호출한 뷰 하나만 갱신된다.
    func loadImage(
        for app: LaunchApp,
        size: CGFloat = LaunchConstants.Launcher.maxIconSize,
        cacheInMemory: Bool = true
    ) async -> NSImage? {
        let key = Self.memoryKey(path: app.path, size: size)
        if cacheInMemory, let cached = memory.object(forKey: key) {
            return cached
        }
        let cacheURL = diskDir.appendingPathComponent(Self.diskKey(path: app.path, size: size))
        let image = await Task.detached(priority: .utility) {
            autoreleasepool {
                let loaded = Self.loadFromDisk(url: cacheURL, size: size)
                    ?? Self.loadFromWorkspace(path: app.path, size: size)
                if let loaded { Self.saveToDisk(loaded, url: cacheURL) }
                return loaded
            }
        }.value
        guard !Task.isCancelled else { return nil }
        guard let image else { return nil }
        guard cacheInMemory else { return image }
        guard memory.object(forKey: key) == nil else { return memory.object(forKey: key) }
        memory.setObject(image, forKey: key, cost: Self.byteCost(image: image))
        return image
    }

    func clear() {
        memory.removeAllObjects()
    }

    // ponytail: djb2 + lastPathComponent — 경로→파일명 매핑. 해시 충돌 확률 무시 가능,
    // 충돌 시 해당 아이콘만 캐시 미스(재로드). 정확성이 중요하면 SHA256으로 교체.
    private static func diskKey(path: String, size: CGFloat) -> String {
        var hash = 5381
        for byte in path.utf8 { hash = ((hash << 5) &+ hash) &+ Int(byte) }
        return "\(pixelSize(for: size))_\(hash)_\((path as NSString).lastPathComponent).png"
    }

    private static func memoryKey(path: String, size: CGFloat) -> NSString {
        "\(pixelSize(for: size))_\(path)" as NSString
    }

    private nonisolated static func pixelSize(for size: CGFloat) -> Int {
        Int(ceil(size * 2))
    }

    private nonisolated static func loadFromDisk(url: URL, size: CGFloat) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return thumbnail(from: source, size: size)
    }

    private nonisolated static func loadFromWorkspace(path: String, size: CGFloat) -> NSImage? {
        rasterized(NSWorkspace.shared.icon(forFile: path), size: size)
    }

    private nonisolated static func saveToDisk(_ image: NSImage, url: URL) {
        guard let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first,
              let png = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: url, options: .atomic)
    }

    private nonisolated static func thumbnail(from source: CGImageSource, size: CGFloat) -> NSImage? {
        let px = pixelSize(for: size)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: px
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let image = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
        image.cacheMode = .never
        return image
    }

    private nonisolated static func rasterized(_ image: NSImage, size: CGFloat) -> NSImage? {
        let px = pixelSize(for: size)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: px,
            pixelsHigh: px,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        rep.size = NSSize(width: size, height: size)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
        NSGraphicsContext.restoreGraphicsState()

        let result = NSImage(size: NSSize(width: size, height: size))
        result.addRepresentation(rep)
        result.cacheMode = .never
        return result
    }

    private nonisolated static func byteCost(image: NSImage) -> Int {
        guard let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first else {
            return Int(ceil(image.size.width * 2) * ceil(image.size.height * 2) * 4)
        }
        return rep.pixelsWide * rep.pixelsHigh * max(rep.bitsPerPixel / 8, 4)
    }
}

/// 자기 아이콘만 비동기로 로드하는 뷰. `.task(id:)`가 appear 시 한 번 로드하고,
/// 로드 완료 시 이 뷰만 갱신된다(그리드 전체 무효화 없음). `loadSize`는 캐시 해상도,
/// `displaySize`는 화면 표시 크기(폴더 미니 아이콘처럼 작게 그릴 때 분리).
struct LoadedIcon: View {
    let app: LaunchApp
    let displaySize: CGFloat
    let loadSize: CGFloat
    let loadsImage: Bool
    let cachesImageInMemory: Bool
    @EnvironmentObject private var iconCache: IconCache
    @State private var image: NSImage?

    init(
        app: LaunchApp,
        displaySize: CGFloat,
        loadSize: CGFloat? = nil,
        loadsImage: Bool = true,
        cachesImageInMemory: Bool = true
    ) {
        self.app = app
        self.displaySize = displaySize
        self.loadSize = loadSize ?? displaySize
        self.loadsImage = loadsImage
        self.cachesImageInMemory = cachesImageInMemory
    }

    var body: some View {
        IconImage(image: image, size: displaySize)
            .task(id: "\(app.path)-\(loadSize)-\(loadsImage)-\(cachesImageInMemory)") {
                guard loadsImage else {
                    image = nil
                    return
                }
                image = await iconCache.loadImage(for: app, size: loadSize, cacheInMemory: cachesImageInMemory)
            }
            .onChange(of: loadsImage) { _, newValue in
                if !newValue { image = nil }
            }
            .onDisappear {
                image = nil
            }
    }
}

/// 옵셔널 아이콘을 렌더: 로드 전에는 옅은 글래스 placeholder를 보여준다.
struct IconImage: View {
    let image: NSImage?
    let size: CGFloat

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
            } else {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .stroke(.white.opacity(0.05), lineWidth: 1)
                    )
            }
        }
        .frame(width: size, height: size)
    }
}
