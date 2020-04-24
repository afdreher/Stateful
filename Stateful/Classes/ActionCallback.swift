//
//  StateMachine.swift
//  Stateful
//
//  Created by Andrew Dreher on 24/04/2020.
//

import Foundation

public enum Action {
    case entry
    case exit
}

public struct ActionCallback<State> {

    public let state: State
    public let action: Action
    let execution: ExecutionBlock

    public init(state: State, execution: @escaping ExecutionBlock, action: Action) {
        self.state = state
        self.action = action
        self.execution = execution
    }

    func execute() {
        execution()
    }
}
