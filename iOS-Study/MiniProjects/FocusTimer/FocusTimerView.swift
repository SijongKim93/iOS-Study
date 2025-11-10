//
//  FocusTimerView.swift
//  iOS-Study
//
//  Created by GPT-5 Codex on 11/10/25.
//

import SwiftUI
import Combine

struct FocusTimerView: View {
    @StateObject private var viewModel = FocusTimerViewModel()
    
    var body: some View {
        List {
            Section("현재 상태") {
                VStack(spacing: 16) {
                    Text(viewModel.phaseTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.phaseColor)
                        .frame(maxWidth: .infinity)
                    
                    Text(viewModel.formattedRemainingTime)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)
                    
                    ProgressView(value: viewModel.progress, total: 1.0) {
                        EmptyView()
                    } currentValueLabel: {
                        Text(viewModel.progressLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .progressViewStyle(.linear)
                    
                    if let message = viewModel.bannerMessage {
                        Label(message, systemImage: "lightbulb.max")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            
            Section("컨트롤") {
                HStack(spacing: 12) {
                    Button(action: viewModel.toggleRunning) {
                        Label(viewModel.isRunning ? "일시정지" : "시작",
                              systemImage: viewModel.isRunning ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(role: .destructive, action: viewModel.reset) {
                        Label("리셋", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canReset)
                    
                    Button(action: viewModel.skipPhase) {
                        Label("다음 단계", systemImage: "forward.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canSkipPhase)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Toggle(isOn: $viewModel.autoRepeatEnabled) {
                    Label("완료 후 자동 반복", systemImage: "repeat")
                }
                .toggleStyle(.switch)
            }
            
            Section("세션 설정") {
                Stepper(value: viewModel.focusDurationBinding, in: 5...120, step: 5) {
                    Label("집중 시간", systemImage: "brain.head.profile")
                    Spacer()
                    Text("\(viewModel.focusDurationMinutes)분")
                        .foregroundStyle(.secondary)
                }
                
                Stepper(value: viewModel.breakDurationBinding, in: 0...30, step: 1) {
                    Label("휴식 시간", systemImage: "cup.and.saucer")
                    Spacer()
                    Text("\(viewModel.breakDurationMinutes)분")
                        .foregroundStyle(.secondary)
                }
            }
            
            if !viewModel.completedSessions.isEmpty {
                Section("완료 기록") {
                    HStack {
                        Label("누적 집중 시간", systemImage: "timer")
                        Spacer()
                        Text(viewModel.totalFocusDurationLabel)
                            .foregroundStyle(.secondary)
                    }
                    
                    ForEach(viewModel.completedSessions) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Label("집중 \(session.focusDurationMinutes)분 완료",
                                      systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Spacer()
                                Text(session.completedAt, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if session.breakDurationMinutes > 0 {
                                Text("휴식 \(session.breakDurationMinutes)분 포함")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(session.summaryDescription)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("포커스 타이머")
        .animation(.easeInOut, value: viewModel.isRunning)
        .animation(.easeInOut, value: viewModel.completedSessions)
    }
}

// MARK: - View Model

@MainActor
final class FocusTimerViewModel: ObservableObject {
    enum Phase: String {
        case focus
        case rest
        
        var label: String {
            switch self {
            case .focus:
                return "집중 시간"
            case .rest:
                return "휴식 시간"
            }
        }
    }
    
    struct FocusSession: Identifiable {
        let id = UUID()
        let completedAt: Date
        let focusDurationMinutes: Int
        let breakDurationMinutes: Int
        let autoRepeatEnabled: Bool
        
        var summaryDescription: String {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.localizedString(for: completedAt, relativeTo: .now)
        }
    }
    
    @Published var focusDurationMinutes: Int = 25 {
        didSet { focusDurationMinutes = clamp(focusDurationMinutes, min: 5, max: 120); syncRemainingIfNeeded(for: .focus) }
    }
    
    @Published var breakDurationMinutes: Int = 5 {
        didSet { breakDurationMinutes = clamp(breakDurationMinutes, min: 0, max: 30); syncRemainingIfNeeded(for: .rest) }
    }
    
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var currentPhase: Phase = .focus
    @Published private(set) var isRunning: Bool = false
    @Published var autoRepeatEnabled: Bool = false
    @Published private(set) var completedSessions: [FocusSession] = []
    @Published private(set) var bannerMessage: String?
    
    var focusDurationBinding: Binding<Int> {
        Binding(
            get: { self.focusDurationMinutes },
            set: { self.focusDurationMinutes = $0 }
        )
    }
    
    var breakDurationBinding: Binding<Int> {
        Binding(
            get: { self.breakDurationMinutes },
            set: { self.breakDurationMinutes = $0 }
        )
    }
    
    var progress: Double {
        let total = max(currentPhaseTotalSeconds, 1)
        return 1 - Double(remainingSeconds) / Double(total)
    }
    
    var progressLabel: String {
        let percentage = Int(progress * 100)
        return "\(percentage)% 완료"
    }
    
    var phaseTitle: String {
        currentPhase.label + (isRunning ? " 진행 중" : " 준비")
    }
    
    var formattedRemainingTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var phaseColor: Color {
        switch currentPhase {
        case .focus:
            return .green
        case .rest:
            return .blue
        }
    }
    
    var canReset: Bool {
        isRunning || remainingSeconds != focusDurationMinutes * 60 || currentPhase != .focus || !completedSessions.isEmpty
    }
    
    var canSkipPhase: Bool {
        currentPhase == .focus ? breakDurationMinutes > 0 : true
    }
    
    var totalFocusDurationLabel: String {
        let totalMinutes = completedSessions.reduce(0) { $0 + $1.focusDurationMinutes }
        if totalMinutes == 0 { return "0분" }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        }
        return "\(minutes)분"
    }
    
    private var timerCancellable: AnyCancellable?
    
    init() {
        remainingSeconds = 25 * 60
    }
    
    deinit {
        timerCancellable?.cancel()
    }
    
    func toggleRunning() {
        isRunning ? pause() : start()
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        bannerMessage = currentPhase == .focus ? "한 번에 한 가지에 집중해보세요!" : "짧은 휴식을 취하며 머리를 식혀보세요."
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    func pause() {
        guard isRunning else { return }
        isRunning = false
        bannerMessage = "필요할 때 언제든 다시 시작할 수 있어요."
        timerCancellable?.cancel()
    }
    
    func reset() {
        timerCancellable?.cancel()
        isRunning = false
        currentPhase = .focus
        remainingSeconds = focusDurationMinutes * 60
        bannerMessage = nil
    }
    
    func skipPhase() {
        completeCurrentPhase(skipped: true)
    }
    
    private func tick() {
        guard isRunning else { return }
        guard currentPhaseTotalSeconds > 0 else {
            completeCurrentPhase()
            return
        }
        
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            if remainingSeconds == 0 {
                completeCurrentPhase()
            }
        } else {
            completeCurrentPhase()
        }
    }
    
    private func completeCurrentPhase(skipped: Bool = false) {
        switch currentPhase {
        case .focus:
            if !skipped {
                let session = FocusSession(
                    completedAt: .now,
                    focusDurationMinutes: focusDurationMinutes,
                    breakDurationMinutes: breakDurationMinutes,
                    autoRepeatEnabled: autoRepeatEnabled
                )
                completedSessions.insert(session, at: 0)
            }
            if breakDurationMinutes > 0 {
                transitionToRestPhase(shouldContinue: autoRepeatEnabled && !skipped)
            } else {
                transitionToNextFocusCycle(shouldContinue: autoRepeatEnabled && !skipped)
            }
            
        case .rest:
            transitionToNextFocusCycle(shouldContinue: autoRepeatEnabled && !skipped)
        }
    }
    
    private func transitionToRestPhase(shouldContinue: Bool) {
        currentPhase = .rest
        remainingSeconds = max(breakDurationMinutes * 60, 1)
        
        if shouldContinue {
            bannerMessage = "휴식 시간입니다. 잠깐 일어나서 몸을 풀어보세요."
            start()
        } else {
            pause()
            bannerMessage = "휴식 시간입니다. 잠깐 일어나서 몸을 풀어보세요."
        }
    }
    
    private func transitionToNextFocusCycle(shouldContinue: Bool) {
        currentPhase = .focus
        remainingSeconds = max(focusDurationMinutes * 60, 1)
        
        if shouldContinue {
            bannerMessage = "새로운 집중 세션을 준비해보세요."
            start()
        } else {
            pause()
            bannerMessage = "새로운 집중 세션을 준비해보세요."
        }
    }
    
    private func syncRemainingIfNeeded(for phase: Phase) {
        guard !isRunning else { return }
        
        switch (phase, currentPhase) {
        case (.focus, .focus):
            remainingSeconds = focusDurationMinutes * 60
        case (.rest, .rest):
            remainingSeconds = max(breakDurationMinutes * 60, 1)
        default:
            break
        }
    }
    
    private func clamp(_ value: Int, min: Int, max: Int) -> Int {
        if value < min { return min }
        if value > max { return max }
        return value
    }
    
    private var currentPhaseTotalSeconds: Int {
        switch currentPhase {
        case .focus:
            return focusDurationMinutes * 60
        case .rest:
            return breakDurationMinutes * 60
        }
    }
}

#Preview {
    NavigationStack {
        FocusTimerView()
    }
}

