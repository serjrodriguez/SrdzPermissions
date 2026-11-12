//
//  AppSettings.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

#if os(iOS)
import UIKit

public enum AppSettings {
    @MainActor
    @discardableResult
    public static func open() async -> Bool {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return false }
        return await UIApplication.shared.open(url)
    }
}
#endif
