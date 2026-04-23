import SwiftUI
import ScriptMagicCore

struct ComicPanelView: View {
    var pageID: UUID
    @Binding var panel: ComicPanel
    var findText: String
    @Binding var selection: ScriptSelection?

    private var letteringWordCount: Int {
        panel.textBlocks.reduce(0) { total, block in
            guard block.type == .dialogue || block.type == .caption else { return total }
            return total + ComicDiagnostics.wordCount(block.text)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("PANEL")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("Panel", value: $panel.number, format: .number)
                    .font(.headline)
                    .textFieldStyle(.plain)
                    .frame(width: 56)
                Spacer()
                Text("\(letteringWordCount) lettering words")
                    .font(.caption)
                    .foregroundStyle(letteringWordCount > 50 ? .orange : .secondary)
            }

            TextField("What should the artist draw in this panel?", text: $panel.visualDescription, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(10)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            ForEach($panel.textBlocks) { $block in
                ComicTextBlockView(block: $block, findText: findText)
                    .id(ScriptSelection.block(pageID, panel.id, block.id))
                    .onTapGesture {
                        selection = .block(pageID, panel.id, block.id)
                    }
            }
        }
        .padding(14)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        }
    }
}
