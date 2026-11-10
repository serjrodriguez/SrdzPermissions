//
//  CoreLocationBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

#if os(iOS)
import CoreLocation
import Foundation

@MainActor
final class CoreLocationBackend: NSObject, LocationBackend, CLLocationManagerDelegate {
    nonisolated let events: AsyncStream<LocationBackendEvent>
    private nonisolated let continuation: AsyncStream<LocationBackendEvent>.Continuation
    private let manager = CLLocationManager()

    override init() {
        let (events, continuation) = AsyncStream.makeStream(of: LocationBackendEvent.self)
        self.events = events
        self.continuation = continuation
        super.init()
        manager.delegate = self
    }

    deinit {
        continuation.finish()
    }

    func currentStatus() async -> LocationStatus {
        Self.status(from: manager)
    }

    func requestAuthorization(_ access: LocationAccess) async {
        switch access {
        case .whenInUse: manager.requestWhenInUseAuthorization()
        case .always: manager.requestAlwaysAuthorization()
        }
    }

    func startUpdates(_ options: LocationUpdateOptions) async {
        manager.desiredAccuracy = options.accuracy.coreLocationValue
        manager.distanceFilter = options.distanceFilter ?? kCLDistanceFilterNone
        manager.allowsBackgroundLocationUpdates = options.allowsBackgroundUpdates && Self.hasLocationBackgroundMode
        manager.startUpdatingLocation()
    }

    func stopUpdates() async {
        manager.stopUpdatingLocation()
    }

    func requestOneShot() async {
        manager.requestLocation()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        continuation.yield(.authorizationChanged(Self.status(from: manager)))
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation.yield(.locationsUpdated(locations.map(Location.init(_:))))
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let clError = error as? CLError else {
            continuation.yield(.failed(.underlying(description: error.localizedDescription)))
            return
        }
        switch clError.code {
        case .locationUnknown:
            break
        case .denied:
            continuation.yield(.failed(.notAuthorized(.denied)))
        default:
            continuation.yield(.failed(.underlying(description: clError.localizedDescription)))
        }
    }

    private nonisolated static func status(from manager: CLLocationManager) -> LocationStatus {
        let precision: LocationPrecision = manager.accuracyAuthorization == .reducedAccuracy ? .reduced : .full
        switch manager.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return LocationStatus(permission: .restricted)
        case .denied:
            return LocationStatus(permission: .denied)
        case .authorizedWhenInUse:
            return LocationStatus(permission: precision == .reduced ? .limited : .authorized, access: .whenInUse, precision: precision)
        case .authorizedAlways:
            return LocationStatus(permission: precision == .reduced ? .limited : .authorized, access: .always, precision: precision)
        @unknown default:
            return .notDetermined
        }
    }

    private static var hasLocationBackgroundMode: Bool {
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
        return modes?.contains("location") ?? false
    }
}

private extension Location {
    init(_ location: CLLocation) {
        self.init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            speed: location.speed,
            course: location.course,
            timestamp: location.timestamp
        )
    }
}

private extension LocationDesiredAccuracy {
    var coreLocationValue: CLLocationAccuracy {
        switch self {
        case .best: kCLLocationAccuracyBest
        case .nearestTenMeters: kCLLocationAccuracyNearestTenMeters
        case .hundredMeters: kCLLocationAccuracyHundredMeters
        case .kilometer: kCLLocationAccuracyKilometer
        case .threeKilometers: kCLLocationAccuracyThreeKilometers
        }
    }
}
#endif
