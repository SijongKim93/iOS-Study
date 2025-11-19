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
                
                Picker("차트 유형", selection: $viewModel.chartStyle) {
                    ForEach(StudyProgressChartViewModel.ChartStyle.allCases) { style in
                        Label(style.label, systemImage: style.icon).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("카테고리 필터") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(StudyProgressChartViewModel.Category.allCases) { category in
                            let isSelected = viewModel.selectedCategories.contains(category)
                            
                            Button {
                                viewModel.toggle(category: category)
                            } label: {
                                Label(category.displayName, systemImage: category.icon)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .background(isSelected ? category.color : Color.gray.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if viewModel.selectedCategories.isEmpty {
                    Text("최소 한 개의 카테고리를 선택해야 차트를 볼 수 있습니다.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            
            Section("학습 시간 차트") {
                if viewModel.displaySessions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("표시할 데이터가 없습니다", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text("기간이나 카테고리 선택을 조정해 학습 데이터를 확인해보세요.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                } else {
                    Chart {
                        ForEach(viewModel.displaySessions) { session in
                            switch viewModel.chartStyle {
                            case .bar:
                                BarMark(
                                    x: .value("날짜", session.date, unit: .day),
                                    y: .value("시간", session.focusHours)
                                )
                                .cornerRadius(6)
                                .foregroundStyle(by: .value("카테고리", session.category.displayName))
                            case .line:
                                LineMark(
                                    x: .value("날짜", session.date, unit: .day),
                                    y: .value("시간", session.focusHours)
                                )
                                .symbol(.circle)
                                .foregroundStyle(by: .value("카테고리", session.category.displayName))
                            case .area:
                                AreaMark(
                                    x: .value("날짜", session.date, unit: .day),
                                    y: .value("시간", session.focusHours)
                                )
                                .foregroundStyle(by: .value("카테고리", session.category.displayName))
                                LineMark(
                                    x: .value("날짜", session.date, unit: .day),
                                    y: .value("시간", session.focusHours)
                                )
                                .symbol(.circle)
                                .foregroundStyle(by: .value("카테고리", session.category.displayName))
                            }
                        }
                        .interpolationMethod(.catmullRom)
                        
                        RuleMark(y: .value("목표", viewModel.dailyTargetHours))
                            .foregroundStyle(.secondary)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .topLeading) {
                                Text("목표 \(viewModel.dailyTargetHours, specifier: "%.1f")h")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(height: 260)
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
                    .overlay(alignment: .topTrailing) {
                        if let peakText = viewModel.peakSessionText {
                            Label(peakText, systemImage: "rosette")
                                .font(.caption2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .padding(.trailing, 12)
                        }
                    }
                    .chartOverlay { proxy in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        viewModel.updateSelection(value: value, proxy: proxy)
                                    }
                                    .onEnded { _ in
                                        viewModel.clearSelection()
                                    }
                            )
                    }
                    
                    if let selectionSummary = viewModel.activeSelectionSummary {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(selectionSummary.title, systemImage: "hand.tap")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(selectionSummary.detail)
                                .font(.headline)
                            Text(selectionSummary.description)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
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
                    Label("목표 달성률", systemImage: "target")
                    Spacer()
                    Text(viewModel.targetAchievementLabel)
                        .foregroundStyle(viewModel.targetAchievementColor)
                }
                
                if let bestCategory = viewModel.bestCategoryLabel {
                    HStack {
                        Label("가장 집중한 분야", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                        Spacer()
                        Text(bestCategory)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let streak = viewModel.currentStreakLabel {
                    HStack {
                        Label("연속 목표 달성", systemImage: "bolt.badge.clock")
                            .foregroundStyle(.green)
                        Spacer()
                        Text(streak)
                            .foregroundStyle(.secondary)
                    }
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
        
        var icon: String {
            switch self {
            case .ios: return "iphone"
            case .algorithm: return "function"
            case .design: return "paintpalette"
            case .english: return "book"
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
    
    enum ChartStyle: CaseIterable, Identifiable {
        case bar
        case line
        case area
        
        var id: Self { self }
        
        var label: String {
            switch self {
            case .bar: return "막대"
            case .line: return "선"
            case .area: return "면"
            }
        }
        
        var icon: String {
            switch self {
            case .bar: return "chart.bar"
            case .line: return "chart.xyaxis.line"
            case .area: return "mountain.2.fill"
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
    @Published var selectedCategories: Set<Category> = Set(Category.allCases)
    @Published var chartStyle: ChartStyle = .bar
    @Published private(set) var activeSelection: StudySession?
    
    var filteredSessions: [StudySession] {
        let interval = selectedRange.dateInterval
        return sessions.filter { interval.contains($0.date) }
    }
    
    var displaySessions: [StudySession] {
        guard !selectedCategories.isEmpty else { return [] }
        return filteredSessions
            .filter { selectedCategories.contains($0.category) }
            .sorted(by: { $0.date < $1.date })
    }
    
    var totalHoursLabel: String {
        let total = displaySessions.reduce(0) { $0 + $1.focusHours }
        return "\(total, specifier: "%.1f")h"
    }
    
    var averageHoursLabel: String {
        let total = displaySessions.reduce(0) { $0 + $1.focusHours }
        let days = max(Set(displaySessions.map { Calendar.current.startOfDay(for: $0.date) }).count, 1)
        let average = total / Double(days)
        return "\(average, specifier: "%.1f")h/일"
    }
    
    var targetAchievementLabel: String {
        let total = displaySessions.reduce(0) { $0 + $1.focusHours }
        let expected = dailyTargetHours * Double(daysInRange)
        guard expected > 0 else { return "0%" }
        let ratio = total / expected
        return "\(Int(ratio * 100))%"
    }
    
    var targetAchievementColor: Color {
        let total = displaySessions.reduce(0) { $0 + $1.focusHours }
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
        guard let maxSession = displaySessions.max(by: { $0.focusHours < $1.focusHours }) else {
            return base + " 데이터를 불러오는 중이에요."
        }
        return base + " \(dayFormatter.string(from: maxSession.date))에 \(maxSession.focusHours, specifier: "%.1f")시간으로 가장 많이 집중했습니다."
    }
    
    var peakSessionText: String? {
        guard let session = displaySessions.max(by: { $0.focusHours < $1.focusHours }) else {
            return nil
        }
        return "\(dayFormatter.string(from: session.date)) • \(session.category.displayName) \(session.focusHours, specifier: \"%.1f\")h"
    }
    
    var bestCategoryLabel: String? {
        guard !displaySessions.isEmpty else { return nil }
        let totals = Dictionary(grouping: displaySessions, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.focusHours } }
        guard let (category, hours) = totals.max(by: { $0.value < $1.value }) else {
            return nil
        }
        return "\(category.displayName) \(hours, specifier: \"%.1f\")h"
    }
    
    var currentStreakLabel: String? {
        guard !displaySessions.isEmpty else { return nil }
        let calendar = Calendar.current
        let sortedDays = Set(displaySessions.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
        guard let latest = sortedDays.first else { return nil }
        
        var streak = 0
        for (index, day) in sortedDays.enumerated() {
            guard let expected = calendar.date(byAdding: .day, value: -index, to: latest),
                  calendar.isDate(day, inSameDayAs: expected) else {
                break
            }
            let total = displaySessions
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.focusHours }
            if total >= dailyTargetHours {
                streak += 1
            } else {
                break
            }
        }
        
        return streak > 0 ? "\(streak)일 연속 목표 달성" : nil
    }
    
    var activeSelectionSummary: ActiveSelectionSummary? {
        guard let selection = activeSelection else { return nil }
        let calendar = Calendar.current
        let totalForDay = displaySessions
            .filter { calendar.isDate($0.date, inSameDayAs: selection.date) }
            .reduce(0) { $0 + $1.focusHours }
        
        let title = "\(dayFormatter.string(from: selection.date))의 학습"
        let detail = "\(selection.category.displayName) \(selection.focusHours, specifier: \"%.1f\")h"
        let achievement = dailyTargetHours > 0 ? Int((totalForDay / dailyTargetHours) * 100) : 0
        let description = "총 \(totalForDay, specifier: \"%.1f\")시간 학습, 목표 대비 \(achievement)%"
        
        return ActiveSelectionSummary(title: title, detail: detail, description: description)
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
    
    func toggle(category: Category) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    func updateSelection(value: DragGesture.Value, proxy: ChartProxy) {
        let location = value.location
        guard let date: Date = proxy.value(atX: location.x, as: Date.self),
              let hours: Double = proxy.value(atY: location.y, as: Double.self) else {
            activeSelection = nil
            return
        }
        
        let nearest = displaySessions.min { lhs, rhs in
            let lhsDiff = abs(lhs.date.timeIntervalSince(date))
            let rhsDiff = abs(rhs.date.timeIntervalSince(date))
            return lhsDiff < rhsDiff
        }
        
        guard let candidate = nearest else {
            activeSelection = nil
            return
        }
        
        let calendar = Calendar.current
        if calendar.isDate(candidate.date, inSameDayAs: date) && abs(candidate.focusHours - hours) <= 1.5 {
            activeSelection = candidate
        } else {
            activeSelection = nil
        }
    }
    
    func clearSelection() {
        activeSelection = nil
    }
    
    struct ActiveSelectionSummary {
        let title: String
        let detail: String
        let description: String
    }
}

#Preview {
    NavigationStack {
        StudyProgressChartView()
    }
}

