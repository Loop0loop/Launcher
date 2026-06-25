import Foundation

let options = PackagerOptions(arguments: Array(CommandLine.arguments.dropFirst()))

do {
    try LaunchpadPackager().run(options)
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(1)
}
