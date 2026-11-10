//
//  WaitersTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Testing
import Foundation
@testable import SrdzPermissionsCore

private actor Box {
    var waiters = Waiters<Int>()
    
    func wait(_ id: UUID = UUID()) async throws -> Int {
        try await withCheckedThrowingContinuation { waiters.add(id, $0) }
    }
    func resume(_ value: Int) { waiters.resumeAll(returning: value) }
    func cancel(_ id: UUID) { waiters.cancel(id) }
    var count: Int { waiters.count }
}

@Suite struct WaitersTests {
    @Test func resumesAllWaitersWithSameValue() async throws {
        let box = Box()
        async let a = box.wait()
        async let b = box.wait()
        while await box.count < 2 { await Task.yield() }
        await box.resume(42)
        #expect(try await a == 42)
        #expect(try await b == 42)
        #expect(await box.count == 0)
    }
    
    @Test func cancelResumesOnlyThatWaiterWithCancellationError() async throws {
        let box = Box()
        let id = UUID()
        let task = Task { try await box.wait(id) }
        while await box.count < 1 { await Task.yield() }
        await box.cancel(id)
        await #expect(throws: CancellationError.self) { try await task.value }
    }
}
