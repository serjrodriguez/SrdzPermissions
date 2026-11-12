//
//  PhotosPermission+Live.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
extension PhotosPermission {
    /// The real implementation, backed by Photos and PhotosUI.
    public static let live = PhotosPermission(
        provider: PhotosService(backend: PhotoLibraryBackend())
    )
}
#endif
