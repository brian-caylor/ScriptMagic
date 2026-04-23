import Foundation

public enum BackupServiceError: Error, LocalizedError {
    case missingSource

    public var errorDescription: String? {
        switch self {
        case .missingSource:
            "A saved FDX file is required before a backup can be created."
        }
    }
}

public struct BackupService {
    public var backupDirectoryName: String

    public init(backupDirectoryName: String = ".scriptmagic-backups") {
        self.backupDirectoryName = backupDirectoryName
    }

    @discardableResult
    public func createBackup(for fileURL: URL) throws -> URL {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw BackupServiceError.missingSource
        }

        let folder = fileURL.deletingLastPathComponent().appendingPathComponent(backupDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: Date())
        let baseName = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension.isEmpty ? "fdx" : fileURL.pathExtension
        let backupURL = folder.appendingPathComponent("\(baseName)-\(timestamp).\(ext)")
        try FileManager.default.copyItem(at: fileURL, to: backupURL)
        return backupURL
    }

    @discardableResult
    public func createAppManagedBackup(contents data: Data, suggestedName: String = "ScriptMagic") throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let folder = support
            .appendingPathComponent("ScriptMagic", isDirectory: true)
            .appendingPathComponent("Backups", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: Date())
        let safeName = suggestedName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        let backupURL = folder.appendingPathComponent("\(safeName)-\(timestamp).fdx")
        try data.write(to: backupURL, options: .atomic)
        return backupURL
    }
}
