//
//  Transition.swift
//  Stateful
//
//  Created by Alberto De Bortoli on 16/12/2018.
//

import Foundation

public enum TransitionResult {
    case success
    case failure
}

public typealias ExecutionBlock = (() -> Void)
public typealias TransitionBlock = ((TransitionResult) -> Void)
public typealias GuardBlock = (() -> Bool)

public struct Transition<State, Event> {
    
    public let event: Event
    public let source: State
    public let destination: State
    let preBlock: ExecutionBlock?
    let postBlock: ExecutionBlock?
    let guardBlock: GuardBlock?
    
    public init(with event: Event,
                from: State,
                to: State,
                preBlock: ExecutionBlock? = nil,
                postBlock: ExecutionBlock? = nil,
                guardBlock: GuardBlock? = nil) {
        self.event = event
        self.source = from
        self.destination = to
        self.preBlock = preBlock
        self.postBlock = postBlock
        self.guardBlock = guardBlock
    }
    
    func executePreBlock() {
        preBlock?()
    }
    
    func executePostBlock() {
        postBlock?()
    }
}
