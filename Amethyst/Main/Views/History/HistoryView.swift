//
//  HistoryView.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 04.12.24.
//

import SwiftUI

struct HistoryView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = HistoryViewModel()
    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel

        BackgroundView(shouldRotate: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search history", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .focused($searchFieldFocused)
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                }

                HStack {
                    Text("\(viewModel.resultCount) \(viewModel.resultCount == 1 ? "page" : "pages")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if viewModel.hasHistory {
                        Button("Clear History", role: .destructive) {
                            viewModel.showClearAllConfirmation = true
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Group {
                    if !viewModel.hasHistory {
                        EmptyStateView(
                            title: "No history yet",
                            subtitle: "Pages you open will start showing up here."
                        )
                    } else if !viewModel.hasSearchResults {
                        EmptyStateView(
                            title: "No results",
                            subtitle: "Try searching by title, host, or URL."
                        )
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                ForEach(viewModel.sections) { section in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(section.title)
                                            .font(.headline)
                                        HistoryListView(
                                            pages: section.pages,
                                            expandedPageIDs: $viewModel.expandedPageIDs,
                                            onDeleteVisit: { visit in
                                                viewModel.deleteVisit(visit, meili: appViewModel.meili)
                                            },
                                            onDeletePage: { page in
                                                viewModel.confirmDeletePage(page)
                                            }
                                        )
                                    }
                                    .padding(14)
                                    .background {
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(.ultraThinMaterial)
                                    }
                                }
                            }
                            .padding(.bottom, 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding()
        .confirmationDialog(
            "Delete all browsing history?",
            isPresented: $viewModel.showClearAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                viewModel.clearAllHistory(meili: appViewModel.meili)
            }
        } message: {
            Text("This removes all saved history entries and clears their omnibox suggestions.")
        }
        .confirmationDialog(
            "Delete all visits for \(viewModel.pendingPageDeletion?.displayTitle ?? "this page")?",
            isPresented: Binding(
                get: { viewModel.pendingPageDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.dismissPendingPageDeletion()
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete All Visits", role: .destructive) {
                viewModel.deletePendingPage(meili: appViewModel.meili)
            }
        } message: {
            Text("This removes matching visits across all days, not just the visible section.")
        }
        .onAppear {
            viewModel.load()
            searchFieldFocused = true
        }
    }

    private struct EmptyStateView: View {
        let title: String
        let subtitle: String

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}
