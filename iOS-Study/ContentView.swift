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
                    
                    NavigationLink {
                        ColorPickerView()
                    } label: {
                        Label("색상 선택기", systemImage: "paintpalette")
                    }
                    
                    Text("ColorPicker를 사용한 색상 선택 및 미리보기 예제입니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    NavigationLink {
                        SimpleCounterView()
                    } label: {
                        Label("간단한 카운터", systemImage: "number.circle")
                    }
                    
                    Text("증감 단위와 범위를 설정할 수 있는 카운터 예제입니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    NavigationLink {
                        RandomNumberView()
                    } label: {
                        Label("랜덤 숫자", systemImage: "dice")
                    }
                    
                    Text("범위를 설정하고 랜덤 숫자를 생성하는 예제입니다.")
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
