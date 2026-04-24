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

    func testReadsTierOneComicAttributesAndReaderFacingTypes() throws {
        let data = Data(
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <FinalDraft DocumentType="Script" Template="No" Version="1">
              <Title>Tier One</Title>
              <Issue>2</Issue>
              <Writer>Writer</Writer>
              <Content>
                <Paragraph Type="Page" Layout="splash" ExpectedPanels="1"><Text>PAGE 1: Attribute Test</Text></Paragraph>
                <Paragraph Type="Panel"><Text>Panel 1</Text></Paragraph>
                <Paragraph Type="Description"><Text>A city wall full of warnings.</Text></Paragraph>
                <Paragraph Type="Caption" Speaker="ELENA" Locked="true"><Text>This is a protected interior caption.</Text></Paragraph>
                <Paragraph Type="Sign"><Text>KEEP OUT</Text></Paragraph>
                <Paragraph Type="Screen"><Text>SIGNAL LOST</Text></Paragraph>
                <Paragraph Type="Text Message"><Text>where are you?</Text></Paragraph>
                <Paragraph Type="Chyron"><Text>BREAKING NEWS</Text></Paragraph>
                <Paragraph Type="Title Card"><Text>THREE YEARS LATER</Text></Paragraph>
                <Paragraph Type="Character" Delivery="voicemail"><Text>MARCUS</Text></Paragraph>
                <Paragraph Type="Dialogue" Locked="true"><Text>Hey. It's me again.</Text></Paragraph>
              </Content>
            </FinalDraft>
            """.utf8
        )

        let model = try FDXComicReader().read(data: data)
        let page = model.pages[0]
        let blocks = page.panels[0].textBlocks

        XCTAssertEqual(page.layout, .splash)
        XCTAssertEqual(page.expectedPanelCount, 1)
        XCTAssertEqual(blocks.map(\.type), [.caption, .sign, .screen, .textMessage, .chyron, .titleCard, .dialogue])
        XCTAssertEqual(blocks[0].speaker, "ELENA")
        XCTAssertTrue(blocks[0].isLocked)
        XCTAssertEqual(blocks[6].speaker, "MARCUS")
        XCTAssertEqual(blocks[6].delivery, .voicemail)
        XCTAssertTrue(blocks[6].isLocked)
    }

    func testWriterRoundTripsTierOneComicAttributes() throws {
        let model = ComicDocumentModel(
            title: "Tier One",
            issue: "2",
            writer: "Writer",
            pages: [
                ComicPage(
                    number: 1,
                    title: "Attribute Test",
                    layout: .halfSplash,
                    expectedPanelCount: 2,
                    panels: [
                        ComicPanel(
                            number: 1,
                            visualDescription: "A phone lights up.",
                            textBlocks: [
                                ComicTextBlock(type: .caption, speaker: "ELENA", text: "I remember this part.", isLocked: true),
                                ComicTextBlock(type: .textMessage, text: "Call me.", isLocked: true),
                                ComicTextBlock(type: .dialogue, speaker: "MARCUS", delivery: .phone, text: "Can you hear me?")
                            ]
                        ),
                        ComicPanel(number: 2, visualDescription: "The screen goes black.")
                    ]
                )
            ]
        )

        let data = try FDXComicWriter().write(model)
        let xml = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(xml.contains("Layout=\"halfSplash\""))
        XCTAssertTrue(xml.contains("ExpectedPanels=\"2\""))
        XCTAssertTrue(xml.contains("Speaker=\"ELENA\""))
        XCTAssertTrue(xml.contains("Locked=\"true\""))
        XCTAssertTrue(xml.contains("Type=\"Text Message\""))
        XCTAssertTrue(xml.contains("Delivery=\"phone\""))

        let roundTrip = try FDXComicReader().read(data: data)
        XCTAssertEqual(roundTrip.pages[0].layout, .halfSplash)
        XCTAssertEqual(roundTrip.pages[0].expectedPanelCount, 2)
        XCTAssertEqual(roundTrip.pages[0].panels[0].textBlocks[0].speaker, "ELENA")
        XCTAssertTrue(roundTrip.pages[0].panels[0].textBlocks[0].isLocked)
        XCTAssertEqual(roundTrip.pages[0].panels[0].textBlocks[1].type, .textMessage)
        XCTAssertEqual(roundTrip.pages[0].panels[0].textBlocks[2].delivery, .phone)
    }

    func testLegacyCharacterLabelsConvertToComicNativeBlocks() throws {
        let data = Data(
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <FinalDraft DocumentType="Script" Template="No" Version="1">
              <Content>
                <Paragraph Type="Scene Heading"><Text>PAGE 2 (5 PANELS)</Text></Paragraph>
                <Paragraph Type="Shot"><Text>PANEL 1</Text></Paragraph>
                <Paragraph Type="Action"><Text>A control room.</Text></Paragraph>
                <Paragraph Type="Character"><Text>CAPTION (ELENA)</Text></Paragraph>
                <Paragraph Type="Dialogue"><Text>Some rooms remember you.</Text></Paragraph>
                <Paragraph Type="Character"><Text>SFX</Text></Paragraph>
                <Paragraph Type="Dialogue"><Text>KRAK</Text></Paragraph>
              </Content>
            </FinalDraft>
            """.utf8
        )

        let model = try FDXComicReader().read(data: data)

        XCTAssertEqual(model.pages[0].number, 2)
        XCTAssertEqual(model.pages[0].expectedPanelCount, 5)
        XCTAssertEqual(model.pages[0].panels[0].textBlocks[0].type, .caption)
        XCTAssertEqual(model.pages[0].panels[0].textBlocks[0].speaker, "ELENA")
        XCTAssertEqual(model.pages[0].panels[0].textBlocks[1].type, .sfx)
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

    func testDiagnosticsWarnAboutExpectedPanelCountMismatch() {
        let model = ComicDocumentModel(
            pages: [
                ComicPage(
                    number: 1,
                    expectedPanelCount: 3,
                    panels: [
                        ComicPanel(number: 1, visualDescription: "A panel."),
                        ComicPanel(number: 2, visualDescription: "Another panel.")
                    ]
                )
            ]
        )

        let diagnostics = ComicDiagnostics.evaluate(model)
        XCTAssertTrue(diagnostics.contains { $0.message.contains("declares 3 panels but has 2") })
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
        XCTAssertEqual(model.pages[0].layout, .splash)
        XCTAssertEqual(model.pages[0].expectedPanelCount, 3)

        let firstPanelBlocks = model.pages[0].panels[0].textBlocks.map(\.type)
        XCTAssertEqual(firstPanelBlocks, [.caption, .sfx, .dialogue, .dialogue])
        XCTAssertEqual(model.pages[0].panels[0].textBlocks[0].speaker, "ELENA")
        XCTAssertTrue(model.pages[0].panels[0].textBlocks[0].isLocked)
        XCTAssertEqual(model.pages[0].panels[1].textBlocks.map(\.type), [.sign, .screen, .textMessage, .chyron, .titleCard, .thought, .note])
        XCTAssertEqual(model.pages[0].panels[2].textBlocks[0].delivery, .voicemail)
        XCTAssertTrue(model.pages[0].panels[2].textBlocks[0].isLocked)
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
