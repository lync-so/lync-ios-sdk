import Foundation

/// Configuration for the Lync SDK
@objc public class Config: NSObject {
    /// API key for authentication (from backend)
    @objc public let apiKey: String
    /// Base URL for the API
    @objc public let baseURL: URL
    /// Debug mode flag
    @objc public let debug: Bool

    /// Initialize configuration with API key
    /// - Parameters:
    ///   - apiKey: API key for authentication
    ///   - baseURL: Base URL for the API
    ///   - debug: Enable debug logging (default: false)
    @objc public init(
        apiKey: String,
        baseURL: URL,
        debug: Bool = false
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.debug = debug
        super.init()
    }
} 