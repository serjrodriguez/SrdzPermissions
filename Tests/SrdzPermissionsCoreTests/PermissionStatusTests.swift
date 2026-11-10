import Testing
@testable import SrdzPermissionsCore

@Suite struct PermissionStatusTests {
    @Test(arguments: [
        (PermissionStatus.authorized, true),

        (.limited, true),
        (.notDetermined, false),
        (.denied, false),
        (.restricted, false),
    ])
    func isGranted(status: PermissionStatus, expected: Bool) {
        #expect(status.isGranted == expected)
    }
    
    @Test func errorsAreEquatable() {
        #expect(PermissionError.notAuthorized(.denied) == .notAuthorized(.denied))
        #expect(PermissionError.notAuthorized(.denied) != .notAuthorized(.restricted))
    }
}
