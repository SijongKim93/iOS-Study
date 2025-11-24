//
//  RandomNumberView.swift
//  iOS-Study
//
//  Created by GPT-5 Codex on 11/10/25.
//

import SwiftUI

struct RandomNumberView: View {
    @StateObject private var viewModel = RandomNumberViewModel()
    
    var body: some View {
        List {
            Section("랜덤 숫자") {
                VStack(spacing: 24) {
                    Text("\(viewModel.currentNumber)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.quaternary)
                        )
                    
                    Button {
                        viewModel.generate()
                    } label: {
                        Label("새 숫자 생성", systemImage: "dice.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            
            Section("범위 설정") {
                Stepper(value: $viewModel.minValue, in: 0...999) {
                    Label("최소값", systemImage: "arrow.down")
                    Spacer()
                    Text("\(viewModel.minValue)")
                        .foregroundStyle(.secondary)
                }
                
                Stepper(value: $viewModel.maxValue, in: 1...1000) {
                    Label("최대값", systemImage: "arrow.up")
                    Spacer()
                    Text("\(viewModel.maxValue)")
                        .foregroundStyle(.secondary)
                }
                
                if viewModel.minValue >= viewModel.maxValue {
                    Label("최소값은 최대값보다 작아야 합니다", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                }
            }
            
            if !viewModel.generatedNumbers.isEmpty {
                Section("생성 기록") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.generatedNumbers.prefix(20)) { number in
                                Text("\(number.value)")
                                    .font(.system(.title3, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(.blue.opacity(0.2))
                                    )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    HStack {
                        Label("평균", systemImage: "chart.bar")
                        Spacer()
                        Text(viewModel.averageText)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("최소", systemImage: "arrow.down.circle")
                        Spacer()
                        Text("\(viewModel.minGenerated)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("최대", systemImage: "arrow.up.circle")
                        Spacer()
                        Text("\(viewModel.maxGenerated)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            if viewModel.currentNumber == nil {
                viewModel.generate()
            }
        }
    }
}

// MARK: - View Model

@MainActor
final class RandomNumberViewModel: ObservableObject {
    @Published var minValue: Int = 1
    @Published var maxValue: Int = 100
    @Published private(set) var currentNumber: Int?
    @Published private(set) var generatedNumbers: [GeneratedNumber] = []
    
    var averageText: String {
        guard !generatedNumbers.isEmpty else { return "-" }
        let sum = generatedNumbers.reduce(0) { $0 + $1.value }
        let average = Double(sum) / Double(generatedNumbers.count)
        return String(format: "%.1f", average)
    }
    
    var minGenerated: Int {
        generatedNumbers.map(\.value).min() ?? 0
    }
    
    var maxGenerated: Int {
        generatedNumbers.map(\.value).max() ?? 0
    }
    
    func generate() {
        let validMin = min(minValue, maxValue - 1)
        let validMax = max(maxValue, minValue + 1)
        let number = Int.random(in: validMin...validMax)
        
        currentNumber = number
        let item = GeneratedNumber(value: number, timestamp: Date())
        generatedNumbers.insert(item, at: 0)
        
        if generatedNumbers.count > 50 {
            generatedNumbers = Array(generatedNumbers.prefix(50))
        }
    }
    
    struct GeneratedNumber: Identifiable {
        let id = UUID()
        let value: Int
        let timestamp: Date
    }
}

#Preview {
    NavigationStack {
        RandomNumberView()
    }
}

