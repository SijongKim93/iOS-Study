//
//  NukeImageCacheView.swift
//  iOS-Study
//
//  Created by Claude on 11/21/25.
//

import SwiftUI
import NukeUI
import Nuke

struct NukeImageCacheView: View {
    @StateObject private var viewModel = NukeImageCacheViewModel()

    var body: some View {
        List {
            Section("이미지 로드") {
                LazyImage(url: viewModel.currentImageURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if state.error != nil {
                        ContentUnavailableView("로드 실패", systemImage: "photo.badge.exclamationmark")
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 200)
                .listRowInsets(EdgeInsets())

                Button("다음 이미지") {
                    viewModel.loadNextImage()
                }
            }

            Section("캐시 정보") {
                HStack {
                    Label("메모리 캐시", systemImage: "memorychip")
                    Spacer()
                    Text("\(viewModel.memoryCacheCount)개")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("디스크 캐시", systemImage: "externaldrive")
                    Spacer()
                    Text(viewModel.diskCacheSize)
                        .foregroundStyle(.secondary)
                }

                Button("캐시 초기화", role: .destructive) {
                    viewModel.clearCache()
                }
            }

            Section("이미지 목록") {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.imageURLs, id: \.self) { url in
                            LazyImage(url: url) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                viewModel.selectImage(url: url)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .listRowInsets(EdgeInsets())
                .frame(height: 120)
            }
        }
        .navigationTitle("Nuke 이미지 캐싱")
        .onAppear {
            viewModel.updateCacheInfo()
        }
    }
}

// MARK: - View Model

@MainActor
final class NukeImageCacheViewModel: ObservableObject {
    @Published var currentImageURL: URL?
    @Published var memoryCacheCount: Int = 0
    @Published var diskCacheSize: String = "0 KB"

    private var currentIndex = 0

    let imageURLs: [URL] = [
        URL(string: "https://picsum.photos/id/10/400/300")!,
        URL(string: "https://picsum.photos/id/20/400/300")!,
        URL(string: "https://picsum.photos/id/30/400/300")!,
        URL(string: "https://picsum.photos/id/40/400/300")!,
        URL(string: "https://picsum.photos/id/50/400/300")!,
    ]

    init() {
        currentImageURL = imageURLs.first
    }

    func loadNextImage() {
        currentIndex = (currentIndex + 1) % imageURLs.count
        currentImageURL = imageURLs[currentIndex]
        updateCacheInfo()
    }

    func selectImage(url: URL) {
        currentImageURL = url
        if let index = imageURLs.firstIndex(of: url) {
            currentIndex = index
        }
        updateCacheInfo()
    }

    func clearCache() {
        ImageCache.shared.removeAll()
        DataLoader.sharedUrlCache.removeAllCachedResponses()
        updateCacheInfo()
    }

    func updateCacheInfo() {
        memoryCacheCount = ImageCache.shared.totalCount

        let bytes = DataLoader.sharedUrlCache.currentDiskUsage
        if bytes < 1024 {
            diskCacheSize = "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            diskCacheSize = String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            diskCacheSize = String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
}

#Preview {
    NavigationStack {
        NukeImageCacheView()
    }
}
