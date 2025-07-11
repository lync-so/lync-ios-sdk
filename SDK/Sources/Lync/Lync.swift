import Foundation
import UIKit

/// Super lean Lync SDK for attribution tracking
@objc public class Lync: NSObject {
    
    // MARK: - Properties
    
    /// Shared instance - the only way to access Lync
    @objc public static let shared = Lync()
    
    /// Configuration
    private var apiKey: String?
    private var baseURL: String?
    private var debug: Bool = false
    
    /// Device info cache
    private var deviceInfo: DeviceInfo?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    /// Initialize Lync with just your API key
    /// - Parameters:
    ///   - apiKey: Your Lync API key
    ///   - baseURL: Optional base URL (defaults to https://api.lync.so)
    ///   - debug: Enable debug logging
    @objc public func initialize(apiKey: String, baseURL: String = "https://api.lync.so", debug: Bool = false) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.debug = debug
        self.deviceInfo = DeviceInfo.current()
        
        if debug {
            print("🔗 Lync initialized with API key: \(apiKey.prefix(8))...")
        }
    }
    
    // MARK: - Super Simple Tracking
    
    /// Track any event with optional properties
    /// - Parameters:
    ///   - event: Event name (e.g., "install", "registration", "button_click")
    ///   - properties: Optional event properties
    ///   - userId: Optional user ID
    ///   - userEmail: Optional user email
    @objc public func track(
        _ event: String,
        properties: [String: Any]? = nil,
        userId: String? = nil,
        userEmail: String? = nil
    ) {
        guard let apiKey = apiKey, let baseURL = baseURL else {
            print("❌ Lync not initialized. Call Lync.shared.initialize() first.")
            return
        }
        
        guard let deviceInfo = deviceInfo else {
            print("❌ Device info not available")
            return
        }
        
        // Build simple payload
        var payload: [String: Any] = [
            "event": event,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "device": deviceInfo.toDictionary()
        ]
        
        // Add optional data
        if let properties = properties {
            payload["properties"] = properties
        }
        
        if let userId = userId {
            payload["user_id"] = userId
        }
        
        if let userEmail = userEmail {
            payload["user_email"] = userEmail
        }
        
        // Send it
        sendEvent(payload: payload, apiKey: apiKey, baseURL: baseURL)
    }
    
    /// Track app install
    @objc public func trackInstall(userId: String? = nil, userEmail: String? = nil) {
        track("install", userId: userId, userEmail: userEmail)
    }
    
    /// Track user registration
    @objc public func trackRegistration(userId: String? = nil, userEmail: String? = nil) {
        track("registration", userId: userId, userEmail: userEmail)
    }
    
    /// Track custom event with properties
    @objc public func trackEvent(_ event: String, properties: [String: Any]? = nil) {
        track(event, properties: properties)
    }
    
    // MARK: - Private Methods
    
    /// Send event to API
    private func sendEvent(payload: [String: Any], apiKey: String, baseURL: String) {
        guard let url = URL(string: "\(baseURL)/api/track/mobile") else {
            print("❌ Invalid API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("❌ Failed to serialize payload: \(error)")
            return
        }
        
        if debug {
            print("🔗 Tracking: \(payload["event"] ?? "unknown")")
            if let properties = payload["properties"] {
                print("🔗 Properties: \(properties)")
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if self.debug {
                            print("✅ Event tracked successfully")
                        }
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
}

// MARK: - Usage Examples

/*
 
 // Initialize once in your app
 Lync.shared.initialize(apiKey: "sk_live_your_api_key", debug: true)
 
 // Track events anywhere
 Lync.shared.track("app_opened")
 Lync.shared.track("button_clicked", properties: ["button": "sign_up"])
 Lync.shared.track("purchase", properties: ["amount": 29.99, "currency": "USD"])
 
 // Or use convenience methods
 Lync.shared.trackInstall(userId: "user123", userEmail: "user@example.com")
 Lync.shared.trackRegistration(userId: "user123", userEmail: "user@example.com")
 Lync.shared.trackEvent("custom_event", properties: ["key": "value"])
 
 */ 