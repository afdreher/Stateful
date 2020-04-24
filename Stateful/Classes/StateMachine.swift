//
//  StateMachine.swift
//  Stateful
//
//  Created by Alberto De Bortoli on 16/12/2018.
//

import Foundation

open class StateMachine<State: Hashable, Event: Hashable> {
    
    public var enableLogging: Bool = false
    public var currentState: State {
        return {
            workingQueue.sync {
                return internalCurrentState
            }
            }()
    }
    
    private var internalCurrentState: State
    private var transitionsByEvent: [Event : [Transition<State, Event>]] = [:]
  private var callbacksByState: [State : [Action: ActionCallback<State>]] = [:]
    
    private let lockQueue: DispatchQueue
    private let workingQueue: DispatchQueue
    private let callbackQueue: DispatchQueue
    
    public init(initialState: State, callbackQueue: DispatchQueue? = nil) {
        self.internalCurrentState = initialState
        self.lockQueue = DispatchQueue(label: "com.albertodebortoli.statemachine.queue.lock")
        self.workingQueue = DispatchQueue(label: "com.albertodebortoli.statemachine.queue.working")
        self.callbackQueue = callbackQueue ?? .main
    }

    public func add(callback: ActionCallback<State>) {
        lockQueue.sync {
          // See if the state & action already exist
          if let callback = self.callbacksByState[callback.state]?[callback.action] {
              assertionFailure("Callback already exists for state \(callback.state).")
          }
          // Add the callback
          if self.callbacksByState[callback.state] == nil {
              self.callbacksByState[callback.state] = [:]
          }
          self.callbacksByState[callback.state]![callback.action] = callback
        }
    }
    
    public func add(transition: Transition<State, Event>) {
        lockQueue.sync {
            if let transitions = self.transitionsByEvent[transition.event] {
                if (transitions.filter { return $0.source == transition.source && $0.guardBlock == nil}.count > 0) {
                    assertionFailure("Transition with event '\(transition.event)' and source '\(transition.source)' already existing.")
                }
                self.transitionsByEvent[transition.event]?.append(transition)
            } else {
                self.transitionsByEvent[transition.event] = [transition]
            }
        }
    }
    
    public func process(event: Event, execution: (() -> Void)? = nil, callback: TransitionBlock? = nil) {
        var transitions: [Transition<State, Event>]?
        lockQueue.sync {
            transitions = self.transitionsByEvent[event]
        }
        
        workingQueue.async {
            let performableTransitions = transitions?.filter { return $0.source == self.internalCurrentState } ?? []
            
            if performableTransitions.count == 0 {
                self.callbackQueue.async {
                    callback?(.failure)
                }
                return
            }

            // Check the guards
            var performableTransition: Transition<State, Event>?
            for transition in performableTransitions {
                if transition.guardBlock == nil || transition.guardBlock!() {
                    performableTransition = transition
                    break
                }
            }

            guard let transition = performableTransition else {
                self.callbackQueue.async {
                    callback?(.failure)
                }
                return
            }

            self.log(message: "Processing event '\(event)' from '\(self.internalCurrentState)'")
            self.callbackQueue.async {
                transition.executePreBlock()
            }

            if let exitCallback = self.callbacksByState[self.internalCurrentState]?[.exit] {
                self.log(message: "Processed exit callback for state '\(self.internalCurrentState)'")

                self.callbackQueue.async {
                    exitCallback.execute()
                }
            }

            self.log(message: "Processed pre condition for event '\(event)' from '\(transition.source)' to '\(transition.destination)'")
            
            self.callbackQueue.async {
                execution?()
            }
            
            let previousState = self.internalCurrentState
            self.internalCurrentState = transition.destination

            self.log(message: "Processed state change from '\(previousState)' to '\(transition.destination)'")

            if let entryCallback = self.callbacksByState[self.internalCurrentState]?[.entry] {
                self.log(message: "Processed entry callback for state '\(self.internalCurrentState)'")

                self.callbackQueue.async {
                    entryCallback.execute()
                }
            }

            self.callbackQueue.async {
                transition.executePostBlock()
            }
            
            self.log(message: "Processed post condition for event '\(event)' from '\(transition.source)' to '\(transition.destination)'")
            
            self.callbackQueue.async {
                callback?(.success)
            }
        }
    }
    
    private func log(message: String) {
        if self.enableLogging {
            print("[Stateful 🦜] \(message)")
        }
    }
}
