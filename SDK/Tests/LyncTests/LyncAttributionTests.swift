import XCTest
@testable import Lync

final class LyncTests: XCTestCase {
    
    var lync: Lync!
    
    override func setUpWithError() throws {
        let config = Lync.Config(
            apiBaseURL: "https://test.example.com",
            entityId: "test-entity-id",
            debug: true
        )
        lync = Lync(config: config)
    }
    
    override func tearDownWithError() throws {
        lync = nil
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "lync_click_id")
        UserDefaults.standard.removeObject(forKey: "lync_install_time")
        UserDefaults.standard.removeObject(forKey: "lync_session_count")
        UserDefaults.standard.removeObject(forKey: "lync_first_launch")
    }
    
    func testClickIdStorage() throws {
        let testClickId = "test-click-id-123"
        
        lync.setClickId(testClickId)
        
        let storedClickId = UserDefaults.standard.string(forKey: "lync_click_id")
        XCTAssertEqual(storedClickId, testClickId)
    }
    
    func testDeepLinkClickIdExtraction() throws {
        let urlWithClickId = URL(string: "myapp://open?click_id=abc123&other=param")!
        let extractedClickId = Lync.extractClickId(from: urlWithClickId)
        
        XCTAssertEqual(extractedClickId, "abc123")
        
        let urlWithoutClickId = URL(string: "myapp://open?other=param")!
        let noClickId = Lync.extractClickId(from: urlWithoutClickId)
        
        XCTAssertNil(noClickId)
    }
    
    func testDeviceInfoCreation() throws {
        let deviceInfo = Lync.DeviceInfo.current()
        
        XCTAssertEqual(deviceInfo.platform, "ios")
        XCTAssertFalse(deviceInfo.osVersion.isEmpty)
        XCTAssertFalse(deviceInfo.bundleId.isEmpty)
        XCTAssertGreaterThan(deviceInfo.screenWidth, 0)
        XCTAssertGreaterThan(deviceInfo.screenHeight, 0)
    }
    
    func testAppContextCreation() throws {
        let appContext = Lync.AppContext.current()
        
        XCTAssertFalse(appContext.sessionId.isEmpty)
        XCTAssertNotNil(appContext.installTime)
        XCTAssertTrue(appContext.firstLaunch) // Should be true for first test run
    }
    
    func testConfigInitialization() throws {
        let config = Lync.Config(
            apiBaseURL: "https://api.example.com",
            entityId: "entity-123",
            apiKey: "key-456",
            debug: true
        )
        
        XCTAssertEqual(config.apiBaseURL, "https://api.example.com")
        XCTAssertEqual(config.entityId, "entity-123")
        XCTAssertEqual(config.apiKey, "key-456")
        XCTAssertTrue(config.debug)
    }
} 