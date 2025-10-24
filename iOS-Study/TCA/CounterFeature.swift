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
    }
    
    enum Action {
        case incrementButtonTapped
        case decrementButtonTapped
        case resetButtonTapped
        case loadingChanged(Bool)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .incrementButtonTapped:
                state.count += 1
                return .none
                
            case .decrementButtonTapped:
                state.count -= 1
                return .none
                
            case .resetButtonTapped:
                state.count = 0
                return .none
                
            case let .loadingChanged(isLoading):
                state.isLoading = isLoading
                return .none
            }
        }
    }
}
