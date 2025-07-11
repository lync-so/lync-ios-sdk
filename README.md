# Lync iOS SDK

Super lean attribution tracking for iOS apps. Track app installs, user registrations, and custom events with just a few lines of code.

## Features

- 📱 **App Install Tracking** - Track when users install your app
- 🙋 **Registration Tracking** - Track when users sign up
- 🎯 **Custom Event Tracking** - Track any custom events
- 🔗 **Attribution Matching** - Match app events to original click data
- 🛡️ **Privacy Compliant** - Respects iOS 14+ App Tracking Transparency
- 🏎️ **Ultra Lightweight** - Minimal dependencies, clean codebase
- 👤 **User Info** - Send user id and email with any event

## Installation

### Swift Package Manager (Recommended)

**In Xcode:**
1. Go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/YOUR_USERNAME/lync-ios-sdk`
3. Choose version (or branch)
4. Add to your target

**Or add locally:**
1. Click **Add Local...** in Package Dependencies
2. Select the `lync-ios-sdk` folder
3. Add to your target

## Quick Start

### 1. Initialize Once

```swift
import Lync

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Lync (only need to do this once)
        Lync.shared.initialize(
            apiKey: "sk_live_your_api_key_here",
            baseURL: "https://api.lync.so",  // Optional, defaults to https://api.lync.so
            debug: true                      // Optional, defaults to false
        )
        
        // Track app install
        Lync.shared.trackInstall(userId: "user123", userEmail: "user@example.com")
        
        return true
    }
}
```

### 2. Track Events Anywhere

```swift
// Track user registration
Lync.shared.trackRegistration(userId: "user123", userEmail: "user@example.com")

// Track custom events
Lync.shared.track("purchase", properties: ["amount": 29.99, "currency": "USD"])
Lync.shared.track("button_clicked", properties: ["button": "sign_up"])
Lync.shared.track("level_completed", properties: ["level": 5])

// Or use convenience methods
Lync.shared.trackEvent("premium_upgrade", properties: ["plan": "yearly"])
```

## API Reference

### Initialization

```swift
Lync.shared.initialize(
    apiKey: "sk_live_your_api_key_here",
    baseURL: "https://api.lync.so",  // Optional
    debug: true                      // Optional
)
```

### Tracking Methods

```swift
// Main tracking method
Lync.shared.track(
    _ event: String,
    properties: [String: Any]? = nil,
    userId: String? = nil,
    userEmail: String? = nil
)

// Convenience methods
Lync.shared.trackInstall(userId: String? = nil, userEmail: String? = nil)
Lync.shared.trackRegistration(userId: String? = nil, userEmail: String? = nil)
Lync.shared.trackEvent(_ event: String, properties: [String: Any]? = nil)
```

## Usage Examples

### Basic Tracking

```swift
// App lifecycle events
Lync.shared.track("app_opened")
Lync.shared.track("app_backgrounded")

// User actions
Lync.shared.track("button_clicked", properties: ["button": "sign_up"])
Lync.shared.track("screen_viewed", properties: ["screen": "onboarding"])

// Business events
Lync.shared.track("purchase", properties: [
    "amount": 29.99,
    "currency": "USD",
    "product_id": "premium_plan"
])
```

### With User Information

```swift
// Track with user context
Lync.shared.track(
    "subscription_started",
    properties: ["plan": "yearly"],
    userId: "user123",
    userEmail: "user@example.com"
)

// Install tracking with user info
Lync.shared.trackInstall(
    userId: "user123",
    userEmail: "user@example.com"
)
```

## Device Information

The SDK automatically collects this device information for attribution:

```json
{
  "platform": "ios",
  "device_model": "iPhone14,3",
  "device_name": "iPhone 13 Pro",
  "os_version": "17.0.1",
  "app_version": "1.0.0",
  "bundle_id": "com.yourapp.name",
  "vendor_id": "ABC123-DEF456",
  "advertising_id": "XYZ789",
  "timezone": "America/New_York",
  "language": "en-US",
  "screen_width": 1170,
  "screen_height": 2532,
  "device_type": "phone"
}
```

## Privacy & Permissions

### iOS 14+ App Tracking Transparency

The SDK respects ATT and only collects IDFA if permission is granted:

```swift
import AppTrackingTransparency

// Request tracking permission (optional, but improves attribution)
if #available(iOS 14, *) {
    ATTrackingManager.requestTrackingAuthorization { status in
        // Initialize Lync after permission is granted
        Lync.shared.initialize(apiKey: "your-api-key")
    }
}
```

## Attribution Flow

1. **User clicks your ad/link** → Your system stores click data
2. **User installs app** → iOS SDK sends install event with device fingerprinting
3. **Your system matches** install to stored click data based on timing + device info

## Requirements

- iOS 12.0+
- Mac Catalyst 13.0+
- Swift 5.7+

## Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/YOUR_USERNAME/lync-ios-sdk/issues)
- Email: support@lync.so

## License

MIT License - see LICENSE file for details. 