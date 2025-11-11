//
//  StudyProgressChartView.swift
//  iOS-Study
//
//  Created by GPT-5 Codex on 11/10/25.
//

import SwiftUI
import Charts

struct StudyProgressChartView: View {
    @StateObject private var viewModel = StudyProgressChartViewModel()
    
    var body: some View {
        List {
            Section("기간 선택") {
                Picker("기간", selection: $viewModel.selectedRange) {
                    ForEach(StudyProgressChartViewModel.Range.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("학습 시간 차트") {
                Chart(viewModel.filteredSessions) { session in
                    BarMark(
                        x: .value("날짜", session.date, unit: .day),
                        y: .value("시간", session.focusHours)
                    )
                    .foregroundStyle(by: .value("카테고리", session.category.displayName))
                    .cornerRadius(6)
                    
                    RuleMark(y: .value("목표", viewModel.dailyTargetHours))
                        .foregroundStyle(.secondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .topLeading) {
                            Text("목표 \(viewModel.dailyTargetHours, specifier: "%.1f")h")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(height: 240)
                .chartLegend(.visible)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(viewModel.dayFormatter.string(from: date))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .aligned, position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(hours, specifier: "%.0f")h")
                            }
                        }
                    }
                }
                
                Text(viewModel.chartDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            
            Section("요약") {
                HStack {
                    Label("총 학습 시간", systemImage: "clock.badge.checkmark")
                    Spacer()
                    Text(viewModel.totalHoursLabel)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Label("평균 집중 시간", systemImage: "chart.bar.xaxis")
                    Spacer()
                    Text(viewModel.averageHoursLabel)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Label("목표 달성률", systemImage: "target")
                    Spacer()
                    Text(viewModel.targetAchievementLabel)
                        .foregroundStyle(viewModel.targetAchievementColor)
                }
            }
        }
        .navigationTitle("학습 차트")
        .task {
            await viewModel.loadMockData()
        }
    }
}

// MARK: - View Model

@MainActor
final class StudyProgressChartViewModel: ObservableObject {
    enum Category: CaseIterable, Identifiable {
        case ios
        case algorithm
        case design
        case english
        
        var id: Self { self }
        
        var displayName: String {
            switch self {
            case .ios: return "iOS"
            case .algorithm: return "알고리즘"
            case .design: return "디자인"
            case .english: return "영어"
            }
        }
        
        var color: Color {
            switch self {
            case .ios: return .green
            case .algorithm: return .orange
            case .design: return .purple
            case .english: return .blue
            }
        }
    }
    
    enum Range: CaseIterable, Identifiable {
        case week
        case month
        case quarter
        
        var id: Self { self }
        
        var label: String {
            switch self {
            case .week: return "7일"
            case .month: return "30일"
            case .quarter: return "90일"
            }
        }
        
        var dateInterval: DateInterval {
            let end = Date()
            switch self {
            case .week:
                return DateInterval(start: end.addingTimeInterval(-6 * 24 * 60 * 60), end: end)
            case .month:
                return DateInterval(start: end.addingTimeInterval(-29 * 24 * 60 * 60), end: end)
            case .quarter:
                return DateInterval(start: end.addingTimeInterval(-89 * 24 * 60 * 60), end: end)
            }
        }
    }
    
    struct StudySession: Identifiable {
        let id = UUID()
        let date: Date
        let focusHours: Double
        let category: Category
        
        static func mock(date: Date, category: Category, focusHours: Double) -> StudySession {
            StudySession(date: date, focusHours: focusHours, category: category)
        }
    }
    
    @Published private(set) var sessions: [StudySession] = []
    @Published var selectedRange: Range = .week
    @Published var dailyTargetHours: Double = 3.0
    
    var filteredSessions: [StudySession] {
        let interval = selectedRange.dateInterval
        return sessions.filter { interval.contains($0.date) }
    }
    
    var totalHoursLabel: String {
        let total = filteredSessions.reduce(0) { $0 + $1.focusHours }
        return "\(total, specifier: "%.1f")h"
    }
    
    var averageHoursLabel: String {
        let total = filteredSessions.reduce(0) { $0 + $1.focusHours }
        let days = max(Set(filteredSessions.map { Calendar.current.startOfDay(for: $0.date) }).count, 1)
        let average = total / Double(days)
        return "\(average, specifier: "%.1f")h/일"
    }
    
    var targetAchievementLabel: String {
        let total = filteredSessions.reduce(0) { $0 + $1.focusHours }
        let expected = dailyTargetHours * Double(daysInRange)
        guard expected > 0 else { return "0%" }
        let ratio = total / expected
        return "\(Int(ratio * 100))%"
    }
    
    var targetAchievementColor: Color {
        let total = filteredSessions.reduce(0) { $0 + $1.focusHours }
        let expected = dailyTargetHours * Double(daysInRange)
        guard expected > 0 else { return .secondary }
        let ratio = total / expected
        switch ratio {
        case ..<0.7: return .red
        case 0.7..<1.0: return .orange
        default: return .green
        }
    }
    
    var chartDescription: String {
        let base = "\(selectedRange.label) 동안의 학습 기록입니다."
        guard let maxSession = filteredSessions.max(by: { $0.focusHours < $1.focusHours }) else {
            return base + " 데이터를 불러오는 중이에요."
        }
        return base + " \(dayFormatter.string(from: maxSession.date))에 \(maxSession.focusHours, specifier: "%.1f")시간으로 가장 많이 집중했습니다."
    }
    
    var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d"
        return formatter
    }
    
    private var daysInRange: Int {
        let interval = selectedRange.dateInterval
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: interval.start)
        let end = calendar.startOfDay(for: interval.end)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0 + 1
    }
    
    func loadMockData() async {
        guard sessions.isEmpty else { return }
        
        await Task.sleep(for: .milliseconds(250))
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        
        var generated: [StudySession] = []
        for offset in 0..<90 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let category = Category.allCases.randomElement() ?? .ios
            let hours = Double.random(in: 0.5...4.5)
            generated.append(.mock(date: date, category: category, focusHours: hours))
        }
        
        sessions = generated
    }
}

#Preview {
    NavigationStack {
        StudyProgressChartView()
    }
}

