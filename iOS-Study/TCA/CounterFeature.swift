//
//  CounterFeature.swift
//  iOS-Study
//
//  Created by duse on 10/23/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct CounterFeature {
    
    @ObservableState
    struct State: Equatable {
        var count = 0
        var isLoading = false
        var errorMessage: String?
        var lastAction: String = ""
        var history: [HistoryItem] = []
        var isAnimating = false
        var timerCount = 0
        var isTimerRunning = false
        var timerTargetCount: Int? = nil
        var isTimerCompleted = false
        var maxCount = 100
        var minCount = -100
    }
    
    struct HistoryItem: Equatable, Identifiable {
        let id = UUID()
        let action: String
        let count: Int
        let timestamp: Date
        
        init(action: String, count: Int) {
            self.action = action
            self.count = count
            self.timestamp = Date()
        }
    }
    
    enum Action {
        case incrementButtonTapped
        case decrementButtonTapped
        case resetButtonTapped
        case doubleButtonTapped
        case randomButtonTapped
        case loadFromServer
        case serverResponse(Int)
        case serverError(String)
        case clearError
        
        case startTimer
        case stopTimer
        case timerTick
        case setTimerTarget(Int?)
        case timerCompleted
        case clearTimerCompleted
        case clearHistory
        case undoLastAction
        case setMaxCount(Int)
        case setMinCount(Int)
        case startAnimation
        case stopAnimation
        case performSequence
        case sequenceStep(Int)
        case checkBounds
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .incrementButtonTapped:
                state.count += 1
                state.lastAction = "증가"
                state.errorMessage = nil
                state.history.append(HistoryItem(action: "증가", count: state.count))
                return .send(.checkBounds)
                
            case .decrementButtonTapped:
                state.count -= 1
                state.lastAction = "감소"
                state.errorMessage = nil
                state.history.append(HistoryItem(action: "감소", count: state.count))
                return .send(.checkBounds)
                
            case .resetButtonTapped:
                state.count = 0
                state.lastAction = "리셋"
                state.errorMessage = nil
                state.history.append(HistoryItem(action: "리셋", count: state.count))
                return .none
                
            case .doubleButtonTapped:
                state.count *= 2
                state.lastAction = "2배 증가"
                state.errorMessage = nil
                state.history.append(HistoryItem(action: "2배 증가", count: state.count))
                return .send(.checkBounds)
                
            case .randomButtonTapped:
                state.count = Int.random(in: state.minCount...state.maxCount)
                state.lastAction = "랜덤 값"
                state.errorMessage = nil
                state.history.append(HistoryItem(action: "랜덤 값", count: state.count))
                return .none
                
            case .loadFromServer:
                state.isLoading = true
                state.errorMessage = nil
                state.lastAction = "서버 로딩 중..."
                // 비동기 작업 시뮬레이션
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    
                    // 30% 확률로 에러 발생
                    if Bool.random() {
                        await send(.serverError("서버 연결 실패"))
                    } else {
                        let randomValue = Int.random(in: 1...50)
                        await send(.serverResponse(randomValue))
                    }
                }
                
            case let .serverResponse(value):
                state.count = value
                state.isLoading = false
                state.lastAction = "서버에서 로드됨: \(value)"
                return .none
                
            case let .serverError(message):
                state.isLoading = false
                state.errorMessage = message
                state.lastAction = "에러 발생"
                return .none
                
            case .clearError:
                state.errorMessage = nil
                return .none
                
            // 새로운 액션들 처리
            case .startTimer:
                state.isTimerRunning = true
                state.timerCount = 0
                state.isTimerCompleted = false
                return .run { send in
                    while true {
                        try await Task.sleep(for: .seconds(1))
                        await send(.timerTick)
                    }
                }
                .cancellable(id: TimerID())
                
            case .stopTimer:
                state.isTimerRunning = false
                state.isTimerCompleted = false
                return .cancel(id: TimerID())
                
            case .timerTick:
                guard state.isTimerRunning else { return .none }
                
                state.timerCount += 1
                state.count += 1
                state.history.append(HistoryItem(action: "타이머 증가", count: state.count))
                

                if let target = state.timerTargetCount, state.timerCount >= target {
                    return .send(.timerCompleted)
                }
                
                return .none
                
            case let .setTimerTarget(target):
                state.timerTargetCount = target
                state.isTimerCompleted = false
                state.lastAction = target != nil ? "타이머 목표: \(target!)초" : "타이머 목표 제거"
                return .none
                
            case .timerCompleted:
                state.isTimerRunning = false
                state.isTimerCompleted = true
                state.lastAction = "타이머 완료! (\(state.timerCount)초)"
                state.history.append(HistoryItem(action: "타이머 완료", count: state.count))
                return .cancel(id: TimerID())
                
            case .clearTimerCompleted:
                state.isTimerCompleted = false
                state.timerTargetCount = nil
                state.lastAction = "타이머 완료 상태 클리어"
                return .none
                
            case .clearHistory:
                state.history.removeAll()
                state.lastAction = "히스토리 클리어"
                return .none
                
            case .undoLastAction:
                if let lastItem = state.history.last {
                    state.count = lastItem.count
                    state.history.removeLast()
                    state.lastAction = "실행 취소"
                }
                return .none
                
            case let .setMaxCount(value):
                state.maxCount = value
                state.lastAction = "최대값 설정: \(value)"
                return .send(.checkBounds)
                
            case let .setMinCount(value):
                state.minCount = value
                state.lastAction = "최소값 설정: \(value)"
                return .send(.checkBounds)
                
            case .startAnimation:
                state.isAnimating = true
                state.lastAction = "애니메이션 시작"
                return .run { send in
                    try await Task.sleep(for: .seconds(3))
                    await send(.stopAnimation)
                }
                
            case .stopAnimation:
                state.isAnimating = false
                state.lastAction = "애니메이션 종료"
                return .none
                
            case .performSequence:
                state.lastAction = "시퀀스 시작"
                return .run { send in
                    for i in 1...5 {
                        try await Task.sleep(for: .milliseconds(500))
                        await send(.sequenceStep(i))
                    }
                }
                
            case let .sequenceStep(step):
                state.count += step
                state.history.append(HistoryItem(action: "시퀀스 단계 \(step)", count: state.count))
                state.lastAction = "시퀀스 단계 \(step)"
                return .none
                
            case .checkBounds:
                if state.count > state.maxCount {
                    state.count = state.maxCount
                    state.errorMessage = "최대값 초과! \(state.maxCount)로 제한됨"
                } else if state.count < state.minCount {
                    state.count = state.minCount
                    state.errorMessage = "최소값 미만! \(state.minCount)로 제한됨"
                }
                return .none
            }
        }
    }
}

// 타이머 ID를 위한 구조체
private struct TimerID: Hashable {}

// 카운트 관련 통계 정보
struct CountStatistics: Equatable {
    var averageCount: Double
    var maxCount: Int
    var minCount: Int
    var totalActions: Int
}

// 카운트 클라이언트 프로토콜
struct CountClient {
    var save: (Int) async throws -> Void
    var load: () async throws -> Int?
    var calculateStatistics: ([HistoryItem]) -> CountStatistics
}

// 카운트 클라이언트 의존성
extension CountClient: DependencyKey {
    static var liveValue: CountClient {
        CountClient(
            save: { count in
                try await Task.sleep(for: .milliseconds(100))
                UserDefaults.standard.set(count, forKey: "savedCount")
            },
            load: {
                try await Task.sleep(for: .milliseconds(100))
                let savedCount = UserDefaults.standard.integer(forKey: "savedCount")
                return savedCount != 0 ? savedCount : nil
            },
            calculateStatistics: { history in
                guard !history.isEmpty else {
                    return CountStatistics(
                        averageCount: 0,
                        maxCount: 0,
                        minCount: 0,
                        totalActions: 0
                    )
                }
                
                let counts = history.map { $0.count }
                let sum = counts.reduce(0, +)
                let average = Double(sum) / Double(counts.count)
                
                return CountStatistics(
                    averageCount: average,
                    maxCount: counts.max() ?? 0,
                    minCount: counts.min() ?? 0,
                    totalActions: history.count
                )
            }
        )
    }
    
    static var testValue: CountClient {
        CountClient(
            save: { _ in },
            load: { nil },
            calculateStatistics: { _ in
                CountStatistics(
                    averageCount: 0,
                    maxCount: 0,
                    minCount: 0,
                    totalActions: 0
                )
            }
        )
    }
}

extension DependencyValues {
    var countClient: CountClient {
        get { self[CountClient.self] }
        set { self[CountClient.self] = newValue }
    }
}
