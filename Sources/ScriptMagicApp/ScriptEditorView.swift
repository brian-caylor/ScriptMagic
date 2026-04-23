import SwiftUI
import ScriptMagicCore

struct ScriptEditorView: View {
    @Binding var document: ScriptMagicFileDocument
    @State private var selection: ScriptSelection?
    @State private var findText = ""
    @State private var showsWritingAids = true
    @FocusState private var findFieldFocused: Bool

    private var diagnostics: [ComicDiagnostic] {
        showsWritingAids ? ComicDiagnostics.evaluate(document.model) : []
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            VStack(spacing: 0) {
                metadataBar
                Divider()
                toolbar
                Divider()
                scriptFlow
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .scriptMagicAddPage)) { _ in
            addPage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .scriptMagicAddPanel)) { _ in
            addPanel()
        }
        .onReceive(NotificationCenter.default.publisher(for: .scriptMagicAddBlock)) { notification in
            guard let type = notification.object as? ComicBlockType else { return }
            addBlock(type)
        }
        .onReceive(NotificationCenter.default.publisher(for: .scriptMagicAddNextLogicalBlock)) { _ in
            addNextLogicalBlock()
        }
        .onReceive(NotificationCenter.default.publisher(for: .scriptMagicCycleBlockType)) { _ in
            cycleSelectedBlockType()
        }
        .onReceive(NotificationCenter.default.publisher(for: .scriptMagicSetBlockType)) { notification in
            guard let type = notification.object as? ComicBlockType else { return }
            setSelectedBlockType(type)
        }
        .onReceive(NotificationCenter.default.publisher(for: .scriptMagicDeleteSelection)) { _ in
            deleteSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .scriptMagicRenumberPanels)) { _ in
            renumberPanels()
        }
        .onReceive(NotificationCenter.default.publisher(for: .scriptMagicNavigate)) { notification in
            guard let direction = notification.object as? ScriptMagicNavigation else { return }
            navigate(direction)
        }
        .onReceive(NotificationCenter.default.publisher(for: .scriptMagicFocusFind)) { _ in
            findFieldFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .scriptMagicClearFind)) { _ in
            findText = ""
        }
        .onReceive(NotificationCenter.default.publisher(for: .scriptMagicToggleWritingAids)) { _ in
            showsWritingAids.toggle()
        }
    }

    private var sidebar: some View {
        List(selection: $selection) {
            Section("Pages") {
                ForEach(document.model.pages) { page in
                    DisclosureGroup {
                        ForEach(page.panels) { panel in
                            Text("Panel \(panel.number)")
                                .tag(ScriptSelection.panel(page.id, panel.id))
                        }
                    } label: {
                        Text(page.title.isEmpty ? "Page \(page.number)" : "Page \(page.number): \(page.title)")
                            .tag(ScriptSelection.page(page.id))
                    }
                }
            }

            if !diagnostics.isEmpty {
                Section("Writing Aids") {
                    ForEach(diagnostics) { diagnostic in
                        Label(diagnostic.message, systemImage: diagnostic.severity == .warning ? "exclamationmark.triangle" : "info.circle")
                            .font(.caption)
                            .foregroundStyle(diagnostic.severity == .warning ? .orange : .secondary)
                    }
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 280)
    }

    private var metadataBar: some View {
        HStack(spacing: 12) {
            TextField("Title", text: $document.model.title)
                .textFieldStyle(.roundedBorder)
            TextField("Issue", text: $document.model.issue)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 160)
            TextField("Writer", text: $document.model.writer)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 220)
        }
        .padding(12)
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button {
                addPage()
            } label: {
                Label("Page", systemImage: "doc.badge.plus")
            }

            Button {
                addPanel()
            } label: {
                Label("Panel", systemImage: "rectangle.split.2x1")
            }

            Button {
                addNextLogicalBlock()
            } label: {
                Label("Next", systemImage: "return")
            }

            Menu {
                Button("Dialogue") { addBlock(.dialogue) }
                Button("Caption") { addBlock(.caption) }
                Button("SFX") { addBlock(.sfx) }
                Button("Thought") { addBlock(.thought) }
                Button("Note") { addBlock(.note) }
            } label: {
                Label("Lettering", systemImage: "text.bubble")
            }

            Spacer()

            TextField("Find", text: $findText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
                .focused($findFieldFocused)
        }
        .padding(10)
    }

    private var scriptFlow: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach($document.model.pages) { $page in
                        ComicPageView(page: $page, findText: findText, selection: $selection)
                            .id(ScriptSelection.page(page.id))
                    }
                }
                .padding(24)
                .frame(maxWidth: 920)
                .frame(maxWidth: .infinity)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .onChange(of: selection) { _, newValue in
                guard let newValue else { return }
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .top)
                }
            }
        }
    }

    private func addPage() {
        let nextNumber = (document.model.pages.map(\.number).max() ?? 0) + 1
        let page = ComicPage(number: nextNumber, panels: [ComicPanel(number: 1)])
        document.model.pages.append(page)
        selection = .page(page.id)
    }

    private func addPanel() {
        let pageIndex = selectedPageIndex() ?? max(document.model.pages.count - 1, 0)
        guard document.model.pages.indices.contains(pageIndex) else { return }
        let nextNumber = (document.model.pages[pageIndex].panels.map(\.number).max() ?? 0) + 1
        let panel = ComicPanel(number: nextNumber)
        document.model.pages[pageIndex].panels.append(panel)
        selection = .panel(document.model.pages[pageIndex].id, panel.id)
    }

    private func addBlock(_ type: ComicBlockType) {
        let pageIndex = selectedPageIndex() ?? max(document.model.pages.count - 1, 0)
        guard document.model.pages.indices.contains(pageIndex) else { return }

        if document.model.pages[pageIndex].panels.isEmpty {
            document.model.pages[pageIndex].panels.append(ComicPanel(number: 1))
        }

        let panelIndex = selectedPanelIndex(in: pageIndex) ?? max(document.model.pages[pageIndex].panels.count - 1, 0)
        let block = ComicTextBlock(type: type)
        document.model.pages[pageIndex].panels[panelIndex].textBlocks.append(block)
        selection = .block(document.model.pages[pageIndex].id, document.model.pages[pageIndex].panels[panelIndex].id, block.id)
    }

    private func addNextLogicalBlock() {
        switch selection {
        case .none:
            addPanel()

        case .page:
            addPanel()

        case let .panel(pageID, panelID):
            guard
                let pageIndex = document.model.pages.firstIndex(where: { $0.id == pageID }),
                let panelIndex = document.model.pages[pageIndex].panels.firstIndex(where: { $0.id == panelID })
            else { return }

            if document.model.pages[pageIndex].panels[panelIndex].visualDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return
            }

            addBlock(.dialogue)

        case let .block(pageID, panelID, _):
            guard
                let pageIndex = document.model.pages.firstIndex(where: { $0.id == pageID }),
                let panelIndex = document.model.pages[pageIndex].panels.firstIndex(where: { $0.id == panelID })
            else { return }

            let nextNumber = (document.model.pages[pageIndex].panels.map(\.number).max() ?? 0) + 1
            let panel = ComicPanel(number: nextNumber)
            document.model.pages[pageIndex].panels.insert(panel, at: panelIndex + 1)
            selection = .panel(pageID, panel.id)
        }
    }

    private func cycleSelectedBlockType() {
        guard
            case let .block(pageID, panelID, blockID) = selection,
            let pageIndex = document.model.pages.firstIndex(where: { $0.id == pageID }),
            let panelIndex = document.model.pages[pageIndex].panels.firstIndex(where: { $0.id == panelID }),
            let blockIndex = document.model.pages[pageIndex].panels[panelIndex].textBlocks.firstIndex(where: { $0.id == blockID })
        else { return }

        let cycle: [ComicBlockType] = [.dialogue, .caption, .sfx, .thought, .note]
        let current = document.model.pages[pageIndex].panels[panelIndex].textBlocks[blockIndex].type
        let nextIndex = cycle.index(after: cycle.firstIndex(of: current) ?? cycle.startIndex)
        document.model.pages[pageIndex].panels[panelIndex].textBlocks[blockIndex].type = cycle[nextIndex == cycle.endIndex ? cycle.startIndex : nextIndex]
    }

    private func setSelectedBlockType(_ type: ComicBlockType) {
        guard
            case let .block(pageID, panelID, blockID) = selection,
            let pageIndex = document.model.pages.firstIndex(where: { $0.id == pageID }),
            let panelIndex = document.model.pages[pageIndex].panels.firstIndex(where: { $0.id == panelID }),
            let blockIndex = document.model.pages[pageIndex].panels[panelIndex].textBlocks.firstIndex(where: { $0.id == blockID })
        else { return }

        document.model.pages[pageIndex].panels[panelIndex].textBlocks[blockIndex].type = type
    }

    private func deleteSelection() {
        guard let selection else { return }

        switch selection {
        case let .block(pageID, panelID, blockID):
            guard
                let pageIndex = document.model.pages.firstIndex(where: { $0.id == pageID }),
                let panelIndex = document.model.pages[pageIndex].panels.firstIndex(where: { $0.id == panelID }),
                let blockIndex = document.model.pages[pageIndex].panels[panelIndex].textBlocks.firstIndex(where: { $0.id == blockID })
            else { return }

            document.model.pages[pageIndex].panels[panelIndex].textBlocks.remove(at: blockIndex)
            self.selection = .panel(pageID, panelID)

        case let .panel(pageID, panelID):
            guard
                let pageIndex = document.model.pages.firstIndex(where: { $0.id == pageID }),
                let panelIndex = document.model.pages[pageIndex].panels.firstIndex(where: { $0.id == panelID })
            else { return }

            document.model.pages[pageIndex].panels.remove(at: panelIndex)
            if document.model.pages[pageIndex].panels.isEmpty {
                document.model.pages[pageIndex].panels.append(ComicPanel(number: 1))
            }
            self.selection = .page(pageID)
            renumberPanels(on: pageIndex)

        case let .page(pageID):
            guard let pageIndex = document.model.pages.firstIndex(where: { $0.id == pageID }) else { return }
            document.model.pages.remove(at: pageIndex)
            if document.model.pages.isEmpty {
                document.model.pages.append(ComicPage(number: 1, panels: [ComicPanel(number: 1)]))
            }
            renumberPages()
            self.selection = .page(document.model.pages[min(pageIndex, document.model.pages.count - 1)].id)
        }
    }

    private func renumberPanels() {
        if let pageIndex = selectedPageIndex() {
            renumberPanels(on: pageIndex)
        } else {
            for pageIndex in document.model.pages.indices {
                renumberPanels(on: pageIndex)
            }
        }
    }

    private func renumberPanels(on pageIndex: Int) {
        guard document.model.pages.indices.contains(pageIndex) else { return }
        for panelIndex in document.model.pages[pageIndex].panels.indices {
            document.model.pages[pageIndex].panels[panelIndex].number = panelIndex + 1
        }
    }

    private func renumberPages() {
        for pageIndex in document.model.pages.indices {
            document.model.pages[pageIndex].number = pageIndex + 1
        }
    }

    private func navigate(_ direction: ScriptMagicNavigation) {
        switch direction {
        case .previousPage:
            movePage(offset: -1)
        case .nextPage:
            movePage(offset: 1)
        case .previousPanel:
            movePanel(offset: -1)
        case .nextPanel:
            movePanel(offset: 1)
        }
    }

    private func movePage(offset: Int) {
        guard !document.model.pages.isEmpty else { return }
        let currentIndex = selectedPageIndex() ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), document.model.pages.count - 1)
        selection = .page(document.model.pages[nextIndex].id)
    }

    private func movePanel(offset: Int) {
        guard !document.model.pages.isEmpty else { return }
        let pageIndex = selectedPageIndex() ?? 0
        guard document.model.pages.indices.contains(pageIndex) else { return }

        let panelIndex = selectedPanelIndex(in: pageIndex) ?? 0
        let nextIndex = min(max(panelIndex + offset, 0), max(document.model.pages[pageIndex].panels.count - 1, 0))
        guard document.model.pages[pageIndex].panels.indices.contains(nextIndex) else { return }
        selection = .panel(document.model.pages[pageIndex].id, document.model.pages[pageIndex].panels[nextIndex].id)
    }

    private func selectedPageIndex() -> Int? {
        guard let selection else { return nil }
        let pageID = selection.pageID
        return document.model.pages.firstIndex { $0.id == pageID }
    }

    private func selectedPanelIndex(in pageIndex: Int) -> Int? {
        guard case let .panel(_, panelID) = selection ?? .page(UUID()) else {
            if case let .block(_, panelID, _) = selection {
                return document.model.pages[pageIndex].panels.firstIndex { $0.id == panelID }
            }
            return nil
        }

        return document.model.pages[pageIndex].panels.firstIndex { $0.id == panelID }
    }
}

enum ScriptSelection: Hashable {
    case page(UUID)
    case panel(UUID, UUID)
    case block(UUID, UUID, UUID)

    var pageID: UUID {
        switch self {
        case let .page(pageID), let .panel(pageID, _), let .block(pageID, _, _):
            pageID
        }
    }
}
