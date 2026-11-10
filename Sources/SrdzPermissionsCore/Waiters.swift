//
//  Waiters.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation

package struct Waiters<Value: Sendable> {
    
    private var items: [UUID: CheckedContinuation<Value, Error>] = [:]
    
    package var count: Int { items.count }
    package var isEmpty: Bool { items.isEmpty }
    
    package init() { }
    
    package mutating func add(_ id: UUID, _ continuation: CheckedContinuation<Value, Error>) {
        items[id] = continuation
    }
    
    package mutating func resumeAll(returning value: Value) {
        let all = items.values
        items.removeAll()
        for continuation in all { continuation.resume(returning: value) }
    }
    
    package mutating func resumeAll(throwing error: Error) {
        let all = items.values
        items.removeAll()
        for continuation in all { continuation.resume(throwing: error) }
    }
    
    package mutating func cancel(_ id: UUID) {
        items.removeValue(forKey: id)?.resume(throwing: CancellationError())
    }
}
