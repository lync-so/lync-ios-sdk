# Lync iOS SDK

Lightweight attribution tracking for iOS apps. Track app installs, user registrations, and custom events, matching them to original click data from your marketing campaigns.

## Features

- 📱 **App Install Tracking** - Track when users install your app
- 🙋 **Registration Tracking** - Track when users sign up
- 🎯 **Custom Event Tracking** - Track any custom conversion events
- 🔗 **Attribution Matching** - Match app events to original click data
- 🛡️ **Privacy Compliant** - Respects iOS 14+ App Tracking Transparency
- 🏎️ **Lightweight** - Single file, minimal dependencies
- 👤 **Customer Info** - Send customer id, email, name, and avatar URL with any event

## Installation

### Option 1: Manual Installation

1. Download `Lync.swift` and `Config.swift`
2. Drag them into your Xcode project
3. Make sure to add them to your target

### Option 2: Swift Package Manager (GitHub)

**In Xcode:**
1. Go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/YOUR_USERNAME/lync-ios-sdk`
3. Choose version (or branch)
4. Add to your target

**In Package.swift:**
```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/lync-ios-sdk", from: "0.0.1")
]
```

**Then import in your target:**
```swift
.target(
    name: "YourApp",
    dependencies: ["Lync"]
)
```

## Quick Start

### 1. Add to Your Project

**Swift Package Manager (Recommended):**
```
https://github.com/lync-so/lync-ios-sdk.git
Version: 0.0.1
```

### 2. Configure in Info.plist

Add these keys to your app's `Info.plist`:

```xml
<key>LyncAPIBaseURL</key>
<string>https://your-api-domain.com</string>
<key>LyncAPIKey</key>
<string>sk_live_your_api_key_here</string>
<key>LyncDebug</key>
<true/>
```

### 3. Initialize in AppDelegate

```swift
import Lync

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure programmatically
        let config = Config(
            apiKey: "sk_live_your_api_key_here",
            baseURL: URL(string: "https://your-api-domain.com")!,
            debug: true
        )
        Lync.shared.configure(with: config)
        
        // Track app install (with optional customer info)
        Lync.shared.trackInstall(
            customerExternalId: "user123",
            customerEmail: "user@example.com",
            customerAvatarUrl: "https://example.com/avatar.png",
            customerName: "Jane Doe"
        )
        
        return true
    }
    
    // Handle deep links for attribution
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // (Deep link handling code here)
        return true
    }
}
```

### 4. Track Events (with Customer Info)

```swift
// Track user registration
Lync.shared.trackRegistration(
    customerExternalId: "user123",
    customerEmail: "user@example.com",
    customerAvatarUrl: "https://example.com/avatar.png",
    customerName: "Jane Doe"
)

// Track custom events
Lync.shared.trackCustomEvent(
    "premium_upgrade",
    properties: ["plan": "yearly"],
    customerExternalId: "user123",
    customerEmail: "user@example.com",
    customerAvatarUrl: "https://example.com/avatar.png",
    customerName: "Jane Doe"
)
```

## Alternative Configuration

If you prefer Info.plist configuration, you can still use it (see previous instructions), but programmatic configuration is recommended for passing customer info.

## Attribution Flow

The attribution system works like this:

1. **User clicks your ad/link** → Your system stores click data with `click_id`
2. **User goes to App Store** → (no data can be passed)
3. **User installs app** → iOS SDK sends install event with device fingerprinting
4. **Your system matches** install to stored click data based on timing + device info

### With Deep Links (Recommended)

If your marketing campaigns use deep links that open your app after install:

```swift
// In AppDelegate or SceneDelegate
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // Extract click_id from deep link
    // (Deep link handling code here)
    return true
}
```

## Attribution Matching

The system uses several methods to match app installs to clicks:

### 1. Direct Attribution (Best)
- **Deep Links**: When users click a link that opens your app after install
- **Click ID**: Passed via URL parameter `?click_id=abc123`

### 2. Probabilistic Attribution (Fallback)
- **Device Fingerprinting**: iOS version, device model, timezone, etc.
- **Timing**: Install time vs click time correlation
- **IP Address**: Network-based matching

## Device Information Collected

The SDK automatically collects this device information for attribution:

```swift
{
  "platform": "ios",
  "device_model": "iPhone14,3",
  "device_name": "iPhone 13 Pro", 
  "os_version": "17.0.1",
  "app_version": "1.0.0",
  "bundle_id": "com.yourapp.name",
  "vendor_id": "ABC123-DEF456", // identifierForVendor
  "advertising_id": "XYZ789", // IDFA (if permission granted)
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
        switch status {
        case .authorized:
            print("📱 Tracking authorized - IDFA available")
        case .denied, .restricted, .notDetermined:
            print("📱 Tracking not authorized - using other signals")
        @unknown default:
            break
        }
    }
}
```

### Data Collection

- ✅ **No PII collected by default** (unless you provide customer info)
- ✅ **Respects user privacy settings**
- ✅ **No persistent tracking identifiers** (except IDFA with permission)
- ✅ **All data stored securely** in your own database

## API Integration

The SDK sends data to your `/api/track/mobile` endpoint. Make sure your API is configured to handle these requests.

### Example API Response

```json
{
  "success": true,
  "interaction_id": "abc123",
  "click_id": "def456",
  "message": "install event tracked successfully",
  "attribution": {
    "entity_id": "your-entity-id",
    "source_type": "app_install",
    "utm_campaign": "summer_campaign",
    "utm_source": "google_ads"
  }
}
```

## Advanced Usage

### Custom Configuration

```swift
let config = Config(
    apiKey: "sk_test_123",
    baseURL: URL(string: "https://api.yourdomain.com")!,
    debug: false // Disable debug logs in production
)

Lync.shared.configure(with: config)
```

### Batch Event Tracking

For apps that need to track multiple events:

```swift
// Track multiple events for the same user
let userId = "user123"

Lync.shared.trackCustomEvent("Onboarding Complete", customerExternalId: userId)
Lync.shared.trackCustomEvent("First Purchase", customerExternalId: userId)
Lync.shared.trackCustomEvent("Subscription", customerExternalId: userId)
```

### Error Handling

```swift
// Example error handling for event tracking
Lync.shared.trackInstall { result in
    switch result {
    case .success:
        print("✅ Event tracked")
    case .failure(let error):
        print("❌ Tracking failed: \(error)")
    }
}
```

## Testing

### Debug Mode

Enable debug mode to see detailed logs:

```swift
let config = Config(
    apiKey: "sk_test_123",
    baseURL: URL(string: "https://your-test-api.com")!,
    debug: true // Enable detailed logging
)
Lync.shared.configure(with: config)
```

You'll see logs like:
```
🔗 Lync SDK initialized with base URL: https://your-api.com
🔗 Click ID: ...
🔗 Lync ID: ...
🔗 Sending event to: https://your-api.com/api/track/mobile
🔗 Payload: {...}
✅ Event sent successfully
```

### Testing Attribution

1. **Test install tracking**: Delete and reinstall your app
2. **Test with click_id**: Use a test deep link with `?click_id=test123`
3. **Test registration**: Sign up with a test account
4. **Check your analytics**: Verify events appear in your dashboard

## Migration Guide

### From Other SDKs

If you're migrating from another attribution SDK:

```swift
// Replace your old SDK initialization
// OLD: Adjust.appDidLaunch(adjustConfig)
// NEW: 
Lync.shared.trackInstall()

// Replace event tracking
// OLD: Adjust.trackEvent(adjustEvent)  
// NEW:
Lync.shared.trackCustomEvent("Event Name")
```

## Troubleshooting

### Common Issues

**Events not appearing in dashboard:**
- Check your API key is correct
- Verify your API endpoint is working
- Enable debug mode to see network requests
- Check your server logs

**Attribution not working:**
- Ensure deep links are configured correctly
- Test with `click_id` parameter manually
- Verify click data is being stored in your system

**Build errors:**
- Make sure to import required frameworks: `AdSupport`, `AppTrackingTransparency`
- Check iOS deployment target (minimum iOS 12.0)

### Debug Checklist

- [ ] SDK initialized with correct `apiKey` and `baseURL`
- [ ] Network connection available
- [ ] API endpoint responding with 200 status
- [ ] Debug mode enabled to see detailed logs
- [ ] Deep links configured in Info.plist (if using)

## Support

- 📖 **Documentation**: [Link to your docs]
- 🐛 **Bug Reports**: [Link to issues]
- 💬 **Discord**: [Link to community]
- ✉️ **Email**: support@yourdomain.com

## License

MIT License - see LICENSE file for details. 