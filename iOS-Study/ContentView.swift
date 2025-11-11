//
//  ContentView.swift
//  iOS-Study
//
//  Created by duse on 10/21/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Mini Projects") {
                    NavigationLink {
                        FocusTimerView()
                    } label: {
                        Label("포커스 타이머", systemImage: "hourglass")
                    }
                    
                    Text("집중-휴식 사이클을 구성하고 자동 반복을 학습해보세요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    NavigationLink {
                        StudyProgressChartView()
                    } label: {
                        Label("학습 차트 실험", systemImage: "chart.bar.doc.horizontal")
                    }
                    
                    Text("Swift Charts로 다양한 카테고리와 기간을 시각화해보세요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Section("실험 중인 아키텍처") {
                    Label("ReactorKit", systemImage: "atom")
                        .foregroundStyle(.secondary)
                    Label("The Composable Architecture", systemImage: "puzzlepiece.extension")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("iOS Study Lab")
            .listStyle(.insetGrouped)
        }
    }
}

#Preview {
    ContentView()
}
