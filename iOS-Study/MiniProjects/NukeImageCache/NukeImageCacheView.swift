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

#Preview {
    NavigationStack {
        NukeImageCacheView()
    }
}
