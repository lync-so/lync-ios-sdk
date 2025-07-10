import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency

/**
 * LyncAttribution iOS SDK
 * 
 * Lightweight attribution tracking for iOS apps.
 * Tracks app installs, registrations, and custom events,
 * matching them to original click data stored in your system.
 * 
 * Usage:
 * 1. Initialize with your API URL and entity ID
 * 2. Call trackInstall() on first app launch
 * 3. Call trackRegistration() when user signs up
 * 4. Call trackEvent() for custom events
 */

public class LyncAttribution {
    
    // MARK: - Configuration
    
    public struct Config {
        let apiBaseURL: String
        let entityId: String
        let apiKey: String?
        let debug: Bool
        
        public init(apiBaseURL: String, entityId: String, apiKey: String? = nil, debug: Bool = false) {
            self.apiBaseURL = apiBaseURL
            self.entityId = entityId
            self.apiKey = apiKey
            self.debug = debug
        }
    }
    
    // MARK: - Event Types
    
    public enum EventType: String {
        case install = "install"
        case registration = "registration"
        case custom = "custom"
    }
    
    // MARK: - Device Info
    
    public struct DeviceInfo {
        let platform: String = "ios"
        let deviceModel: String
        let deviceName: String
        let osVersion: String
        let appVersion: String
        let bundleId: String
        let vendorId: String?
        let advertisingId: String?
        let timezone: String
        let language: String
        let screenWidth: Int
        let screenHeight: Int
        let deviceType: String
        
        static func current() -> DeviceInfo {
            let device = UIDevice.current
            let screen = UIScreen.main
            let mainBundle = Bundle.main
            
            return DeviceInfo(
                deviceModel: Self.getDeviceModel(),
                deviceName: device.name,
                osVersion: device.systemVersion,
                appVersion: mainBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0",
                bundleId: mainBundle.bundleIdentifier ?? "unknown",
                vendorId: device.identifierForVendor?.uuidString,
                advertisingId: Self.getAdvertisingId(),
                timezone: TimeZone.current.identifier,
                language: Locale.current.identifier,
                screenWidth: Int(screen.bounds.width * screen.scale),
                screenHeight: Int(screen.bounds.height * screen.scale),
                deviceType: device.userInterfaceIdiom == .pad ? "tablet" : "phone"
            )
        }
        
        private static func getDeviceModel() -> String {
            var systemInfo = utsname()
            uname(&systemInfo)
            let modelCode = withUnsafePointer(to: &systemInfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    ptr in String.init(validatingUTF8: ptr)
                }
            }
            return modelCode ?? "Unknown"
        }
        
        private static func getAdvertisingId() -> String? {
            if #available(iOS 14, *) {
                // iOS 14+ requires ATT permission
                guard ATTrackingManager.trackingAuthorizationStatus == .authorized else {
                    return nil
                }
            }
            
            guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
                return nil
            }
            
            let idfa = ASIdentifierManager.shared().advertisingIdentifier
            return idfa.uuidString != "00000000-0000-0000-0000-000000000000" ? idfa.uuidString : nil
        }
    }
    
    // MARK: - App Context
    
    public struct AppContext {
        let installTime: String?
        let sessionId: String
        let previousSessionCount: Int
        let timeSinceInstall: TimeInterval?
        let firstLaunch: Bool
        
        static func current() -> AppContext {
            let userDefaults = UserDefaults.standard
            let sessionId = UUID().uuidString
            
            // Track install time
            let installTimeKey = "lync_install_time"
            let installTime: Date
            if let savedInstallTime = userDefaults.object(forKey: installTimeKey) as? Date {
                installTime = savedInstallTime
            } else {
                installTime = Date()
                userDefaults.set(installTime, forKey: installTimeKey)
            }
            
            // Track session count
            let sessionCountKey = "lync_session_count"
            let previousSessionCount = userDefaults.integer(forKey: sessionCountKey)
            userDefaults.set(previousSessionCount + 1, forKey: sessionCountKey)
            
            // Check if this is first launch
            let firstLaunchKey = "lync_first_launch"
            let firstLaunch = !userDefaults.bool(forKey: firstLaunchKey)
            if firstLaunch {
                userDefaults.set(true, forKey: firstLaunchKey)
            }
            
            return AppContext(
                installTime: ISO8601DateFormatter().string(from: installTime),
                sessionId: sessionId,
                previousSessionCount: previousSessionCount,
                timeSinceInstall: Date().timeIntervalSince(installTime),
                firstLaunch: firstLaunch
            )
        }
    }
    
    // MARK: - Public Interface
    
    private let config: Config
    private let session: URLSession
    
    public init(config: Config) {
        self.config = config
        self.session = URLSession(configuration: .default)
        
        if config.debug {
            print("🚀 LyncAttribution initialized")
            print("📍 API URL: \(config.apiBaseURL)")
            print("🏢 Entity ID: \(config.entityId)")
        }
    }
    
    // MARK: - Attribution Storage
    
    private func getStoredClickId() -> String? {
        return UserDefaults.standard.string(forKey: "lync_click_id")
    }
    
    private func storeClickId(_ clickId: String) {
        UserDefaults.standard.set(clickId, forKey: "lync_click_id")
        if config.debug {
            print("💾 Stored click_id: \(clickId)")
        }
    }
    
    public func setClickId(_ clickId: String) {
        storeClickId(clickId)
    }
    
    // MARK: - Event Tracking
    
    public func trackInstall(
        clickId: String? = nil,
        customProperties: [String: Any]? = nil,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        // Store click_id if provided (e.g., from deep link)
        if let clickId = clickId {
            storeClickId(clickId)
        }
        
        trackEvent(
            type: .install,
            name: "App Install",
            clickId: clickId ?? getStoredClickId(),
            customProperties: customProperties,
            completion: completion
        )
    }
    
    public func trackRegistration(
        customerId: String,
        customerEmail: String? = nil,
        customerName: String? = nil,
        customProperties: [String: Any]? = nil,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        var properties = customProperties ?? [:]
        properties["customer_id"] = customerId
        if let email = customerEmail { properties["customer_email"] = email }
        if let name = customerName { properties["customer_name"] = name }
        
        trackEvent(
            type: .registration,
            name: "User Registration",
            customerId: customerId,
            customerEmail: customerEmail,
            customerName: customerName,
            customProperties: properties,
            completion: completion
        )
    }
    
    public func trackEvent(
        type: EventType,
        name: String,
        clickId: String? = nil,
        customerId: String? = nil,
        customerEmail: String? = nil,
        customerName: String? = nil,
        customProperties: [String: Any]? = nil,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        
        let deviceInfo = DeviceInfo.current()
        let appContext = AppContext.current()
        
        // Build payload
        var payload: [String: Any] = [
            "entity_id": config.entityId,
            "event_type": type.rawValue,
            "event_name": name,
            "device_info": [
                "platform": deviceInfo.platform,
                "device_model": deviceInfo.deviceModel,
                "device_name": deviceInfo.deviceName,
                "os_version": deviceInfo.osVersion,
                "app_version": deviceInfo.appVersion,
                "bundle_id": deviceInfo.bundleId,
                "vendor_id": deviceInfo.vendorId as Any,
                "advertising_id": deviceInfo.advertisingId as Any,
                "timezone": deviceInfo.timezone,
                "language": deviceInfo.language,
                "screen_width": deviceInfo.screenWidth,
                "screen_height": deviceInfo.screenHeight,
                "device_type": deviceInfo.deviceType
            ],
            "app_context": [
                "install_time": appContext.installTime as Any,
                "session_id": appContext.sessionId,
                "previous_session_count": appContext.previousSessionCount,
                "time_since_install": appContext.timeSinceInstall as Any,
                "first_launch": appContext.firstLaunch
            ],
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "client_timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Add optional attribution data
        if let clickId = clickId ?? getStoredClickId() {
            payload["click_id"] = clickId
        }
        
        if let customerId = customerId {
            payload["customer_id"] = customerId
        }
        
        if let customerEmail = customerEmail {
            payload["customer_email"] = customerEmail
        }
        
        if let customerName = customerName {
            payload["customer_name"] = customerName
        }
        
        if let customProperties = customProperties {
            payload["custom_properties"] = customProperties
        }
        
        // Send to API
        sendEvent(payload: payload) { result in
            switch result {
            case .success:
                if self.config.debug {
                    print("✅ Event tracked: \(type.rawValue) - \(name)")
                }
            case .failure(let error):
                if self.config.debug {
                    print("❌ Event tracking failed: \(error)")
                }
            }
            completion(result)
        }
    }
    
    // MARK: - Network
    
    private func sendEvent(payload: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(config.apiBaseURL)/api/track/mobile") else {
            completion(.failure(LyncAttributionError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("LyncAttribution-iOS/1.0.0", forHTTPHeaderField: "User-Agent")
        
        // Add API key if provided
        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData
            
            if config.debug {
                print("📤 Sending event to: \(url)")
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("📦 Payload: \(jsonString)")
                }
            }
            
            session.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        completion(.failure(LyncAttributionError.invalidResponse))
                        return
                    }
                    
                    if self.config.debug {
                        print("📥 Response status: \(httpResponse.statusCode)")
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            print("📦 Response: \(responseString)")
                        }
                    }
                    
                    if 200...299 ~= httpResponse.statusCode {
                        completion(.success(()))
                    } else {
                        let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                        completion(.failure(LyncAttributionError.apiError(httpResponse.statusCode, errorMessage)))
                    }
                }
            }.resume()
            
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: - Errors

public enum LyncAttributionError: Error {
    case invalidURL
    case invalidResponse
    case apiError(Int, String)
    
    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code, let message):
            return "API Error \(code): \(message)"
        }
    }
}

// MARK: - Deep Link Handling Helper

public extension LyncAttribution {
    
    /**
     * Extract click_id from deep link URL
     * Call this from your AppDelegate or SceneDelegate when handling deep links
     */
    static func extractClickId(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        // Look for click_id parameter in the URL
        return queryItems.first { $0.name == "click_id" }?.value
    }
} 