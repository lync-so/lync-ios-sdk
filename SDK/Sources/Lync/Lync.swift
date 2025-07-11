import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency
import Network

/// Main Lync SDK class for tracking app installs, registrations, and custom events
@objc public class Lync: NSObject {
    
    // MARK: - Properties
    
    /// Shared instance for singleton access
    @objc public static let shared = Lync()
    
    /// Configuration for the SDK
    private var config: Config?
    
    /// Device information cache
    private var deviceInfo: DeviceInfo?
    
    /// App context information
    private var appContext: AppContext?
    
    /// Stored click_id and lync_id from initialization
    private var clickId: String?
    private var lyncId: String?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    /// Initialize the Lync SDK with configuration
    /// - Parameter config: Configuration object containing API key and base URL
    @objc public func configure(with config: Config) {
        self.config = config
        self.deviceInfo = DeviceInfo()
        self.appContext = AppContext()
        
        // Extract click_id and lync_id from config if present
        if let url = config.baseURL {
            self.clickId = extractClickId(from: url)
            self.lyncId = extractLyncId(from: url)
        }
        
        #if DEBUG
        print("🔗 Lync SDK initialized with base URL: \(config.baseURL.absoluteString)")
        print("🔗 Click ID: \(clickId ?? "nil")")
        print("🔗 Lync ID: \(lyncId ?? "nil")")
        #endif
    }
    
    // MARK: - Public Tracking Methods
    
    /// Track an app install event
    @objc public func trackInstall(
        customerExternalId: String? = nil,
        customerEmail: String? = nil,
        customerAvatarUrl: String? = nil,
        customerName: String? = nil
    ) {
        trackEvent(
            type: .install,
            customerExternalId: customerExternalId,
            customerEmail: customerEmail,
            customerAvatarUrl: customerAvatarUrl,
            customerName: customerName
        )
    }
    
    /// Track a registration event
    @objc public func trackRegistration(
        customerExternalId: String? = nil,
        customerEmail: String? = nil,
        customerAvatarUrl: String? = nil,
        customerName: String? = nil
    ) {
        trackEvent(
            type: .registration,
            customerExternalId: customerExternalId,
            customerEmail: customerEmail,
            customerAvatarUrl: customerAvatarUrl,
            customerName: customerName
        )
    }
    
    /// Track a custom event
    @objc public func trackCustomEvent(
        _ eventName: String,
        properties: [String: Any]? = nil,
        customerExternalId: String? = nil,
        customerEmail: String? = nil,
        customerAvatarUrl: String? = nil,
        customerName: String? = nil
    ) {
        trackEvent(
            type: .custom(eventName),
            properties: properties,
            customerExternalId: customerExternalId,
            customerEmail: customerEmail,
            customerAvatarUrl: customerAvatarUrl,
            customerName: customerName
        )
    }
    
    // MARK: - Private Methods
    
    /// Track an event with the specified type and parameters
    private func trackEvent(
        type: EventType,
        properties: [String: Any]? = nil,
        customerExternalId: String? = nil,
        customerEmail: String? = nil,
        customerAvatarUrl: String? = nil,
        customerName: String? = nil
    ) {
        guard let config = config else {
            print("❌ Lync SDK not configured. Call configure() first.")
            return
        }
        
        guard let deviceInfo = deviceInfo,
              let appContext = appContext else {
            print("❌ Device or app context not available")
            return
        }
        
        // Build the payload
        var payload: [String: Any] = [
            "event_type": type.rawValue,
            "event_name": type.rawValue == "custom" ? eventName : type.rawValue, // Add event_name
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "device_info": deviceInfo.toDictionary(),
            "app_context": appContext.toDictionary()
        ]
        
        // Add optional parameters if provided
        if let clickId = clickId {
            payload["click_id"] = clickId
        }
        
        if let lyncId = lyncId {
            payload["lync_id"] = lyncId
        }
        
        // Change customer field names
        if let customerExternalId = customerExternalId {
            payload["customer_id"] = customerExternalId // Changed from customer_external_id
        }
        
        if let customerEmail = customerEmail {
            payload["customer_email"] = customerEmail
        }
        
        if let customerAvatarUrl = customerAvatarUrl {
            payload["customer_avatar_url"] = customerAvatarUrl
        }
        
        if let customerName = customerName {
            payload["customer_name"] = customerName
        }
        
        // Add custom properties for custom events
        if case .custom = type, let properties = properties {
            payload["properties"] = properties
        }
        
        // Send the event
        sendEvent(payload: payload, config: config)
    }
    
    /// Send event to the API
    private func sendEvent(payload: [String: Any], config: Config) {
        guard let url = URL(string: "\(config.baseURL.absoluteString)/api/track/mobile") else {
            print("❌ Invalid API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("❌ Failed to serialize payload: \(error)")
            return
        }
        
        #if DEBUG
        print("🔗 Sending event to: \(url)")
        print("🔗 Payload: \(payload)")
        #endif
        
        URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                    print("❌ Network error: \(error)")
                        return
                    }
                    
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        #if DEBUG
                        print("✅ Event sent successfully")
                        #endif
                    } else {
                        print("❌ API error: \(httpResponse.statusCode)")
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            print("❌ Response: \(responseString)")
                        }
                    }
                    }
                }
            }.resume()
    }
    
    /// Extract click_id from URL parameters
    private func extractClickId(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let clickId = components.queryItems?.first(where: { $0.name == "click_id" })?.value else {
            return nil
        }
        return clickId
    }
    
    /// Extract lync_id from URL parameters
    private func extractLyncId(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let lyncId = components.queryItems?.first(where: { $0.name == "lync_id" })?.value else {
            return nil
        }
        return lyncId
    }
}

// MARK: - Usage Examples

/*

// Basic setup with API key
let config = Config(
    apiKey: "your-api-key",
    baseURL: URL(string: "https://your-domain.com")!
)
Lync.shared.configure(with: config)

// Track app install
Lync.shared.trackInstall()

// Track registration with customer info
Lync.shared.trackRegistration(
    customerExternalId: "user123",
    customerEmail: "user@example.com",
    customerName: "John Doe"
)

// Track custom event
Lync.shared.trackCustomEvent(
    "purchase_completed",
    properties: ["amount": 99.99, "currency": "USD"],
    customerExternalId: "user123"
)

*/ 