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
            paragraphElements.append(paragraph(type: "Page", text: pageHeading))

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
            return [
                paragraph(type: "Character", text: speaker),
                paragraph(type: "Dialogue", text: block.text)
            ]

        case .caption:
            return [paragraph(type: "Caption", text: block.text)]

        case .sfx:
            return [paragraph(type: "Sound Effects", text: block.text)]

        case .note:
            return [paragraph(type: "Note", text: block.text)]

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

        if block.type == .thought, modifier.isEmpty {
            return name.isEmpty ? "(thought)" : "\(name) (thought)"
        }

        if modifier.isEmpty {
            return name
        }

        return name.isEmpty ? "(\(modifier))" : "\(name) (\(modifier))"
    }

    private func paragraph(type: String, text: String) -> XMLElement {
        let paragraph = XMLElement(name: "Paragraph")
        paragraph.addAttribute(XMLNode.attribute(withName: "Type", stringValue: type) as! XMLNode)

        let textElement = XMLElement(name: "Text", stringValue: text)
        paragraph.addChild(textElement)
        return paragraph
    }
}
