import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency
import AVFoundation

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
    
    // MARK: - Shared Instance
    
    private static var _shared: LyncAttribution?
    
    /// Shared instance of LyncAttribution (must be configured first)
    public static var shared: LyncAttribution {
        guard let shared = _shared else {
            fatalError("❌ LyncAttribution.shared not configured. Call LyncAttribution.configure() first.")
        }
        return shared
    }
    
    /// Configure the shared instance from Info.plist
    public static func configure() {
        _shared = LyncAttribution()
    }
    
    /// Configure the shared instance with custom config
    public static func configure(config: Config) {
        _shared = LyncAttribution(config: config)
    }
    
    /// Configure the shared instance with parameters
    public static func configure(
        apiBaseURL: String,
        entityId: String,
        apiKey: String,
        debug: Bool = false
    ) {
        let config = Config(
            apiBaseURL: apiBaseURL,
            entityId: entityId,
            apiKey: apiKey,
            debug: debug
        )
        _shared = LyncAttribution(config: config)
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
        
        // Enhanced device fingerprinting
        let screenScale: Double
        let screenBrightness: Double
        let batteryLevel: Float?
        let batteryState: String
        let diskSpace: (total: Int64, free: Int64)?
        let memoryUsage: (total: Int64, used: Int64)?
        let processorCount: Int
        let systemUptime: TimeInterval
        let preferredLanguages: [String]
        let regionCode: String?
        let currencyCode: String?
        let calendarIdentifier: String
        let deviceOrientation: String
        let interfaceOrientation: String
        let userInterfaceIdiom: String
        
        // Network information
        let networkType: String
        let carrierName: String?
        let carrierCountryCode: String?
        let mobileNetworkCode: String?
        let mobileCountryCode: String?
        
        // Accessibility & Capabilities
        let isVoiceOverRunning: Bool
        let isClosedCaptioningEnabled: Bool
        let isReduceMotionEnabled: Bool
        let preferredContentSizeCategory: String
        
        // Jailbreak detection indicators
        let isJailbroken: Bool
        let suspiciousPaths: [String]
        
        // Fingerprints
        let screenFingerprint: String
        let audioFingerprint: String
        let webCompatibleFingerprint: String
        
        static func current() -> DeviceInfo {
            let device = UIDevice.current
            let screen = UIScreen.main
            let mainBundle = Bundle.main
            let processInfo = ProcessInfo.processInfo
            let locale = Locale.current
            
            // Enable battery monitoring for accurate readings
            device.isBatteryMonitoringEnabled = true
            
            return DeviceInfo(
                deviceModel: Self.getDeviceModel(),
                deviceName: device.name,
                osVersion: device.systemVersion,
                appVersion: mainBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0",
                bundleId: mainBundle.bundleIdentifier ?? "unknown",
                vendorId: device.identifierForVendor?.uuidString,
                advertisingId: Self.getAdvertisingId(),
                timezone: TimeZone.current.identifier,
                language: locale.identifier,
                screenWidth: Int(screen.bounds.width * screen.scale),
                screenHeight: Int(screen.bounds.height * screen.scale),
                deviceType: device.userInterfaceIdiom == .pad ? "tablet" : "phone",
                
                // Enhanced fingerprinting
                screenScale: Double(screen.scale),
                screenBrightness: Double(screen.brightness),
                batteryLevel: device.batteryLevel >= 0 ? device.batteryLevel : nil,
                batteryState: Self.getBatteryState(device.batteryState),
                diskSpace: Self.getDiskSpace(),
                memoryUsage: Self.getMemoryUsage(),
                processorCount: processInfo.processorCount,
                systemUptime: processInfo.systemUptime,
                preferredLanguages: locale.preferredLanguages,
                regionCode: locale.regionCode,
                currencyCode: locale.currencyCode,
                calendarIdentifier: locale.calendar.identifier,
                deviceOrientation: Self.getDeviceOrientation(device.orientation),
                interfaceOrientation: Self.getInterfaceOrientation(),
                userInterfaceIdiom: Self.getUserInterfaceIdiom(device.userInterfaceIdiom),
                
                // Network information
                networkType: Self.getNetworkType(),
                carrierName: Self.getCarrierInfo().name,
                carrierCountryCode: Self.getCarrierInfo().countryCode,
                mobileNetworkCode: Self.getCarrierInfo().mobileNetworkCode,
                mobileCountryCode: Self.getCarrierInfo().mobileCountryCode,
                
                // Accessibility
                isVoiceOverRunning: UIAccessibility.isVoiceOverRunning,
                isClosedCaptioningEnabled: UIAccessibility.isClosedCaptioningEnabled,
                isReduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
                preferredContentSizeCategory: UIApplication.shared.preferredContentSizeCategory.rawValue,
                
                // Security
                isJailbroken: Self.detectJailbreak().isJailbroken,
                suspiciousPaths: Self.detectJailbreak().suspiciousPaths,
                
                // Fingerprints
                screenFingerprint: Self.generateScreenFingerprint(),
                audioFingerprint: Self.generateAudioFingerprint(),
                webCompatibleFingerprint: Self.generateWebCompatibleFingerprint()
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
        
        private static func getBatteryState(_ state: UIDevice.BatteryState) -> String {
            switch state {
            case .unknown: return "unknown"
            case .unplugged: return "unplugged"
            case .charging: return "charging"
            case .full: return "full"
            @unknown default: return "unknown"
            }
        }
        
        private static func getDiskSpace() -> (total: Int64, free: Int64)? {
            guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
                return nil
            }
            
            do {
                let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
                let total = attributes[.systemSize] as? Int64 ?? 0
                let free = attributes[.systemFreeSize] as? Int64 ?? 0
                return (total: total, free: free)
            } catch {
                return nil
            }
        }
        
        private static func getMemoryUsage() -> (total: Int64, used: Int64)? {
            var info = mach_task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
            
            let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    task_info(mach_task_self_,
                             task_flavor_t(MACH_TASK_BASIC_INFO),
                             $0,
                             &count)
                }
            }
            
            guard result == KERN_SUCCESS else { return nil }
            
            let total = Int64(ProcessInfo.processInfo.physicalMemory)
            let used = Int64(info.resident_size)
            
            return (total: total, used: used)
        }
        
        private static func getDeviceOrientation(_ orientation: UIDeviceOrientation) -> String {
            switch orientation {
            case .portrait: return "portrait"
            case .portraitUpsideDown: return "portrait-upside-down"
            case .landscapeLeft: return "landscape-left"
            case .landscapeRight: return "landscape-right"
            case .faceUp: return "face-up"
            case .faceDown: return "face-down"
            case .unknown: return "unknown"
            @unknown default: return "unknown"
            }
        }
        
        private static func getInterfaceOrientation() -> String {
            if #available(iOS 13.0, *) {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    return "unknown"
                }
                
                switch windowScene.interfaceOrientation {
                case .portrait: return "portrait"
                case .portraitUpsideDown: return "portrait-upside-down"
                case .landscapeLeft: return "landscape-left"
                case .landscapeRight: return "landscape-right"
                case .unknown: return "unknown"
                @unknown default: return "unknown"
                }
            } else {
                let orientation = UIApplication.shared.statusBarOrientation
                switch orientation {
                case .portrait: return "portrait"
                case .portraitUpsideDown: return "portrait-upside-down"
                case .landscapeLeft: return "landscape-left"
                case .landscapeRight: return "landscape-right"
                case .unknown: return "unknown"
                @unknown default: return "unknown"
                }
            }
        }
        
        private static func getUserInterfaceIdiom(_ idiom: UIUserInterfaceIdiom) -> String {
            switch idiom {
            case .phone: return "phone"
            case .pad: return "pad"
            case .tv: return "tv"
            case .carPlay: return "carPlay"
            case .mac: return "mac"
            case .unspecified: return "unspecified"
            @unknown default: return "unknown"
            }
        }
        
        private static func getNetworkType() -> String {
            // Simple network type detection
            return "wifi" // Default assumption - could enhance with Reachability
        }
        
        private static func getCarrierInfo() -> (name: String?, countryCode: String?, mobileNetworkCode: String?, mobileCountryCode: String?) {
            // Return placeholder values for now
            return (name: "unknown", countryCode: "unknown", mobileNetworkCode: "unknown", mobileCountryCode: "unknown")
        }
        
        private static func generateScreenFingerprint() -> String {
            let screen = UIScreen.main
            let device = UIDevice.current
            
            // Collect screen characteristics
            let screenData = [
                "resolution": "\(Int(screen.bounds.width * screen.scale))x\(Int(screen.bounds.height * screen.scale))",
                "scale": "\(screen.scale)",
                "nativeScale": "\(screen.nativeScale)",
                "brightness": "\(screen.brightness)",
                "maxFPS": "\(screen.maximumFramesPerSecond)",
                "idiom": device.userInterfaceIdiom == .pad ? "pad" : "phone"
            ]
            
            // Enhanced characteristics
            var enhanced: [String: String] = [:]
            
            if #available(iOS 11.0, *) {
                let safeArea = UIApplication.shared.windows.first?.safeAreaInsets ?? .zero
                enhanced["safeArea"] = "\(safeArea.top),\(safeArea.bottom),\(safeArea.left),\(safeArea.right)"
                enhanced["hasNotch"] = safeArea.top > 20 ? "true" : "false"
            }
            
            if #available(iOS 13.0, *) {
                enhanced["latency"] = "\(screen.calibratedLatency)"
                switch screen.traitCollection.displayGamut {
                case .P3: enhanced["colorSpace"] = "P3"
                case .SRGB: enhanced["colorSpace"] = "sRGB"
                default: enhanced["colorSpace"] = "unknown"
                }
            }
            
            // Combine all data
            let allData = screenData.merging(enhanced) { (current, _) in current }
            let sortedKeys = allData.keys.sorted()
            let fingerprint = sortedKeys.map { "\($0):\(allData[$0] ?? "")" }.joined(separator: "|")
            
            return fingerprint
        }
        
        private static func generateAudioFingerprint() -> String {
            let audioSession = AVAudioSession.sharedInstance()
            
            var audioData: [String: String] = [
                "category": audioSession.category.rawValue,
                "sampleRate": "\(audioSession.sampleRate)",
                "inputChannels": "\(audioSession.inputNumberOfChannels)",
                "outputChannels": "\(audioSession.outputNumberOfChannels)",
                "inputLatency": "\(audioSession.inputLatency)",
                "outputLatency": "\(audioSession.outputLatency)",
                "preferredSampleRate": "\(audioSession.preferredSampleRate)",
                "preferredBufferDuration": "\(audioSession.preferredIOBufferDuration)"
            ]
            
            // Get current route info
            let route = audioSession.currentRoute
            let outputs = route.outputs.map { "\($0.portType.rawValue):\($0.portName)" }.joined(separator: ",")
            let inputs = route.inputs.map { "\($0.portType.rawValue):\($0.portName)" }.joined(separator: ",")
            
            audioData["outputs"] = outputs.isEmpty ? "none" : outputs
            audioData["inputs"] = inputs.isEmpty ? "none" : inputs
            
            // Check for specific hardware
            let hasHeadphones = route.outputs.contains { $0.portType == .headphones }
            let hasBluetooth = route.outputs.contains { 
                $0.portType == .bluetoothA2DP || $0.portType == .bluetoothHFP || $0.portType == .bluetoothLE
            }
            let hasBuiltIn = route.outputs.contains { $0.portType == .builtInSpeaker }
            
            audioData["hasHeadphones"] = hasHeadphones ? "true" : "false"
            audioData["hasBluetooth"] = hasBluetooth ? "true" : "false"
            audioData["hasBuiltIn"] = hasBuiltIn ? "true" : "false"
            
            // Create fingerprint
            let sortedKeys = audioData.keys.sorted()
            let fingerprint = sortedKeys.map { "\($0):\(audioData[$0] ?? "")" }.joined(separator: "|")
            
            return fingerprint
        }
        
        private static func generateWebCompatibleFingerprint() -> String {
            let screen = UIScreen.main
            let device = UIDevice.current
            let locale = Locale.current
            
            // Characteristics that both web and iOS can consistently measure
            let webCompatibleData = [
                // Screen (both web and iOS can detect)
                "screen": "\(Int(screen.bounds.width * screen.scale))x\(Int(screen.bounds.height * screen.scale))",
                "scale": String(format: "%.1f", screen.scale),
                
                // Device info (web gets from user agent, iOS gets directly)
                "platform": "iOS",
                "device": device.userInterfaceIdiom == .pad ? "tablet" : "phone",
                "model": Self.getDeviceModel().prefix(8).description, // Simplified model
                
                // Locale info (both have access)
                "tz": TimeZone.current.identifier.replacingOccurrences(of: "/", with: "_"),
                "lang": locale.languageCode ?? "en",
                "region": locale.regionCode ?? "US",
                
                // OS version (web can detect from user agent)
                "os": device.systemVersion.replacingOccurrences(of: ".", with: "_")
            ]
            
            // Create consistent fingerprint format (matches web format)
            let sortedKeys = webCompatibleData.keys.sorted()
            let fingerprint = sortedKeys.map { "\($0):\(webCompatibleData[$0] ?? "")" }.joined(separator: ";")
            
            return fingerprint
        }

        private static func detectJailbreak() -> (isJailbroken: Bool, suspiciousPaths: [String]) {
            let suspiciousPaths = [
                "/Applications/Cydia.app",
                "/Library/MobileSubstrate/MobileSubstrate.dylib",
                "/bin/bash",
                "/usr/sbin/sshd",
                "/etc/apt",
                "/private/var/lib/apt/",
                "/private/var/lib/cydia",
                "/private/var/mobile/Library/SBSettings/Themes",
                "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
                "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
                "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
                "/var/cache/apt",
                "/var/lib/apt",
                "/var/lib/cydia",
                "/usr/bin/sshd",
                "/usr/libexec/sftp-server",
                "/usr/sbin/sshd",
                "/etc/ssh/sshd_config",
                "/private/var/tmp/cydia.log"
            ]
            
            var foundPaths: [String] = []
            var isJailbroken = false
            
            for path in suspiciousPaths {
                if FileManager.default.fileExists(atPath: path) {
                    foundPaths.append(path)
                    isJailbroken = true
                }
            }
            
            // Additional jailbreak detection methods
            if !isJailbroken {
                // Check if we can write to system directories
                do {
                    try "test".write(toFile: "/private/jailbreak.txt", atomically: true, encoding: .utf8)
                    try FileManager.default.removeItem(atPath: "/private/jailbreak.txt")
                    isJailbroken = true
                    foundPaths.append("/private/write-test")
                } catch {
                    // Normal behavior - we can't write to system directories
                }
            }
            
            return (isJailbroken: isJailbroken, suspiciousPaths: foundPaths)
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
    
    // MARK: - Convenience Initializer from Plist
    
    /// Initialize LyncAttribution from Info.plist configuration
    /// Expects these keys in Info.plist:
    /// - LyncAttributionAPIBaseURL (String)
    /// - LyncAttributionEntityID (String)
    /// - LyncAttributionAPIKey (String)
    /// - LyncAttributionDebug (Bool, optional)
    public convenience init() {
        guard let infoDictionary = Bundle.main.infoDictionary else {
            fatalError("❌ LyncAttribution: Info.plist not found")
        }
        
        guard let apiBaseURL = infoDictionary["LyncAttributionAPIBaseURL"] as? String else {
            fatalError("❌ LyncAttribution: Missing LyncAttributionAPIBaseURL in Info.plist")
        }
        
        guard let entityId = infoDictionary["LyncAttributionEntityID"] as? String else {
            fatalError("❌ LyncAttribution: Missing LyncAttributionEntityID in Info.plist")
        }
        
        guard let apiKey = infoDictionary["LyncAttributionAPIKey"] as? String else {
            fatalError("❌ LyncAttribution: Missing LyncAttributionAPIKey in Info.plist")
        }
        
        let debug = infoDictionary["LyncAttributionDebug"] as? Bool ?? false
        
        let config = Config(
            apiBaseURL: apiBaseURL,
            entityId: entityId,
            apiKey: apiKey,
            debug: debug
        )
        
        self.init(config: config)
        
        if debug {
            print("📋 LyncAttribution loaded from Info.plist")
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
        
        // Build comprehensive payload with enhanced device fingerprinting
        var payload: [String: Any] = [
            "entity_id": config.entityId,
            "event_type": type.rawValue,
            "event_name": name,
            "device_info": [
                // Basic device info
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
                "device_type": deviceInfo.deviceType,
                
                // Enhanced device fingerprinting
                "screen_scale": deviceInfo.screenScale,
                "screen_brightness": deviceInfo.screenBrightness,
                "battery_level": deviceInfo.batteryLevel as Any,
                "battery_state": deviceInfo.batteryState,
                "processor_count": deviceInfo.processorCount,
                "system_uptime": deviceInfo.systemUptime,
                "preferred_languages": deviceInfo.preferredLanguages,
                "region_code": deviceInfo.regionCode as Any,
                "currency_code": deviceInfo.currencyCode as Any,
                "calendar_identifier": deviceInfo.calendarIdentifier,
                "device_orientation": deviceInfo.deviceOrientation,
                "interface_orientation": deviceInfo.interfaceOrientation,
                "user_interface_idiom": deviceInfo.userInterfaceIdiom,
                
                // Storage & Memory
                "disk_total": deviceInfo.diskSpace?.total as Any,
                "disk_free": deviceInfo.diskSpace?.free as Any,
                "memory_total": deviceInfo.memoryUsage?.total as Any,
                "memory_used": deviceInfo.memoryUsage?.used as Any,
                
                // Network information
                "network_type": deviceInfo.networkType,
                "carrier_name": deviceInfo.carrierName as Any,
                "carrier_country_code": deviceInfo.carrierCountryCode as Any,
                "mobile_network_code": deviceInfo.mobileNetworkCode as Any,
                "mobile_country_code": deviceInfo.mobileCountryCode as Any,
                
                // Accessibility & Capabilities
                "is_voice_over_running": deviceInfo.isVoiceOverRunning,
                "is_closed_captioning_enabled": deviceInfo.isClosedCaptioningEnabled,
                "is_reduce_motion_enabled": deviceInfo.isReduceMotionEnabled,
                "preferred_content_size_category": deviceInfo.preferredContentSizeCategory,
                
                // Security indicators
                "is_jailbroken": deviceInfo.isJailbroken,
                "suspicious_paths": deviceInfo.suspiciousPaths,
                
                // Fingerprints
                "screen_fingerprint": deviceInfo.screenFingerprint,
                "audio_fingerprint": deviceInfo.audioFingerprint,
                "web_compatible_fingerprint": deviceInfo.webCompatibleFingerprint
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

// MARK: - Static Convenience Methods

extension LyncAttribution {
    
    /// Track app install using shared instance
    public static func trackInstall(
        clickId: String? = nil,
        customProperties: [String: Any]? = nil,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        shared.trackInstall(
            clickId: clickId,
            customProperties: customProperties,
            completion: completion
        )
    }
    
    /// Track user registration using shared instance
    public static func trackRegistration(
        customerId: String,
        customerEmail: String? = nil,
        customerName: String? = nil,
        customProperties: [String: Any]? = nil,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        shared.trackRegistration(
            customerId: customerId,
            customerEmail: customerEmail,
            customerName: customerName,
            customProperties: customProperties,
            completion: completion
        )
    }
    
    /// Track custom event using shared instance
    public static func trackEvent(
        type: EventType,
        name: String,
        clickId: String? = nil,
        customerId: String? = nil,
        customerEmail: String? = nil,
        customerName: String? = nil,
        customProperties: [String: Any]? = nil,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        shared.trackEvent(
            type: type,
            name: name,
            clickId: clickId,
            customerId: customerId,
            customerEmail: customerEmail,
            customerName: customerName,
            customProperties: customProperties,
            completion: completion
        )
    }
    
    /// Set click ID for attribution using shared instance
    public static func setClickId(_ clickId: String) {
        shared.setClickId(clickId)
    }
    
    /// Handle deep link for attribution using shared instance
    public static func handleDeepLink(_ url: URL) -> Bool {
        shared.handleDeepLink(url)
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