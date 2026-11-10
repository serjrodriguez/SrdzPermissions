//
//  InfoPlistValidatorTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Testing
import Foundation
@testable import SrdzPermissionsCore

@Suite struct InfoPlistValidatorTests {
    @Test func throwsWhenKeyIsMissing() {
        #expect(throws: PermissionError.missingUsageDescription(key: "NSFakeKey")) {
            try InfoPlistValidator.require("NSFakeKey", in: Bundle(for: BundleToken.self))
        }
    }
    private final class BundleToken {}
}
