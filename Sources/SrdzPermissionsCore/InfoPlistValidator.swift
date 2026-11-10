//
//  InfoPlistValidator.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation

package enum InfoPlistValidator {
    package static func require(_ key: String, in bundle: Bundle = .main) throws {
        let value = bundle.object(forInfoDictionaryKey: key) as? String
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PermissionError.missingUsageDescription(key: key)
        }
    }
}
