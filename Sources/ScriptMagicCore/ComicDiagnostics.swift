import Foundation

public struct ComicDiagnostic: Equatable, Identifiable, Sendable {
    public enum Severity: String, Sendable {
        case note
        case warning
    }

    public var id: String
    public var severity: Severity
    public var message: String
    public var pageNumber: Int?
    public var panelNumber: Int?

    public init(
        id: String,
        severity: Severity,
        message: String,
        pageNumber: Int? = nil,
        panelNumber: Int? = nil
    ) {
        self.id = id
        self.severity = severity
        self.message = message
        self.pageNumber = pageNumber
        self.panelNumber = panelNumber
    }
}

public enum ComicDiagnostics {
    public static func evaluate(_ document: ComicDocumentModel) -> [ComicDiagnostic] {
        var diagnostics: [ComicDiagnostic] = []

        for page in document.pages {
            var seenPanels: Set<Int> = []
            var expectedPanel = 1

            if let expectedPanelCount = page.expectedPanelCount, expectedPanelCount != page.panels.count {
                diagnostics.append(
                    ComicDiagnostic(
                        id: "page-\(page.number)-panel-count",
                        severity: .warning,
                        message: "Page \(page.number) declares \(expectedPanelCount) panels but has \(page.panels.count).",
                        pageNumber: page.number
                    )
                )
            }

            for panel in page.panels {
                if panel.visualDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    diagnostics.append(
                        ComicDiagnostic(
                            id: "page-\(page.number)-panel-\(panel.number)-missing-description",
                            severity: .warning,
                            message: "Panel \(panel.number) is missing a visual description.",
                            pageNumber: page.number,
                            panelNumber: panel.number
                        )
                    )
                }

                if seenPanels.contains(panel.number) {
                    diagnostics.append(
                        ComicDiagnostic(
                            id: "page-\(page.number)-panel-\(panel.number)-duplicate",
                            severity: .warning,
                            message: "Panel \(panel.number) is duplicated on page \(page.number).",
                            pageNumber: page.number,
                            panelNumber: panel.number
                        )
                    )
                }

                if panel.number != expectedPanel {
                    diagnostics.append(
                        ComicDiagnostic(
                            id: "page-\(page.number)-panel-\(panel.number)-sequence",
                            severity: .note,
                            message: "Panel numbering jumps from \(expectedPanel) to \(panel.number).",
                            pageNumber: page.number,
                            panelNumber: panel.number
                        )
                    )
                    expectedPanel = panel.number
                }

                seenPanels.insert(panel.number)
                expectedPanel += 1

                let panelLetteringWords = panel.textBlocks.reduce(0) { total, block in
                    guard block.type.isReaderFacingText else { return total }
                    return total + wordCount(block.text)
                }

                if panelLetteringWords > 50 {
                    diagnostics.append(
                        ComicDiagnostic(
                            id: "page-\(page.number)-panel-\(panel.number)-dense-lettering",
                            severity: .warning,
                            message: "Panel \(panel.number) has \(panelLetteringWords) dialogue/caption words.",
                            pageNumber: page.number,
                            panelNumber: panel.number
                        )
                    )
                }

                for block in panel.textBlocks where block.type.isReaderFacingText {
                    let words = wordCount(block.text)
                    if words > 25 {
                        diagnostics.append(
                            ComicDiagnostic(
                                id: "page-\(page.number)-panel-\(panel.number)-block-\(block.id)-long",
                                severity: .note,
                                message: "\(block.type.displayName) has \(words) words.",
                                pageNumber: page.number,
                                panelNumber: panel.number
                            )
                        )
                    }
                }
            }
        }

        return diagnostics
    }

    public static func wordCount(_ text: String) -> Int {
        text
            .split { character in
                character.isWhitespace || character.isNewline
            }
            .count
    }
}
