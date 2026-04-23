import Foundation

public struct ComicDocumentModel: Codable, Equatable, Sendable {
    public var title: String
    public var issue: String
    public var writer: String
    public var pages: [ComicPage]
    public var preservedFDX: PreservedFDXDocument?

    public init(
        title: String = "Untitled Comic",
        issue: String = "",
        writer: String = "",
        pages: [ComicPage] = [ComicPage(number: 1)],
        preservedFDX: PreservedFDXDocument? = nil
    ) {
        self.title = title
        self.issue = issue
        self.writer = writer
        self.pages = pages
        self.preservedFDX = preservedFDX
    }
}

public struct ComicPage: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var number: Int
    public var title: String
    public var beatNote: String
    public var panels: [ComicPanel]

    public init(
        id: UUID = UUID(),
        number: Int,
        title: String = "",
        beatNote: String = "",
        panels: [ComicPanel] = [ComicPanel(number: 1)]
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.beatNote = beatNote
        self.panels = panels
    }
}

public struct ComicPanel: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var number: Int
    public var visualDescription: String
    public var textBlocks: [ComicTextBlock]

    public init(
        id: UUID = UUID(),
        number: Int,
        visualDescription: String = "",
        textBlocks: [ComicTextBlock] = []
    ) {
        self.id = id
        self.number = number
        self.visualDescription = visualDescription
        self.textBlocks = textBlocks
    }
}

public struct ComicTextBlock: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var type: ComicBlockType
    public var speaker: String
    public var modifier: String
    public var text: String
    public var preservedXML: String?
    public var sourceParagraphType: String?

    public init(
        id: UUID = UUID(),
        type: ComicBlockType,
        speaker: String = "",
        modifier: String = "",
        text: String = "",
        preservedXML: String? = nil,
        sourceParagraphType: String? = nil
    ) {
        self.id = id
        self.type = type
        self.speaker = speaker
        self.modifier = modifier
        self.text = text
        self.preservedXML = preservedXML
        self.sourceParagraphType = sourceParagraphType
    }
}

public struct PreservedFDXDocument: Codable, Equatable, Sendable {
    public var originalXML: String

    public init(originalXML: String) {
        self.originalXML = originalXML
    }
}
