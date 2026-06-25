import Foundation

extension LaunchpadPackager {
    @discardableResult
    func runProcess(
        _ executable: String,
        _ arguments: [String],
        environment extraEnvironment: [String: String] = [:],
        quiet: Bool = false,
        redactedCommand: String? = nil
    ) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = root

        var environment = ProcessInfo.processInfo.environment
        for (key, value) in extraEnvironment {
            environment[key] = value
        }
        process.environment = environment

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if !quiet, !output.isEmpty {
            print(output, terminator: output.hasSuffix("\n") ? "" : "\n")
        }
        guard process.terminationStatus == 0 else {
            if quiet, !output.isEmpty {
                print(output, terminator: output.hasSuffix("\n") ? "" : "\n")
            }
            let command = redactedCommand ?? ([executable] + arguments).joined(separator: " ")
            throw PackagerError.commandFailed(command, process.terminationStatus)
        }
        return output
    }

    func notarySubmissionID(from output: String) -> String? {
        let lines = output.split(whereSeparator: \.isNewline).map(String.init)
        for (index, line) in lines.enumerated() where line.trimmingCharacters(in: .whitespaces) == "id:" {
            guard index + 1 < lines.count else { continue }
            return lines[index + 1].trimmingCharacters(in: .whitespaces)
        }
        for line in lines where line.trimmingCharacters(in: .whitespaces).hasPrefix("id:") {
            return line.replacingOccurrences(of: "id:", with: "").trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    func requireNotaryCredential(_ key: String, from options: PackagerOptions) throws {
        let hasCredential: Bool
        switch key {
        case "APPLE_ID":
            hasCredential = options.notaryAppleID?.isEmpty == false
        case "APPLE_APP_SPECIFIC_PASSWORD":
            hasCredential = options.notaryPassword?.isEmpty == false
        case "APPLE_TEAM_ID":
            hasCredential = options.notaryTeamID?.isEmpty == false
        default:
            hasCredential = false
        }
        if !hasCredential {
            throw PackagerError.missingNotaryCredential(key)
        }
    }

    func environmentValue(_ key: String, default defaultValue: String) -> String {
        ProcessInfo.processInfo.environment[key] ?? defaultValue
    }

    func relative(_ url: URL) -> String {
        let path = url.path
        let rootPath = root.path + "/"
        guard path.hasPrefix(rootPath) else { return path }
        return String(path.dropFirst(rootPath.count))
    }
}
