//
//  ShortDownloadOverviewItem.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 02.03.25.
//

import SwiftUI

struct ShortDownloadOverviewItem: View {
    @State var item: DownloadItem
    @State var isHovered: Bool = false
    @Environment(AppViewModel.self) var appViewModel
    @Environment(\.colorScheme) var appearance
    var update: () -> Void
    var body: some View {
        HStack {
            item.icon
                .frame(maxWidth: 50, maxHeight: 50)
                .if((0.0...1.0).contains(item.info?.progress ?? -1.0)) { view in
                    view.overlay(alignment: .bottom) {
                        ProgressView(value: item.info?.progress ?? 0.0)
                            .progressViewStyle(.linear)
                            .padding(.horizontal, 5)
                    }
                }
            Text(item.name)
                .lineLimit(1)
                .foregroundStyle(item.info?.didFail ?? false ? .red: item.info?.isCanceled ?? false ? .gray: .primary)
            Spacer()
            if item.info?.progress != nil && item.info?.progress ?? 0.0 < 1.0 {
                Button {
                    appViewModel.downloadManager?.cancelDownload(item.info?.download)
                    update()
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .foregroundStyle(.gray)
                .buttonStyle(.plain)
                .padding(.trailing, 10)
            }
        }
        .onHover { hovering in isHovered = hovering }
        .onTapGesture { if let url = item.url { NSWorkspace.shared.open(url) } }
        .if(isHovered && appearance == .dark) { view in
            view.background(.myPurple.mix(with: .white, by: 0.25))
        }
        .if(isHovered && appearance == .light) { view in
            view.background(.white.mix(with: .gray, by: 0.05))
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contextMenu {
            if item.info?.progress == nil {
                Button("Show in Finder") {
                    if let url = item.url {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            }
        }
    }
}

