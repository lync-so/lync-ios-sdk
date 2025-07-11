import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency

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
    
    func toDictionary() -> [String: Any] {
        return [
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
            "device_type": deviceType
        ]
    }
    
    static func current() -> DeviceInfo {
        let device = UIDevice.current
        let screen = UIScreen.main
        let mainBundle = Bundle.main
        let locale = Locale.current
        
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
            deviceType: device.userInterfaceIdiom == .pad ? "tablet" : "phone"
        )
    }
} 