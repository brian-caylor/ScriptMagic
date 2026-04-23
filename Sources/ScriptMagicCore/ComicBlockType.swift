import Foundation

public enum ComicBlockType: String, Codable, CaseIterable, Identifiable, Sendable {
    case page
    case panel
    case description
    case dialogue
    case caption
    case sfx
    case thought
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
        case .note: "Note"
        case .unknown: "Unknown"
        }
    }
}
