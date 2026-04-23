import SwiftUI
import ScriptMagicCore

struct ComicTextBlockView: View {
    @Binding var block: ComicTextBlock
    var findText: String

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
                    ForEach([ComicBlockType.dialogue, .caption, .sfx, .thought, .note, .unknown]) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .labelsHidden()
                .frame(width: 140)

                if block.type == .dialogue || block.type == .thought {
                    TextField("Speaker", text: $block.speaker)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 160)

                    TextField("Modifier", text: $block.modifier)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }

                Spacer()

                if block.type == .dialogue || block.type == .caption {
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
        }
        .padding(10)
        .background(blockBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var blockBackground: Color {
        switch block.type {
        case .dialogue, .thought:
            Color.accentColor.opacity(0.08)
        case .caption:
            Color.purple.opacity(0.08)
        case .sfx:
            Color.orange.opacity(0.10)
        case .note:
            Color.gray.opacity(0.10)
        case .unknown:
            Color.red.opacity(0.08)
        case .page, .panel, .description:
            Color.clear
        }
    }
}
