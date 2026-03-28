//
//  HistoryListView.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 04.12.24.
//

import SwiftUI


struct HistoryListView: View {
    @Environment(ContentViewModel.self) private var contentViewModel
    let pages: [HistoryGroupedPage]
    @Binding var expandedPageIDs: Set<String>
    let onDeleteVisit: (HistoryVisitRow) -> Void
    let onDeletePage: (HistoryGroupedPage) -> Void
    @State var shiftPressed: Bool = false

    var body: some View {
        LazyVStack(spacing: 10) {
            ForEach(pages) { page in
                HistoryPageRow(
                    page: page,
                    isExpanded: expandedPageIDs.contains(page.id),
                    shiftPressed: $shiftPressed,
                    toggleExpanded: {
                        toggleExpanded(pageID: page.id)
                    },
                    onDeleteVisit: onDeleteVisit,
                    onDeletePage: onDeletePage
                )
            }
        }
        .onKeyPress(phases: [.down, .up], action: keyPressed)
    }

    private func keyPressed(_ event: KeyPress) -> KeyPress.Result {
        if event.modifiers == .shift {
            shiftPressed = event.phase == .down
            return .ignored
        }
        return .ignored
    }

    private func toggleExpanded(pageID: String) {
        withAnimation(.linear(duration: 0.15)) {
            if expandedPageIDs.contains(pageID) {
                expandedPageIDs.remove(pageID)
            } else {
                expandedPageIDs.insert(pageID)
            }
        }
    }

    struct HistoryPageRow: View {
        let page: HistoryGroupedPage
        let isExpanded: Bool
        @Environment(AppViewModel.self) var appViewModel
        @Environment(ContentViewModel.self) var contentViewModel
        @Environment(\.dismiss) var dismiss
        @Binding var shiftPressed: Bool
        let toggleExpanded: () -> Void
        let onDeleteVisit: (HistoryVisitRow) -> Void
        let onDeletePage: (HistoryGroupedPage) -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Button(action: toggleExpanded) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(page.displayTitle)
                                .font(.title3.weight(.semibold))
                                .lineLimit(1)
                            Text(page.displayURL)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            HStack(spacing: 8) {
                                Label(
                                    "\(page.visitCount) \(page.visitCount == 1 ? "visit" : "visits")",
                                    systemImage: "clock.arrow.circlepath"
                                )
                                Text(Date(timeIntervalSinceReferenceDate: page.lastVisitedTime).formatted(date: .omitted, time: .shortened))
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    ActionButton(systemName: "arrow.up.forward.square") {
                        openURL(page.latestVisit.url)
                    }
                    .help("Open page")

                    ActionButton(systemName: "trash", role: .destructive) {
                        onDeletePage(page)
                    }
                    .help("Delete all visits for this page")

                    ActionButton(systemName: isExpanded ? "chevron.up" : "chevron.down") {
                        toggleExpanded()
                    }
                    .help(isExpanded ? "Collapse visits" : "Expand visits")
                }

                if isExpanded {
                    VStack(spacing: 6) {
                        ForEach(page.visits) { visit in
                            VisitRow(
                                visit: visit,
                                shiftPressed: $shiftPressed,
                                onDelete: {
                                    onDeleteVisit(visit)
                                }
                            )
                        }
                    }
                    .padding(.leading, 12)
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.08))
            }
            .contextMenu {
                Button("Open") {
                    openURL(page.latestVisit.url)
                }
                Button(isExpanded ? "Collapse Visits" : "Expand Visits") {
                    toggleExpanded()
                }
                Button("Delete All Visits", role: .destructive) {
                    onDeletePage(page)
                }
            }
        }

        func openURL(_ url: URL) {
            let vm = WebViewModel(contentViewModel: contentViewModel, appViewModel: appViewModel)
            vm.load(urlString: url.absoluteString)
            let tab = ATab(webViewModel: vm)
            contentViewModel.tabs.append(tab)
            if !shiftPressed {
                contentViewModel.currentTab = tab.id
                dismiss()
            }
        }
    }

    struct VisitRow: View {
        let visit: HistoryVisitRow
        @Environment(AppViewModel.self) var appViewModel
        @Environment(ContentViewModel.self) var contentViewModel
        @Environment(\.dismiss) var dismiss
        @Binding var shiftPressed: Bool
        let onDelete: () -> Void

        var body: some View {
            HStack(alignment: .top, spacing: 10) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(visit.displayTitle)
                            .font(.body)
                            .lineLimit(1)
                        Text(visit.urlString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(Date(timeIntervalSinceReferenceDate: visit.time).formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                ActionButton(systemName: "arrow.up.forward.square") {
                    openItem(visit.url)
                }
                .help("Open visit")

                ActionButton(systemName: "trash", role: .destructive) {
                    onDelete()
                }
                .help("Delete visit")
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
            }
            .contextMenu {
                Button("Open") {
                    openItem(visit.url)
                }
                Button("Delete Visit", role: .destructive) {
                    onDelete()
                }
            }
        }

        func openItem(_ url: URL) {
            let vm = WebViewModel(contentViewModel: contentViewModel, appViewModel: appViewModel)
            vm.load(urlString: url.absoluteString)
            let tab = ATab(webViewModel: vm)
            contentViewModel.tabs.append(tab)
            if !shiftPressed {
                contentViewModel.currentTab = tab.id
                dismiss()
            }
        }
    }

    private struct ActionButton: View {
        let systemName: String
        let role: ButtonRole?
        let action: () -> Void

        init(systemName: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
            self.systemName = systemName
            self.role = role
            self.action = action
        }

        var body: some View {
            Button(role: role, action: action) {
                Image(systemName: systemName)
                    .frame(width: 18, height: 18)
                    .padding(6)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.thinMaterial)
                    }
            }
            .buttonStyle(.plain)
        }
    }

}
