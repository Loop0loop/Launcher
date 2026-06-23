import Foundation
import LaunchCore

let url = URL(fileURLWithPath: "/tmp/Fake App.app")
assert(AppCatalog.displayName(for: url) == "Fake App")

let missing = URL(fileURLWithPath: "/tmp/launch-missing-\(UUID().uuidString)")
assert(AppCatalog.scan(roots: [missing]).isEmpty)

let apps = [
    LaunchApp(id: "a", name: "A", path: "/A.app"),
    LaunchApp(id: "b", name: "B", path: "/B.app"),
    LaunchApp(id: "c", name: "C", path: "/C.app")
]
assert(LayoutOrder.apply(["c", "a"], to: apps).map(\.id) == ["c", "a", "b"])
assert(LayoutOrder.move("c", before: "b", in: ["a", "b", "c"]) == ["a", "c", "b"])

print("LaunchCheck OK")
