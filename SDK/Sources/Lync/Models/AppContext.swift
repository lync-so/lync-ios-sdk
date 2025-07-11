import Foundation

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

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "install_time": installTime as Any,
            "session_id": sessionId,
            "previous_session_count": previousSessionCount,
            "time_since_install": timeSinceInstall as Any,
            "first_launch": firstLaunch
        ]
        
        return dict
    }
} 