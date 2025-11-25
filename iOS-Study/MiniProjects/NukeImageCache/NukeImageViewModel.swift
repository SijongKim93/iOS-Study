//
//  NukeImageViewModel.swift
//  iOS-Study
//
//  Created by Sijong on 11/25/25.
//

import Foundation
import Nuke

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
