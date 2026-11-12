//
//  NotificationOptionsTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Testing
import SrdzPermissionsNotifications

@Suite struct NotificationOptionsTests {
    @Test func standardIsAlertSoundAndBadge() {
        #expect(NotificationOptions.standard == [.alert, .sound, .badge])
    }

    @Test func provisionalIsNotPartOfTheStandardOptions() {
        #expect(!NotificationOptions.standard.contains(.provisional))
    }
}
