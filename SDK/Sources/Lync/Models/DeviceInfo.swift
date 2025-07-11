import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency
import Darwin

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
    

    
    // Fingerprints
    let screenFingerprint: String
    let audioFingerprint: String
    let webCompatibleFingerprint: String
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "platform": platform,
            "device_model": deviceModel,
            "device_name": deviceName,
            "os_version": osVersion,
            "app_version": appVersion,
            "bundle_id": bundleId,
            "vendor_id": vendorId as Any,
            "advertising_id": advertisingId as Any,
            "timezone": timezone,
            "language": language,
            "screen_width": screenWidth,
            "screen_height": screenHeight,
            "device_type": deviceType,
            
            // Enhanced device fingerprinting
            "screen_scale": screenScale,
            "screen_brightness": screenBrightness,
            "battery_level": batteryLevel as Any,
            "battery_state": batteryState,
            "processor_count": processorCount,
            "system_uptime": systemUptime,
            "preferred_languages": preferredLanguages,
            "region_code": regionCode as Any,
            "currency_code": currencyCode as Any,
            "calendar_identifier": calendarIdentifier,
            "device_orientation": deviceOrientation,
            "interface_orientation": interfaceOrientation,
            "user_interface_idiom": userInterfaceIdiom,
            
            // Storage & Memory
            "disk_total": diskSpace?.total as Any,
            "disk_free": diskSpace?.free as Any,
            "memory_total": memoryUsage?.total as Any,
            "memory_used": memoryUsage?.used as Any,
            
            // Network information
            "network_type": networkType,
            "carrier_name": carrierName as Any,
            "carrier_country_code": carrierCountryCode as Any,
            "mobile_network_code": mobileNetworkCode as Any,
            "mobile_country_code": mobileCountryCode as Any,
            
            // Accessibility & Capabilities
            "is_voice_over_running": isVoiceOverRunning,
            "is_closed_captioning_enabled": isClosedCaptioningEnabled,
            "is_reduce_motion_enabled": isReduceMotionEnabled,
            "preferred_content_size_category": preferredContentSizeCategory,
            
            // Fingerprints
            "screen_fingerprint": screenFingerprint,
            "audio_fingerprint": audioFingerprint,
            "web_compatible_fingerprint": webCompatibleFingerprint
        ]
        
        return dict
    }
    
    static func current() -> DeviceInfo {
        let device = UIDevice.current
        let screen = UIScreen.main
        let mainBundle = Bundle.main
        let processInfo = ProcessInfo.processInfo
        let locale = Locale.current
        
        // Enable battery monitoring for accurate readings
        device.isBatteryMonitoringEnabled = true
        
        return DeviceInfo(
            deviceModel: DeviceUtils.getDeviceModel(),
            deviceName: device.name,
            osVersion: device.systemVersion,
            appVersion: mainBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0",
            bundleId: mainBundle.bundleIdentifier ?? "unknown",
            vendorId: device.identifierForVendor?.uuidString,
            advertisingId: DeviceUtils.getAdvertisingId(),
            timezone: TimeZone.current.identifier,
            language: locale.identifier,
            screenWidth: Int(screen.bounds.width * screen.scale),
            screenHeight: Int(screen.bounds.height * screen.scale),
            deviceType: device.userInterfaceIdiom == .pad ? "tablet" : "phone",
            
            // Enhanced fingerprinting
            screenScale: Double(screen.scale),
            screenBrightness: Double(screen.brightness),
            batteryLevel: device.batteryLevel >= 0 ? device.batteryLevel : nil,
            batteryState: DeviceUtils.getBatteryState(device.batteryState),
            diskSpace: DeviceUtils.getDiskSpace(),
            memoryUsage: DeviceUtils.getMemoryUsage(),
            processorCount: processInfo.processorCount,
            systemUptime: processInfo.systemUptime,
            preferredLanguages: Locale.preferredLanguages,
            regionCode: locale.regionCode,
            currencyCode: locale.currencyCode,
            calendarIdentifier: String(describing: locale.calendar.identifier),
            deviceOrientation: DeviceUtils.getDeviceOrientation(device.orientation),
            interfaceOrientation: DeviceUtils.getInterfaceOrientation(),
            userInterfaceIdiom: DeviceUtils.getUserInterfaceIdiom(device.userInterfaceIdiom),
            
            // Network information
            networkType: "unknown",
            carrierName: nil,
            carrierCountryCode: nil,
            mobileNetworkCode: nil,
            mobileCountryCode: nil,
            
            // Accessibility
            isVoiceOverRunning: UIAccessibility.isVoiceOverRunning,
            isClosedCaptioningEnabled: UIAccessibility.isClosedCaptioningEnabled,
            isReduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
            preferredContentSizeCategory: UIApplication.shared.preferredContentSizeCategory.rawValue,
            

            
            // Fingerprints
            screenFingerprint: generateScreenFingerprint(),
            audioFingerprint: generateAudioFingerprint(),
            webCompatibleFingerprint: generateWebCompatibleFingerprint()
        )
    }
    
    // MARK: - Fingerprint Utility Methods
    
    private static func generateScreenFingerprint() -> String {
        let screen = UIScreen.main
        return "\(Int(screen.bounds.width))x\(Int(screen.bounds.height))@\(screen.scale)x"
    }
    
    private static func generateAudioFingerprint() -> String {
        return "audio_unknown"
    }
    
    private static func generateWebCompatibleFingerprint() -> String {
        return "web_unknown"
    }
} 