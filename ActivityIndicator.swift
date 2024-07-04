//
//  ActivityIndicator.swift
//
//
//  Created by Mohammed Essam.
//  
//

import Foundation
import Combine

/// A class that tracks the activity state of Publishers.
public class ActivityIndicator {
    private let lock = NSRecursiveLock()
    private let subject = CurrentValueSubject<Bool, Never>(false)
    private var count = 0
    public var currentValue: Bool {
        return !count.isEmpty
    }
    
    /// A publisher that emits the current activity state.
    public var isActive: AnyPublisher<Bool, Never> {
        return subject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    /// Tracks the activity of a given publisher.
    /// - Parameters:
    ///   - publisher: The publisher to track.
    ///   - shouldIncrement: Indicates whether to increment the activity state when tracking starts.
    ///   - decrementInCaseOfFailureOnly: Indicates whether to decrement the activity state only in case of failure.
    /// - Returns: A publisher that mirrors the given publisher but also tracks its activity.
    fileprivate func trackActivityOfPublisher<P: Publisher>(
        _ publisher: P,
        shouldIncrement: Bool = true,
        decrementInCaseOfFailureOnly: Bool = false
    ) -> AnyPublisher<P.Output, P.Failure> {
        return Deferred {
            if shouldIncrement {
                self.increment()
            }
            return publisher
                .handleEvents(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            if !decrementInCaseOfFailureOnly {
                                self.decrement()
                            }
                            
                        case .failure:
                            self.decrement()
                        }
                    },
                    receiveCancel: {
                        self.decrement()
                    }
                )
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    /// Increments the activity state.
    private func increment() {
        lock.lock()
        count += 1
        updateSubject()
        lock.unlock()
    }
    
    /// Decrements the activity state.
    private func decrement() {
        lock.lock()
        count -= 1
        updateSubject()
        lock.unlock()
    }
    
    /// Update  the activity state.
    private func updateSubject() {
        subject.send(currentValue)
    }
}

public extension Publisher {
    /// Tracks the activity of the publisher using the given `ActivityIndicator`.
    /// - Parameter activityIndicator: The `ActivityIndicator` to use for tracking.
    /// - Returns: A publisher that mirrors the current publisher but also tracks its activity.
    func trackActivity(
        _ activityIndicator: ActivityIndicator
    ) -> AnyPublisher<Output, Failure> {
        return activityIndicator.trackActivityOfPublisher(self)
    }
    
    /// Tracks the activity of the publisher using the given `ActivityIndicator`.
    /// - Parameters:
    ///   - activityIndicator: The `ActivityIndicator` to use for tracking.
    ///   - isLastOne: Indicates whether this is the last activity to track in a sequence.
    /// - Returns: A publisher that mirrors the current publisher but also tracks its activity.
    func trackActivitySequential(
        _ activityIndicator: ActivityIndicator,
        isLastOne: Bool = false
    ) -> AnyPublisher<Output, Failure> {
        return activityIndicator.trackActivityOfPublisher(
            self,
            shouldIncrement: !activityIndicator.currentValue,
            decrementInCaseOfFailureOnly: !isLastOne
        )
    }
}

/// Solving Lint Empty Count Violation
fileprivate extension Int {
    var isEmpty: Bool {
        return self == 0
    }
}
