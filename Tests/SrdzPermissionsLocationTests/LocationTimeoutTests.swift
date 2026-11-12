//
//  LocationTimeoutTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import Testing
@testable import SrdzPermissionsLocation

@Suite struct LocationTimeoutTests {
    @Test(arguments: [TimeInterval.infinity, TimeInterval.greatestFiniteMagnitude, TimeInterval(1e30), TimeInterval(1e12)])
    func hugeTimeoutsAreCappedInsteadOfCrashing(timeout: TimeInterval) {
        let nanoseconds = LocationService.nanoseconds(from: timeout)

        #expect(nanoseconds == 1_000_000_000 * 1_000_000_000)
    }

    @Test(arguments: [TimeInterval.nan, TimeInterval(-5), -TimeInterval.infinity, TimeInterval(0)])
    func invalidOrNonPositiveTimeoutsAreZero(timeout: TimeInterval) {
        #expect(LocationService.nanoseconds(from: timeout) == 0)
    }

    @Test func aNormalTimeoutConvertsToNanoseconds() {
        #expect(LocationService.nanoseconds(from: 10) == 10_000_000_000)
        #expect(LocationService.nanoseconds(from: 0.5) == 500_000_000)
    }

    @Test func anInfiniteTimeoutStillReturnsTheLocation() async throws {
        let backend = FakeLocationBackend(status: .whenInUse)
        await backend.setAnswerToOneShot(.mexicoCity)
        let service = LocationService(makeBackend: { backend }, validateUsageDescriptions: { _ in })

        let location = try await service.currentLocation(timeout: .infinity)

        #expect(location == .mexicoCity)
    }
}
