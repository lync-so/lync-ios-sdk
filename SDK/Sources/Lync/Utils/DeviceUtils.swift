import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency

struct DeviceUtils {
    
    /// Get the device model identifier
    static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        return identifier
    }
    
    /// Get the advertising ID if available
    static func getAdvertisingId() -> String? {
        guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
            return nil
        }
        
        let advertisingId = ASIdentifierManager.shared().advertisingIdentifier
        return advertisingId.uuidString
    }
} 