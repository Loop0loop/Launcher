import AppKit
import LaunchpadCore
import SwiftUI

/// 아이콘 로드를 메인 스레드에서 분리한다. 각 아이콘 뷰(`LoadedIcon`)가 자기 아이콘만
/// `.task`로 로드하므로, 한 아이콘이 로드돼도 그리드 전체가 아니라 그 뷰 하나만 갱신된다.
/// (1) 메모리 LRU hit → 즉시 반환, (2) miss → 백그라운드(디스크 캐시 → `NSWorkspace.icon`).
@MainActor
final class IconCache: ObservableObject {
    private var memory: [String: NSImage] = [:]
    private var lru: [String] = []
    private let limit = 256
    private let diskDir: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("Launch/icons", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.diskDir = dir
    }

    /// 메모리 히트는 즉시, 미스는 백그라운드 로드 후 반환. 호출한 뷰 하나만 갱신된다.
    func loadImage(for app: LaunchApp, size: CGFloat = LaunchConstants.Launcher.maxIconSize) async -> NSImage? {
        let key = app.path
        if let cached = memory[key] {
            markRecent(key)
            return cached
        }
        let cacheURL = diskDir.appendingPathComponent(Self.diskKey(path: key, size: size))
        let image = await Task.detached(priority: .utility) {
            let loaded = Self.loadFromDisk(url: cacheURL, size: size)
                ?? Self.loadFromWorkspace(path: key, size: size)
            if let loaded { Self.saveToDisk(loaded, url: cacheURL) }
            return loaded
        }.value
        guard let image else { return nil }
        guard memory[key] == nil else { markRecent(key); return memory[key] }
        memory[key] = image
        markRecent(key)
        evictIfNeeded()
        return image
    }

    func clear() {
        memory.removeAll()
        lru.removeAll()
    }

    private func markRecent(_ key: String) {
        lru.removeAll { $0 == key }
        lru.append(key)
    }

    private func evictIfNeeded() {
        while memory.count > limit, let oldest = lru.first {
            lru.removeFirst()
            memory.removeValue(forKey: oldest)
        }
    }

    // ponytail: djb2 + lastPathComponent — 경로→파일명 매핑. 해시 충돌 확률 무시 가능,
    // 충돌 시 해당 아이콘만 캐시 미스(재로드). 정확성이 중요하면 SHA256으로 교체.
    private static func diskKey(path: String, size: CGFloat) -> String {
        var hash = 5381
        for byte in path.utf8 { hash = ((hash << 5) &+ hash) &+ Int(byte) }
        return "\(Int(size))_\(hash)_\((path as NSString).lastPathComponent).png"
    }

    private nonisolated static func loadFromDisk(url: URL, size: CGFloat) -> NSImage? {
        guard let data = try? Data(contentsOf: url), let image = NSImage(data: data) else { return nil }
        let px = size * 2
        image.size = NSSize(width: px, height: px)
        return image
    }

    private nonisolated static func loadFromWorkspace(path: String, size: CGFloat) -> NSImage? {
        let image = NSWorkspace.shared.icon(forFile: path)
        let px = size * 2
        image.size = NSSize(width: px, height: px)
        return image
    }

    private nonisolated static func saveToDisk(_ image: NSImage, url: URL) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: url, options: .atomic)
    }
}

/// 자기 아이콘만 비동기로 로드하는 뷰. `.task(id:)`가 appear 시 한 번 로드하고,
/// 로드 완료 시 이 뷰만 갱신된다(그리드 전체 무효화 없음). `loadSize`는 캐시 해상도,
/// `displaySize`는 화면 표시 크기(폴더 미니 아이콘처럼 작게 그릴 때 분리).
struct LoadedIcon: View {
    let app: LaunchApp
    let displaySize: CGFloat
    let loadSize: CGFloat
    @EnvironmentObject private var iconCache: IconCache
    @State private var image: NSImage?

    init(app: LaunchApp, displaySize: CGFloat, loadSize: CGFloat? = nil) {
        self.app = app
        self.displaySize = displaySize
        self.loadSize = loadSize ?? displaySize
    }

    var body: some View {
        IconImage(image: image, size: displaySize)
            .task(id: app.path) {
                image = await iconCache.loadImage(for: app, size: loadSize)
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
