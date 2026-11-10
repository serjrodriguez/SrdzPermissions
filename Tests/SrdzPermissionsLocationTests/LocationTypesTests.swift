import Testing
@testable import SrdzPermissionsLocation

@Suite struct LocationTypesTests {
    @Test func notDetermined() {
        #expect(LocationStatus.notDetermined.permission == .notDetermined)

        #expect(LocationStatus.notDetermined.access == nil)
    }
    
    @Test func optionsDefaults() {
        let options = LocationUpdateOptions()
        #expect(options.accuracy == .best)
        #expect(options.distanceFilter == nil)
        #expect(options.allowsBackgroundUpdates == false)
    }
    
    @Test func locationDefaultsToInvalidAccuracy() {
        let location = Location(latitude: 19.43, longitude: -99.13)
        #expect(location.horizontalAccuracy < 0)
    }
}
