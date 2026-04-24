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
    public var layout: ComicPageLayout
    public var expectedPanelCount: Int?
    public var panels: [ComicPanel]

    public init(
        id: UUID = UUID(),
        number: Int,
        title: String = "",
        beatNote: String = "",
        layout: ComicPageLayout = .standard,
        expectedPanelCount: Int? = nil,
        panels: [ComicPanel] = [ComicPanel(number: 1)]
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.beatNote = beatNote
        self.layout = layout
        self.expectedPanelCount = expectedPanelCount
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
    public var delivery: ComicDelivery
    public var text: String
    public var isLocked: Bool
    public var preservedXML: String?
    public var sourceParagraphType: String?

    public init(
        id: UUID = UUID(),
        type: ComicBlockType,
        speaker: String = "",
        modifier: String = "",
        delivery: ComicDelivery = .none,
        text: String = "",
        isLocked: Bool = false,
        preservedXML: String? = nil,
        sourceParagraphType: String? = nil
    ) {
        self.id = id
        self.type = type
        self.speaker = speaker
        self.modifier = modifier
        self.delivery = delivery
        self.text = text
        self.isLocked = isLocked
        self.preservedXML = preservedXML
        self.sourceParagraphType = sourceParagraphType
    }
}

public enum ComicPageLayout: String, Codable, CaseIterable, Identifiable, Sendable {
    case standard
    case splash
    case halfSplash
    case doublePageSpread
    case montage
    case grid
    case custom

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .standard: "Standard"
        case .splash: "Splash"
        case .halfSplash: "Half-Splash"
        case .doublePageSpread: "Double-Page Spread"
        case .montage: "Montage"
        case .grid: "Grid"
        case .custom: "Custom"
        }
    }
}

public enum ComicDelivery: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case op
    case off
    case phone
    case voicemail
    case memory
    case thought
    case whisper
    case custom

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: "None"
        case .op: "OP"
        case .off: "OFF"
        case .phone: "Phone"
        case .voicemail: "Voicemail"
        case .memory: "Memory"
        case .thought: "Thought"
        case .whisper: "Whisper"
        case .custom: "Custom"
        }
    }
}

public struct PreservedFDXDocument: Codable, Equatable, Sendable {
    public var originalXML: String

    public init(originalXML: String) {
        self.originalXML = originalXML
    }
}
