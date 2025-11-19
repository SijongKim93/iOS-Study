//
//  SimpleCounterView.swift
//  iOS-Study
//
//  Created by GPT-5 Codex on 11/10/25.
//

import SwiftUI

struct SimpleCounterView: View {
    @StateObject private var viewModel = SimpleCounterViewModel()
    
    var body: some View {
        List {
            Section("카운터") {
                VStack(spacing: 24) {
                    Text("\(viewModel.count)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(viewModel.countColor)
                        .frame(maxWidth: .infinity)
                    
                    HStack(spacing: 16) {
                        Button {
                            viewModel.decrement()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.count <= viewModel.minValue)
                        
                        Button {
                            viewModel.reset()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 32))
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.count == 0)
                        
                        Button {
                            viewModel.increment()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.count >= viewModel.maxValue)
                    }
                }
                .padding(.vertical, 16)
                .listRowBackground(Color.clear)
            }
            
            Section("설정") {
                Stepper(value: $viewModel.step, in: 1...10) {
                    Label("증감 단위", systemImage: "arrow.up.arrow.down")
                    Spacer()
                    Text("\(viewModel.step)")
                        .foregroundStyle(.secondary)
                }
                
                Stepper(value: $viewModel.minValue, in: -100...0) {
                    Label("최소값", systemImage: "arrow.down")
                    Spacer()
                    Text("\(viewModel.minValue)")
                        .foregroundStyle(.secondary)
                }
                
                Stepper(value: $viewModel.maxValue, in: 0...1000) {
                    Label("최대값", systemImage: "arrow.up")
                    Spacer()
                    Text("\(viewModel.maxValue)")
                        .foregroundStyle(.secondary)
                }
            }
            
            if !viewModel.history.isEmpty {
                Section("변경 기록") {
                    ForEach(viewModel.history.prefix(10)) { item in
                        HStack {
                            Label(item.action, systemImage: item.icon)
                            Spacer()
                            Text(item.timestamp, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("간단한 카운터")
    }
}

// MARK: - View Model

@MainActor
final class SimpleCounterViewModel: ObservableObject {
    @Published var count: Int = 0
    @Published var step: Int = 1
    @Published var minValue: Int = -100
    @Published var maxValue: Int = 1000
    @Published private(set) var history: [HistoryItem] = []
    
    var countColor: Color {
        switch count {
        case ..<0:
            return .red
        case 0:
            return .secondary
        default:
            return .green
        }
    }
    
    func increment() {
        let newValue = min(count + step, maxValue)
        if newValue != count {
            count = newValue
            addHistory(action: "+\(step)", icon: "plus.circle.fill")
        }
    }
    
    func decrement() {
        let newValue = max(count - step, minValue)
        if newValue != count {
            count = newValue
            addHistory(action: "-\(step)", icon: "minus.circle.fill")
        }
    }
    
    func reset() {
        count = 0
        addHistory(action: "리셋", icon: "arrow.counterclockwise")
    }
    
    private func addHistory(action: String, icon: String) {
        let item = HistoryItem(action: action, icon: icon, timestamp: Date())
        history.insert(item, at: 0)
        if history.count > 20 {
            history = Array(history.prefix(20))
        }
    }
    
    struct HistoryItem: Identifiable {
        let id = UUID()
        let action: String
        let icon: String
        let timestamp: Date
    }
}

#Preview {
    NavigationStack {
        SimpleCounterView()
    }
}

