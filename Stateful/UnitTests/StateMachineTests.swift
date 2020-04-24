//
//  StateMachine.swift
//  Stateful
//
//  Created by Alberto De Bortoli on 16/12/2018.
//

import XCTest
@testable import Stateful

class aTests: XCTestCase {
    
    typealias TransitionDefault = Transition<StateType, EventType>
    typealias StateMachineDefault = StateMachine<StateType, EventType>
    
    enum EventType {
        case e1
        case e2
    }
    
    enum StateType {
        case idle
        case started
        case running
        case completed
    }
    
    var stateMachine: StateMachine<StateType, EventType>!
    
    override func setUp() {
        super.setUp()
        stateMachine = StateMachineDefault(initialState: .idle)
        stateMachine.enableLogging = true
    }
    
    override func tearDown() {
        stateMachine = nil
        super.tearDown()
    }
    
    func test_Creation() {
        XCTAssertEqual(stateMachine.currentState, .idle)
    }
    
    func test_SingleTransition() {
        stateMachine.process(event: .e1)
        XCTAssertEqual(stateMachine.currentState, .idle)
        
        let transition = TransitionDefault(with: .e1, from: .idle, to: .started)
        stateMachine.add(transition: transition)
        stateMachine.process(event: .e1)
        XCTAssertEqual(stateMachine.currentState, .started)
    }
    
    func test_MultipleTransistions() {
        stateMachine.process(event: .e1)
        XCTAssertEqual(stateMachine.currentState, .idle)
        
        let transition1 = TransitionDefault(with: .e1, from: .idle, to: .started)
        stateMachine.add(transition: transition1)
        let transition2 = TransitionDefault(with: .e2, from: .started, to: .idle)
        stateMachine.add(transition: transition2)
        let transition3 = TransitionDefault(with: .e1, from: .started, to: .idle)
        stateMachine.add(transition: transition3)
        
        stateMachine.process(event: .e1)
        XCTAssertEqual(stateMachine.currentState, .started)
        stateMachine.process(event: .e2)
        XCTAssertEqual(stateMachine.currentState, .idle)
        stateMachine.process(event: .e1)
        XCTAssertEqual(stateMachine.currentState, .started)
        stateMachine.process(event: .e1)
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

  func test_GuardedTransistions() {
      stateMachine.process(event: .e1)
      XCTAssertEqual(stateMachine.currentState, .idle)

      var shouldGoToIdle = true

      let transition1 = TransitionDefault(with: .e1, from: .idle, to: .started)
      stateMachine.add(transition: transition1)
      let transition2 = TransitionDefault(with: .e2, from: .started, to: .idle, guardBlock: { return shouldGoToIdle })
      stateMachine.add(transition: transition2)
      let transition3 = TransitionDefault(with: .e2, from: .started, to: .running)
      stateMachine.add(transition: transition3)

      stateMachine.process(event: .e1)
      XCTAssertEqual(stateMachine.currentState, .started)
      stateMachine.process(event: .e2)
      XCTAssertEqual(stateMachine.currentState, .idle)
      stateMachine.process(event: .e1)
      XCTAssertEqual(stateMachine.currentState, .started)

      shouldGoToIdle = false
      stateMachine.process(event: .e2)
      XCTAssertEqual(stateMachine.currentState, .running)
  }


  func test_ActionCallbacks() {
    let expectation1 = XCTestExpectation(description: #function)
    let expectation2 = XCTestExpectation(description: #function)

    let action1 = ActionCallback<StateType>(state: .started,
                                            execution: { expectation1.fulfill() },
                                            action: .entry)
    let action2 = ActionCallback<StateType>(state: .started,
                                            execution: { expectation2.fulfill() },
                                            action: .exit)
    stateMachine.add(callback: action1)
    stateMachine.add(callback: action2)
    let transition1 = TransitionDefault(with: .e1, from: .idle, to: .started)
    let transition2 = TransitionDefault(with: .e1, from: .started, to: .idle)
    stateMachine.add(transition: transition1)
    stateMachine.add(transition: transition2)

    stateMachine.process(event: .e1)
    wait(for: [expectation1], timeout: 2)
    stateMachine.process(event: .e1)
    wait(for: [expectation2], timeout: 2)
  }
}
