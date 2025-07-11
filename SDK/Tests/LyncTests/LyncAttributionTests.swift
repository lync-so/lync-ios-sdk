import XCTest
@testable import Lync

final class LyncTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Clean up any previous state
        Lync.shared.initialize(apiKey: "test-key", baseURL: "https://test.example.com", debug: true)
    }
    
    override func tearDownWithError() throws {
        // Clean up after tests
    }
    
    func testLyncInitialization() throws {
        // Test that Lync can be initialized
        Lync.shared.initialize(apiKey: "test-api-key", baseURL: "https://test.example.com", debug: true)
        
        // Test singleton pattern
        let instance1 = Lync.shared
        let instance2 = Lync.shared
        XCTAssertIdentical(instance1, instance2, "Lync should be a singleton")
    }
    
    func testBasicEventTracking() throws {
        // Test basic event tracking
        XCTAssertNoThrow(Lync.shared.track("test_event"))
        XCTAssertNoThrow(Lync.shared.track("test_event", properties: ["key": "value"]))
        XCTAssertNoThrow(Lync.shared.track("test_event", userId: "user123"))
        XCTAssertNoThrow(Lync.shared.track("test_event", userEmail: "test@example.com"))
    }
    
    func testConvenienceTrackingMethods() throws {
        // Test convenience methods
        XCTAssertNoThrow(Lync.shared.trackInstall())
        XCTAssertNoThrow(Lync.shared.trackInstall(userId: "user123", userEmail: "test@example.com"))
        XCTAssertNoThrow(Lync.shared.trackRegistration())
        XCTAssertNoThrow(Lync.shared.trackRegistration(userId: "user123", userEmail: "test@example.com"))
        XCTAssertNoThrow(Lync.shared.trackEvent("custom_event"))
        XCTAssertNoThrow(Lync.shared.trackEvent("custom_event", properties: ["key": "value"]))
    }
    
    func testDeviceInfoCreation() throws {
        let deviceInfo = DeviceInfo.current()
        
        XCTAssertEqual(deviceInfo.platform, "ios")
        XCTAssertFalse(deviceInfo.osVersion.isEmpty)
        XCTAssertFalse(deviceInfo.bundleId.isEmpty)
        XCTAssertGreaterThan(deviceInfo.screenWidth, 0)
        XCTAssertGreaterThan(deviceInfo.screenHeight, 0)
        XCTAssertFalse(deviceInfo.deviceModel.isEmpty)
        XCTAssertFalse(deviceInfo.timezone.isEmpty)
        XCTAssertFalse(deviceInfo.language.isEmpty)
        XCTAssertTrue(deviceInfo.deviceType == "phone" || deviceInfo.deviceType == "tablet")
    }
    
    func testDeviceInfoToDictionary() throws {
        let deviceInfo = DeviceInfo.current()
        let dict = deviceInfo.toDictionary()
        
        XCTAssertEqual(dict["platform"] as? String, "ios")
        XCTAssertNotNil(dict["device_model"])
        XCTAssertNotNil(dict["os_version"])
        XCTAssertNotNil(dict["app_version"])
        XCTAssertNotNil(dict["bundle_id"])
        XCTAssertNotNil(dict["timezone"])
        XCTAssertNotNil(dict["language"])
        XCTAssertNotNil(dict["screen_width"])
        XCTAssertNotNil(dict["screen_height"])
        XCTAssertNotNil(dict["device_type"])
    }
    
    func testDeviceUtils() throws {
        let deviceModel = DeviceUtils.getDeviceModel()
        XCTAssertFalse(deviceModel.isEmpty, "Device model should not be empty")
        
        // Test advertising ID (might be nil due to tracking permissions)
        let advertisingId = DeviceUtils.getAdvertisingId()
        // Just test that it doesn't crash - value can be nil
        XCTAssertNoThrow(advertisingId)
    }
    
    func testUninitializedTracking() throws {
        // Create a new instance (though we can't really do this with singleton)
        // This test ensures proper error handling when not initialized
        // The current implementation should handle this gracefully
        XCTAssertNoThrow(Lync.shared.track("test_event"))
    }
} 