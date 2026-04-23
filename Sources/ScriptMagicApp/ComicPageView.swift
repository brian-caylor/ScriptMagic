import SwiftUI
import ScriptMagicCore

struct ComicPageView: View {
    @Binding var page: ComicPage
    var findText: String
    @Binding var selection: ScriptSelection?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("PAGE")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("Page", value: $page.number, format: .number)
                    .font(.title2.weight(.bold))
                    .textFieldStyle(.plain)
                    .frame(width: 64)
                TextField("Optional page title or beat", text: $page.title)
                    .font(.title3)
                    .textFieldStyle(.plain)
            }
            .padding(.bottom, 2)

            TextField("Page beat note", text: $page.beatNote, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundStyle(.secondary)

            ForEach($page.panels) { $panel in
                ComicPanelView(
                    pageID: page.id,
                    panel: $panel,
                    findText: findText,
                    selection: $selection
                )
                .id(ScriptSelection.panel(page.id, panel.id))
            }
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
