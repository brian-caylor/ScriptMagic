import Foundation

public enum FDXComicReaderError: Error, LocalizedError {
    case missingRoot
    case invalidXML(String)

    public var errorDescription: String? {
        switch self {
        case .missingRoot:
            "The FDX file does not contain a FinalDraft root element."
        case let .invalidXML(message):
            "The FDX file could not be parsed: \(message)"
        }
    }
}

public struct FDXComicReader {
    public init() {}

    public func read(data: Data) throws -> ComicDocumentModel {
        let xml: XMLDocument
        do {
            xml = try XMLDocument(data: data, options: [.nodePreserveWhitespace])
        } catch {
            throw FDXComicReaderError.invalidXML(error.localizedDescription)
        }

        guard let root = xml.rootElement() else {
            throw FDXComicReaderError.missingRoot
        }

        let originalXML = String(data: data, encoding: .utf8) ?? xml.xmlString
        let title = metadataValue(named: "Title", in: root) ?? "Untitled Comic"
        let issue = metadataValue(named: "Issue", in: root) ?? ""
        let writer = metadataValue(named: "Writer", in: root) ?? ""

        var model = ComicDocumentModel(
            title: title,
            issue: issue,
            writer: writer,
            pages: [],
            preservedFDX: PreservedFDXDocument(originalXML: originalXML)
        )

        let paragraphs = contentElement(in: root)?
            .children?
            .compactMap { $0 as? XMLElement }
            .filter { $0.name == "Paragraph" } ?? []

        var currentPage: ComicPage?
        var currentPanel: ComicPanel?
        var pendingSpeaker: ParsedSpeaker?

        func ensurePage() {
            if currentPage == nil {
                currentPage = ComicPage(number: model.pages.count + 1, panels: [])
            }
        }

        func ensurePanel() {
            ensurePage()
            if currentPanel == nil {
                currentPanel = ComicPanel(number: (currentPage?.panels.count ?? 0) + 1)
            }
        }

        func flushPanel() {
            guard let panel = currentPanel else { return }
            ensurePage()
            currentPage?.panels.append(panel)
            currentPanel = nil
        }

        func flushPage() {
            flushPanel()
            guard let page = currentPage else { return }
            model.pages.append(page)
            currentPage = nil
        }

        for paragraph in paragraphs {
            let rawType = paragraph.attribute(forName: "Type")?.stringValue ?? ""
            let text = paragraphText(paragraph)
            let kind = classifyParagraphType(rawType)

            switch kind {
            case .page:
                flushPage()
                let parsed = parseNumberedHeading(text, fallback: model.pages.count + 1)
                currentPage = ComicPage(number: parsed.number, title: parsed.remainder, panels: [])
                pendingSpeaker = nil

            case .panel:
                flushPanel()
                ensurePage()
                let parsed = parseNumberedHeading(text, fallback: (currentPage?.panels.count ?? 0) + 1)
                currentPanel = ComicPanel(number: parsed.number, visualDescription: parsed.remainder)
                pendingSpeaker = nil

            case .description:
                ensurePanel()
                if currentPanel?.visualDescription.isEmpty == true {
                    currentPanel?.visualDescription = text
                } else if !text.isEmpty {
                    appendDescription(text, to: &currentPanel)
                }
                pendingSpeaker = nil

            case .character:
                pendingSpeaker = parseSpeaker(text)

            case .dialogue:
                ensurePanel()
                let speaker = pendingSpeaker
                currentPanel?.textBlocks.append(
                    ComicTextBlock(
                        type: speaker?.isThought == true ? .thought : .dialogue,
                        speaker: speaker?.name ?? "",
                        modifier: speaker?.modifier ?? "",
                        text: text,
                        sourceParagraphType: rawType
                    )
                )
                pendingSpeaker = nil

            case .caption:
                ensurePanel()
                currentPanel?.textBlocks.append(ComicTextBlock(type: .caption, text: text, sourceParagraphType: rawType))
                pendingSpeaker = nil

            case .sfx:
                ensurePanel()
                currentPanel?.textBlocks.append(ComicTextBlock(type: .sfx, text: text, sourceParagraphType: rawType))
                pendingSpeaker = nil

            case .note:
                if currentPage != nil, currentPanel == nil {
                    currentPage?.beatNote = text
                } else {
                    ensurePanel()
                    currentPanel?.textBlocks.append(ComicTextBlock(type: .note, text: text, sourceParagraphType: rawType))
                }
                pendingSpeaker = nil

            case .unknown:
                ensurePanel()
                currentPanel?.textBlocks.append(
                    ComicTextBlock(
                        type: .unknown,
                        text: text,
                        preservedXML: paragraph.xmlString,
                        sourceParagraphType: rawType
                    )
                )
                pendingSpeaker = nil
            }
        }

        flushPage()

        if model.pages.isEmpty {
            model.pages = [ComicPage(number: 1, panels: [ComicPanel(number: 1)])]
        }

        return model
    }
}

enum FDXParagraphKind {
    case page
    case panel
    case description
    case character
    case dialogue
    case caption
    case sfx
    case note
    case unknown
}

struct ParsedSpeaker {
    var name: String
    var modifier: String
    var isThought: Bool
}

func contentElement(in root: XMLElement) -> XMLElement? {
    root.elements(forName: "Content").first
}

func paragraphText(_ paragraph: XMLElement) -> String {
    let textElements = paragraph.elements(forName: "Text")
    guard !textElements.isEmpty else {
        return paragraph.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    return textElements
        .compactMap(\.stringValue)
        .joined()
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

func classifyParagraphType(_ type: String) -> FDXParagraphKind {
    let normalized = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    if normalized == "page" || normalized == "comic page" || normalized == "page heading" {
        return .page
    }

    if normalized == "panel" || normalized == "comic panel" {
        return .panel
    }

    if normalized == "description" || normalized == "panel description" || normalized == "action" {
        return .description
    }

    if normalized == "character" {
        return .character
    }

    if normalized == "dialogue" {
        return .dialogue
    }

    if normalized == "caption" || normalized == "narration" {
        return .caption
    }

    if normalized == "sfx" || normalized == "sound effects" || normalized == "sound effect" {
        return .sfx
    }

    if normalized == "note" || normalized == "general" || normalized == "shot" {
        return .note
    }

    return .unknown
}

func metadataValue(named name: String, in root: XMLElement) -> String? {
    let directValue = root.elements(forName: name).first?.stringValue
    if let directValue, !directValue.isEmpty {
        return directValue
    }

    return root
        .elements(forName: "TitlePage")
        .first?
        .elements(forName: name)
        .first?
        .stringValue
}

func parseNumberedHeading(_ text: String, fallback: Int) -> (number: Int, remainder: String) {
    let scanner = Scanner(string: text)
    scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".:-#"))

    _ = scanner.scanUpToCharacters(from: .decimalDigits)
    let number = scanner.scanInt() ?? fallback
    let remainder = String(text.drop { character in
        !character.isNumber
    })
        .drop { $0.isNumber || $0 == "." || $0 == ":" || $0 == "-" || $0 == "#" || $0.isWhitespace }

    return (number, String(remainder).trimmingCharacters(in: .whitespacesAndNewlines))
}

func parseSpeaker(_ text: String) -> ParsedSpeaker {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let open = trimmed.lastIndex(of: "("), trimmed.hasSuffix(")") else {
        return ParsedSpeaker(name: trimmed, modifier: "", isThought: false)
    }

    let name = trimmed[..<open].trimmingCharacters(in: .whitespacesAndNewlines)
    let modifierStart = trimmed.index(after: open)
    let modifierEnd = trimmed.index(before: trimmed.endIndex)
    let modifier = String(trimmed[modifierStart..<modifierEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
    return ParsedSpeaker(name: name, modifier: modifier, isThought: modifier.lowercased().contains("thought"))
}

func appendDescription(_ text: String, to panel: inout ComicPanel?) {
    guard var existing = panel else { return }
    let separator = existing.visualDescription.isEmpty ? "" : "\n\n"
    existing.visualDescription += separator + text
    panel = existing
}
