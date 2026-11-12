//
//  PhotosAccess.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

/// The kind of access to the photo library. Each level has its own status and Info.plist key.
public enum PhotosAccess: Sendable, Hashable {
    /// Read and write the library. Needs `NSPhotoLibraryUsageDescription`.
    case readWrite
    /// Only add photos to the library. Needs `NSPhotoLibraryAddUsageDescription`.
    case addOnly
}
