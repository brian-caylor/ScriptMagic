import Foundation

public enum ComicBlockType: String, Codable, CaseIterable, Identifiable, Sendable {
    case page
    case panel
    case description
    case dialogue
    case caption
    case sfx
    case thought
    case sign
    case screen
    case textMessage
    case chyron
    case titleCard
    case note
    case unknown

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .page: "Page"
        case .panel: "Panel"
        case .description: "Description"
        case .dialogue: "Dialogue"
        case .caption: "Caption"
        case .sfx: "SFX"
        case .thought: "Thought"
        case .sign: "Sign"
        case .screen: "Screen"
        case .textMessage: "Text Message"
        case .chyron: "Chyron"
        case .titleCard: "Title Card"
        case .note: "Note"
        case .unknown: "Unknown"
        }
    }

    public var isReaderFacingText: Bool {
        switch self {
        case .dialogue, .caption, .sfx, .thought, .sign, .screen, .textMessage, .chyron, .titleCard:
            true
        case .page, .panel, .description, .note, .unknown:
            false
        }
    }
}
