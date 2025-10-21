//
//  CounterReactor.swift
//  ReactorKit-Demo
//
//  Created by duse on 10/14/25.
//

import ReactorKit
import RxSwift

final class CounterReactor: Reactor {
    enum Action {
        case increaseButtonTapped
        case decreaseButtonTapped
        case resetButtonTapped
    }
    
    enum Mutation {
        case addValue(Int)
        case resetValue
    }
    
    struct State {
        var count: Int = 0
        var isLoading: Bool = false
    }
    
    let initialState: State = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .increaseButtonTapped:
            return Observable.just(Mutation.addValue(1))
        case .decreaseButtonTapped:
            return Observable.just(Mutation.addValue(-1))
        case .resetButtonTapped:
            return Observable.just(Mutation.resetValue)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case let .addValue(value):
            newState.count += value
            
        case .resetValue:
            newState.count = 0
        }
        
        return newState
    }
}
