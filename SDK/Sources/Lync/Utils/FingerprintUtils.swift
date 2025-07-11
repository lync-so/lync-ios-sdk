import Foundation
import UIKit
import AVFoundation

public struct FingerprintUtils {
    
    /**
     * Generate a comprehensive screen fingerprint based on device characteristics
     * that can be consistently measured across different iOS versions
     */
    public static func generateScreenFingerprint() -> String {
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
    
    /**
     * Generate an audio fingerprint based on audio session characteristics
     * and current audio route information
     */
    public static func generateAudioFingerprint() -> String {
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
    
    /**
     * Generate a web-compatible fingerprint that can be compared with web-based fingerprints
     * Uses characteristics that both web and iOS can consistently measure
     */
    public static func generateWebCompatibleFingerprint() -> String {
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
            "model": getDeviceModel().prefix(8).description, // Simplified model
            
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
    
    /**
     * Get the device model identifier (e.g., "iPhone14,3")
     */
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
} 