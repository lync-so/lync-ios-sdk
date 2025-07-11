import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency

public struct DeviceUtils {
    
    /**
     * Get the device model identifier (e.g., "iPhone14,3")
     */
    public static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        return modelCode ?? "Unknown"
    }
    
    /**
     * Get the advertising identifier (IDFA) if available and permitted
     */
    public static func getAdvertisingId() -> String? {
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
    
    /**
     * Get the current battery state as a string
     */
    public static func getBatteryState(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: return "unknown"
        case .unplugged: return "unplugged"
        case .charging: return "charging"
        case .full: return "full"
        @unknown default: return "unknown"
        }
    }
    
    /**
     * Get disk space information (total and free space)
     */
    public static func getDiskSpace() -> (total: Int64, free: Int64)? {
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
    
    /**
     * Get memory usage information (total and used memory)
     */
    public static func getMemoryUsage() -> (total: Int64, used: Int64)? {
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
    
    /**
     * Get device orientation as a string
     */
    public static func getDeviceOrientation(_ orientation: UIDeviceOrientation) -> String {
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
    
    /**
     * Get interface orientation as a string
     */
    public static func getInterfaceOrientation() -> String {
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
    
    /**
     * Get user interface idiom as a string
     */
    public static func getUserInterfaceIdiom(_ idiom: UIUserInterfaceIdiom) -> String {
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
} 