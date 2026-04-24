import Foundation

public enum FDXComicWriterError: Error, LocalizedError {
    case cannotCreateDocument

    public var errorDescription: String? {
        switch self {
        case .cannotCreateDocument:
            "The FDX document could not be created."
        }
    }
}

public struct FDXComicWriter {
    public init() {}

    public func write(_ model: ComicDocumentModel) throws -> Data {
        let xmlDocument = document(from: model)
        guard let root = xmlDocument.rootElement() else {
            throw FDXComicWriterError.cannotCreateDocument
        }

        root.setAttributesWith([
            "DocumentType": "Script",
            "Template": "No",
            "Version": root.attribute(forName: "Version")?.stringValue ?? "1"
        ])

        upsertMetadata(in: root, model: model)

        let content = contentElement(in: root) ?? {
            let element = XMLElement(name: "Content")
            root.addChild(element)
            return element
        }()

        removeChildren(from: content)
        for paragraph in makeParagraphs(from: model) {
            content.addChild(paragraph)
        }

        let xml = xmlDocument.xmlString(options: [.nodePrettyPrint])
        return Data(xml.utf8)
    }

    private func document(from model: ComicDocumentModel) -> XMLDocument {
        if
            let originalXML = model.preservedFDX?.originalXML,
            let data = originalXML.data(using: .utf8),
            let xml = try? XMLDocument(data: data, options: [.nodePreserveWhitespace]),
            xml.rootElement() != nil
        {
            return xml
        }

        let root = XMLElement(name: "FinalDraft")
        let document = XMLDocument(rootElement: root)
        document.version = "1.0"
        document.characterEncoding = "UTF-8"
        root.addChild(XMLElement(name: "Content"))
        return document
    }

    private func upsertMetadata(in root: XMLElement, model: ComicDocumentModel) {
        setChildText(name: "Title", value: model.title, in: root)
        setChildText(name: "Issue", value: model.issue, in: root)
        setChildText(name: "Writer", value: model.writer, in: root)
    }

    private func setChildText(name: String, value: String, in root: XMLElement) {
        let element = root.elements(forName: name).first ?? {
            let element = XMLElement(name: name)
            root.insertChild(element, at: 0)
            return element
        }()
        element.stringValue = value
    }

    private func removeChildren(from element: XMLElement) {
        while element.childCount > 0 {
            element.removeChild(at: 0)
        }
    }

    private func makeParagraphs(from model: ComicDocumentModel) -> [XMLElement] {
        var paragraphElements: [XMLElement] = []

        for page in model.pages {
            let pageHeading = page.title.isEmpty ? "PAGE \(page.number)" : "PAGE \(page.number): \(page.title)"
            var attributes = ["Layout": page.layout.rawValue]
            if let expectedPanelCount = page.expectedPanelCount {
                attributes["ExpectedPanels"] = "\(expectedPanelCount)"
            }
            paragraphElements.append(paragraph(type: "Page", text: pageHeading, attributes: attributes))

            if !page.beatNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                paragraphElements.append(paragraph(type: "Note", text: page.beatNote))
            }

            for panel in page.panels {
                paragraphElements.append(paragraph(type: "Panel", text: "Panel \(panel.number)"))

                if !panel.visualDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    paragraphElements.append(paragraph(type: "Description", text: panel.visualDescription))
                }

                for block in panel.textBlocks {
                    paragraphElements.append(contentsOf: paragraphs(for: block))
                }
            }
        }

        return paragraphElements
    }

    private func paragraphs(for block: ComicTextBlock) -> [XMLElement] {
        switch block.type {
        case .dialogue, .thought:
            let speaker = formattedSpeaker(for: block)
            var characterAttributes: [String: String] = [:]
            if block.delivery != .none {
                characterAttributes["Delivery"] = block.delivery.rawValue
            }
            return [
                paragraph(type: "Character", text: speaker, attributes: characterAttributes),
                paragraph(type: "Dialogue", text: block.text, attributes: lockedAttributes(for: block))
            ]

        case .caption:
            var attributes = lockedAttributes(for: block)
            if !block.speaker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                attributes["Speaker"] = block.speaker.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return [paragraph(type: "Caption", text: block.text, attributes: attributes)]

        case .sfx:
            return [paragraph(type: "Sound Effects", text: block.text, attributes: lockedAttributes(for: block))]

        case .sign:
            return [paragraph(type: "Sign", text: block.text, attributes: lockedAttributes(for: block))]

        case .screen:
            return [paragraph(type: "Screen", text: block.text, attributes: lockedAttributes(for: block))]

        case .textMessage:
            return [paragraph(type: "Text Message", text: block.text, attributes: lockedAttributes(for: block))]

        case .chyron:
            return [paragraph(type: "Chyron", text: block.text, attributes: lockedAttributes(for: block))]

        case .titleCard:
            return [paragraph(type: "Title Card", text: block.text, attributes: lockedAttributes(for: block))]

        case .note:
            return [paragraph(type: "Note", text: block.text, attributes: lockedAttributes(for: block))]

        case .unknown:
            if
                let preservedXML = block.preservedXML,
                let xml = try? XMLDocument(xmlString: preservedXML, options: []),
                let element = xml.rootElement()?.copy() as? XMLElement
            {
                return [element]
            }
            return [paragraph(type: block.sourceParagraphType ?? "General", text: block.text)]

        case .page, .panel, .description:
            return [paragraph(type: block.sourceParagraphType ?? "General", text: block.text)]
        }
    }

    private func formattedSpeaker(for block: ComicTextBlock) -> String {
        let name = block.speaker.trimmingCharacters(in: .whitespacesAndNewlines)
        let modifier = block.modifier.trimmingCharacters(in: .whitespacesAndNewlines)

        if block.delivery != .none, block.delivery != .custom {
            let delivery = block.delivery.displayName
            return name.isEmpty ? "(\(delivery))" : "\(name) (\(delivery))"
        }

        if block.type == .thought, modifier.isEmpty {
            return name.isEmpty ? "(thought)" : "\(name) (thought)"
        }

        if modifier.isEmpty {
            return name
        }

        return name.isEmpty ? "(\(modifier))" : "\(name) (\(modifier))"
    }

    private func lockedAttributes(for block: ComicTextBlock) -> [String: String] {
        block.isLocked ? ["Locked": "true"] : [:]
    }

    private func paragraph(type: String, text: String, attributes: [String: String] = [:]) -> XMLElement {
        let paragraph = XMLElement(name: "Paragraph")
        paragraph.addAttribute(XMLNode.attribute(withName: "Type", stringValue: type) as! XMLNode)
        for (name, value) in attributes.sorted(by: { $0.key < $1.key }) where !value.isEmpty {
            paragraph.addAttribute(XMLNode.attribute(withName: name, stringValue: value) as! XMLNode)
        }

        let textElement = XMLElement(name: "Text", stringValue: text)
        paragraph.addChild(textElement)
        return paragraph
    }
}
