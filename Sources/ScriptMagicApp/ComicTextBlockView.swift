import SwiftUI
import ScriptMagicCore

struct ComicTextBlockView: View {
    @Binding var block: ComicTextBlock
    var findText: String
    @State private var confirmsUnlock = false

    private let selectableTypes: [ComicBlockType] = [
        .dialogue,
        .caption,
        .sfx,
        .thought,
        .sign,
        .screen,
        .textMessage,
        .chyron,
        .titleCard,
        .note,
        .unknown
    ]

    private var wordCount: Int {
        ComicDiagnostics.wordCount(block.text)
    }

    private var isMatch: Bool {
        !findText.isEmpty &&
        (
            block.text.localizedCaseInsensitiveContains(findText) ||
            block.speaker.localizedCaseInsensitiveContains(findText)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Type", selection: $block.type) {
                    ForEach(selectableTypes) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
                .disabled(block.isLocked)

                if block.type == .dialogue || block.type == .thought || block.type == .caption {
                    TextField("Speaker", text: $block.speaker)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 160)
                        .disabled(block.isLocked)
                }

                if block.type == .dialogue || block.type == .thought {
                    Picker("Delivery", selection: $block.delivery) {
                        ForEach(ComicDelivery.allCases) { delivery in
                            Text(delivery.displayName).tag(delivery)
                        }
                    }
                    .frame(width: 150)
                    .disabled(block.isLocked)

                    if block.delivery == .custom {
                        TextField("Custom", text: $block.modifier)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                            .disabled(block.isLocked)
                    }
                }

                Button {
                    if block.isLocked {
                        confirmsUnlock = true
                    } else {
                        block.isLocked = true
                    }
                } label: {
                    Image(systemName: block.isLocked ? "lock.fill" : "lock.open")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(block.isLocked ? .orange : .secondary)
                .help(block.isLocked ? "Unlock protected line" : "Lock protected line")

                Spacer()

                if block.type.isReaderFacingText {
                    Text("\(wordCount) words")
                        .font(.caption)
                        .foregroundStyle(wordCount > 25 ? .orange : .secondary)
                }
            }

            TextField(block.type == .sfx ? "Sound effect" : "Text", text: $block.text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(8)
                .background(isMatch ? Color.yellow.opacity(0.25) : Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .disabled(block.isLocked)
        }
        .padding(10)
        .background(blockBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            if block.isLocked {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.65), lineWidth: 1)
            }
        }
        .confirmationDialog(
            "Unlock this protected line?",
            isPresented: $confirmsUnlock,
            titleVisibility: .visible
        ) {
            Button("Unlock", role: .destructive) {
                block.isLocked = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Unlocking allows this line to be revised or deleted.")
        }
    }

    private var blockBackground: Color {
        switch block.type {
        case .dialogue, .thought:
            Color.accentColor.opacity(0.08)
        case .caption:
            Color.purple.opacity(0.08)
        case .sfx:
            Color.orange.opacity(0.10)
        case .sign, .screen, .textMessage, .chyron, .titleCard:
            Color.green.opacity(0.10)
        case .note:
            Color.gray.opacity(0.10)
        case .unknown:
            Color.red.opacity(0.08)
        case .page, .panel, .description:
            Color.clear
        }
    }
}
