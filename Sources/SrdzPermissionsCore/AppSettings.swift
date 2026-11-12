//
//  AppSettings.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

#if os(iOS)
import UIKit

/// Opens the app's page in the Settings app.
///
/// After the user denies a permission this is the only way to change it, because iOS shows the system prompt once.
public enum AppSettings {
    /// Opens the Settings page for this app.
    ///
    /// - Returns: `true` if Settings opened.
    @MainActor
    @discardableResult
    public static func open() async -> Bool {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return false }
        return await UIApplication.shared.open(url)
    }
}
#endif
