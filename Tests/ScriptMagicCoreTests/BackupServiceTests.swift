import XCTest
@testable import ScriptMagicCore

final class BackupServiceTests: XCTestCase {
    func testCreatesTimestampedBackupBesideFDXFile() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let fileURL = folder.appendingPathComponent("sample.fdx")
        try Data("<FinalDraft><Content /></FinalDraft>".utf8).write(to: fileURL)

        let backupURL = try BackupService().createBackup(for: fileURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
        XCTAssertEqual(backupURL.deletingLastPathComponent().lastPathComponent, ".scriptmagic-backups")
        XCTAssertTrue(backupURL.lastPathComponent.hasPrefix("sample-"))
        XCTAssertEqual(try Data(contentsOf: backupURL), try Data(contentsOf: fileURL))
    }

    func testCreatesAppManagedBackupFromExistingContents() throws {
        let data = Data("<FinalDraft><Content /></FinalDraft>".utf8)
        let backupURL = try BackupService().createAppManagedBackup(contents: data, suggestedName: "Night Arcade")
        defer { try? FileManager.default.removeItem(at: backupURL) }

        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
        XCTAssertTrue(backupURL.path.contains("ScriptMagic/Backups"))
        XCTAssertTrue(backupURL.lastPathComponent.hasPrefix("Night Arcade-"))
        XCTAssertEqual(try Data(contentsOf: backupURL), data)
    }
}
