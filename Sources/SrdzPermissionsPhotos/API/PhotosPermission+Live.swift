//
//  PhotosPermission+Live.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
extension PhotosPermission {
    public static let live = PhotosPermission(
        provider: PhotosService(backend: PhotoLibraryBackend())
    )
}
#endif
