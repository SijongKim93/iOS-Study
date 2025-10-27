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
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .incrementButtonTapped:
                state.count += 1
                state.lastAction = "증가"
                state.errorMessage = nil
                return .none
                
            case .decrementButtonTapped:
                state.count -= 1
                state.lastAction = "감소"
                state.errorMessage = nil
                return .none
                
            case .resetButtonTapped:
                state.count = 0
                state.lastAction = "리셋"
                state.errorMessage = nil
                return .none
                
            case .doubleButtonTapped:
                state.count *= 2
                state.lastAction = "2배 증가"
                state.errorMessage = nil
                return .none
                
            case .randomButtonTapped:
                state.count = Int.random(in: -100...100)
                state.lastAction = "랜덤 값"
                state.errorMessage = nil
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
            }
        }
    }
}
