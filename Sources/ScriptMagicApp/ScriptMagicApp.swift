import SwiftUI
import UniformTypeIdentifiers
import ScriptMagicCore

extension UTType {
    static let finalDraftFDX = UTType(filenameExtension: "fdx") ?? .xml
}

@main
struct ScriptMagicApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: ScriptMagicFileDocument()) { configuration in
            ScriptEditorView(document: configuration.$document)
                .frame(minWidth: 960, minHeight: 640)
        }
        .commands {
            CommandGroup(after: .pasteboard) {
                Button("Delete Selection") {
                    NotificationCenter.default.post(name: .scriptMagicDeleteSelection, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: [])
            }

            CommandMenu("Insert") {
                Button("Comic Page") {
                    NotificationCenter.default.post(name: .scriptMagicAddPage, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Button("Panel") {
                    NotificationCenter.default.post(name: .scriptMagicAddPanel, object: nil)
                }
                .keyboardShortcut("]", modifiers: [.command])

                Button("Next Comic Block") {
                    NotificationCenter.default.post(name: .scriptMagicAddNextLogicalBlock, object: nil)
                }
                .keyboardShortcut(.return, modifiers: [.command])

                Button("Cycle Block Type") {
                    NotificationCenter.default.post(name: .scriptMagicCycleBlockType, object: nil)
                }
                .keyboardShortcut(.tab, modifiers: [.command])

                Divider()

                Button("Dialogue") {
                    NotificationCenter.default.post(name: .scriptMagicAddBlock, object: ComicBlockType.dialogue)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Button("Caption") {
                    NotificationCenter.default.post(name: .scriptMagicAddBlock, object: ComicBlockType.caption)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Button("SFX") {
                    NotificationCenter.default.post(name: .scriptMagicAddBlock, object: ComicBlockType.sfx)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Button("Thought") {
                    NotificationCenter.default.post(name: .scriptMagicAddBlock, object: ComicBlockType.thought)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])

                Button("Note") {
                    NotificationCenter.default.post(name: .scriptMagicAddBlock, object: ComicBlockType.note)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            CommandMenu("Format") {
                Menu("Block Type") {
                    Button("Dialogue") {
                        NotificationCenter.default.post(name: .scriptMagicSetBlockType, object: ComicBlockType.dialogue)
                    }
                    .keyboardShortcut("1", modifiers: [.command, .option])

                    Button("Caption") {
                        NotificationCenter.default.post(name: .scriptMagicSetBlockType, object: ComicBlockType.caption)
                    }
                    .keyboardShortcut("2", modifiers: [.command, .option])

                    Button("SFX") {
                        NotificationCenter.default.post(name: .scriptMagicSetBlockType, object: ComicBlockType.sfx)
                    }
                    .keyboardShortcut("3", modifiers: [.command, .option])

                    Button("Thought") {
                        NotificationCenter.default.post(name: .scriptMagicSetBlockType, object: ComicBlockType.thought)
                    }
                    .keyboardShortcut("4", modifiers: [.command, .option])

                    Button("Note") {
                        NotificationCenter.default.post(name: .scriptMagicSetBlockType, object: ComicBlockType.note)
                    }
                    .keyboardShortcut("5", modifiers: [.command, .option])
                }

                Button("Cycle Block Type") {
                    NotificationCenter.default.post(name: .scriptMagicCycleBlockType, object: nil)
                }
                .keyboardShortcut(.tab, modifiers: [.command])

                Divider()

                Button("Renumber Panels") {
                    NotificationCenter.default.post(name: .scriptMagicRenumberPanels, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .option])
            }

            CommandMenu("Navigate") {
                Button("Previous Page") {
                    NotificationCenter.default.post(name: .scriptMagicNavigate, object: ScriptMagicNavigation.previousPage)
                }
                .keyboardShortcut(.upArrow, modifiers: [.command, .option])

                Button("Next Page") {
                    NotificationCenter.default.post(name: .scriptMagicNavigate, object: ScriptMagicNavigation.nextPage)
                }
                .keyboardShortcut(.downArrow, modifiers: [.command, .option])

                Divider()

                Button("Previous Panel") {
                    NotificationCenter.default.post(name: .scriptMagicNavigate, object: ScriptMagicNavigation.previousPanel)
                }
                .keyboardShortcut(.upArrow, modifiers: [.command])

                Button("Next Panel") {
                    NotificationCenter.default.post(name: .scriptMagicNavigate, object: ScriptMagicNavigation.nextPanel)
                }
                .keyboardShortcut(.downArrow, modifiers: [.command])
            }

            CommandMenu("Writing") {
                Button("Find in Script") {
                    NotificationCenter.default.post(name: .scriptMagicFocusFind, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command])

                Button("Clear Find") {
                    NotificationCenter.default.post(name: .scriptMagicClearFind, object: nil)
                }
                .keyboardShortcut(.escape, modifiers: [])

                Divider()

                Button("Show/Hide Writing Aids") {
                    NotificationCenter.default.post(name: .scriptMagicToggleWritingAids, object: nil)
                }
                .keyboardShortcut("w", modifiers: [.command, .option])
            }
        }
    }
}

enum ScriptMagicNavigation {
    case previousPage
    case nextPage
    case previousPanel
    case nextPanel
}

extension Notification.Name {
    static let scriptMagicAddPage = Notification.Name("scriptMagicAddPage")
    static let scriptMagicAddPanel = Notification.Name("scriptMagicAddPanel")
    static let scriptMagicAddBlock = Notification.Name("scriptMagicAddBlock")
    static let scriptMagicAddNextLogicalBlock = Notification.Name("scriptMagicAddNextLogicalBlock")
    static let scriptMagicCycleBlockType = Notification.Name("scriptMagicCycleBlockType")
    static let scriptMagicSetBlockType = Notification.Name("scriptMagicSetBlockType")
    static let scriptMagicDeleteSelection = Notification.Name("scriptMagicDeleteSelection")
    static let scriptMagicRenumberPanels = Notification.Name("scriptMagicRenumberPanels")
    static let scriptMagicNavigate = Notification.Name("scriptMagicNavigate")
    static let scriptMagicFocusFind = Notification.Name("scriptMagicFocusFind")
    static let scriptMagicClearFind = Notification.Name("scriptMagicClearFind")
    static let scriptMagicToggleWritingAids = Notification.Name("scriptMagicToggleWritingAids")
}
