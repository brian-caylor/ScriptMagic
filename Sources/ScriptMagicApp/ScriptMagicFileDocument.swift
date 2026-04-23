import SwiftUI
import UniformTypeIdentifiers
import ScriptMagicCore

struct ScriptMagicFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.finalDraftFDX, .xml] }
    static var writableContentTypes: [UTType] { [.finalDraftFDX, .xml] }

    var model: ComicDocumentModel

    init(model: ComicDocumentModel = ComicDocumentModel()) {
        self.model = model
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            self.model = ComicDocumentModel()
            return
        }

        self.model = try FDXComicReader().read(data: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        if let existingData = configuration.existingFile?.regularFileContents {
            _ = try? BackupService().createAppManagedBackup(contents: existingData, suggestedName: model.title)
        }

        let data = try FDXComicWriter().write(model)
        return FileWrapper(regularFileWithContents: data)
    }
}
