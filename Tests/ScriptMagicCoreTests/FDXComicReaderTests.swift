import XCTest
@testable import ScriptMagicCore

final class FDXComicReaderTests: XCTestCase {
    func testReadsComicFDXIntoPagePanelModel() throws {
        let model = try readFixture("sample-comic")

        XCTAssertEqual(model.title, "Night Arcade")
        XCTAssertEqual(model.issue, "1")
        XCTAssertEqual(model.writer, "Brian Caylor")
        XCTAssertEqual(model.pages.count, 1)
        XCTAssertEqual(model.pages[0].number, 1)
        XCTAssertEqual(model.pages[0].title, "Cold Open")
        XCTAssertEqual(model.pages[0].panels.count, 2)

        let firstPanel = try XCTUnwrap(model.pages[0].panels.first)
        XCTAssertEqual(firstPanel.number, 1)
        XCTAssertTrue(firstPanel.visualDescription.contains("rainy alley"))
        XCTAssertEqual(firstPanel.textBlocks.map(\.type), [.dialogue, .caption, .sfx, .thought, .unknown])
        XCTAssertEqual(firstPanel.textBlocks[0].speaker, "MARA")
        XCTAssertEqual(firstPanel.textBlocks[3].modifier, "thought")
        XCTAssertEqual(firstPanel.textBlocks[4].sourceParagraphType, "MysteryElement")
    }

    func testWriterPreservesUnknownRootMetadataAndUnknownParagraphs() throws {
        var model = try readFixture("sample-comic")
        model.pages[0].panels[0].textBlocks[0].text = "We should leave."

        let data = try FDXComicWriter().write(model)
        let xml = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(xml.contains("<CustomMetadata>"))
        XCTAssertTrue(xml.contains("<KeepMe>Preserve this node</KeepMe>"))
        XCTAssertTrue(xml.contains("MysteryElement"))
        XCTAssertTrue(xml.contains("We should leave."))

        let roundTrip = try FDXComicReader().read(data: data)
        XCTAssertEqual(roundTrip.pages[0].panels[0].textBlocks[0].text, "We should leave.")
        XCTAssertEqual(roundTrip.pages[0].panels[0].textBlocks.last?.type, .unknown)
    }

    func testPageBeatNoteRoundTripsBeforeFirstPanel() throws {
        let model = ComicDocumentModel(
            title: "Beat Test",
            pages: [
                ComicPage(
                    number: 1,
                    beatNote: "Keep this page quiet and tense.",
                    panels: [ComicPanel(number: 1, visualDescription: "A silent hallway.")]
                )
            ]
        )

        let data = try FDXComicWriter().write(model)
        let roundTrip = try FDXComicReader().read(data: data)

        XCTAssertEqual(roundTrip.pages[0].beatNote, "Keep this page quiet and tense.")
        XCTAssertEqual(roundTrip.pages[0].panels[0].textBlocks, [])
    }

    func testDiagnosticsWarnAboutDenseLetteringAndMissingDescription() {
        let longText = Array(repeating: "word", count: 26).joined(separator: " ")
        let model = ComicDocumentModel(
            pages: [
                ComicPage(
                    number: 1,
                    panels: [
                        ComicPanel(
                            number: 1,
                            visualDescription: "",
                            textBlocks: [
                                ComicTextBlock(type: .dialogue, speaker: "MARA", text: longText),
                                ComicTextBlock(type: .caption, text: longText)
                            ]
                        )
                    ]
                )
            ]
        )

        let diagnostics = ComicDiagnostics.evaluate(model)
        XCTAssertTrue(diagnostics.contains { $0.message.contains("missing a visual description") })
        XCTAssertTrue(diagnostics.contains { $0.message.contains("52 dialogue/caption words") })
        XCTAssertTrue(diagnostics.contains { $0.message.contains("26 words") })
    }

    func testIdealComicTemplateParsesIntoStructuredComicBlocks() throws {
        let url = repositoryRoot()
            .appendingPathComponent("Templates")
            .appendingPathComponent("ideal-comic-script.fdx")
        let data = try Data(contentsOf: url)
        let model = try FDXComicReader().read(data: data)

        XCTAssertEqual(model.title, "PROJECT TITLE")
        XCTAssertEqual(model.issue, "ISSUE #1")
        XCTAssertEqual(model.writer, "WRITER NAME")
        XCTAssertEqual(model.pages.count, 2)
        XCTAssertEqual(model.pages[0].panels.count, 3)
        XCTAssertEqual(model.pages[1].panels.count, 2)

        let firstPanelBlocks = model.pages[0].panels[0].textBlocks.map(\.type)
        XCTAssertEqual(firstPanelBlocks, [.caption, .sfx, .dialogue, .dialogue])
        XCTAssertEqual(model.pages[0].panels[1].textBlocks.map(\.type), [.thought, .note])
    }

    private func readFixture(_ name: String) throws -> ComicDocumentModel {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "fdx", subdirectory: "Fixtures"))
        let data = try Data(contentsOf: url)
        return try FDXComicReader().read(data: data)
    }

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
