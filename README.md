# LyncAttribution iOS SDK

Lightweight attribution tracking for iOS apps. Track app installs, user registrations, and custom events, matching them to original click data from your marketing campaigns.

## Features

- 📱 **App Install Tracking** - Track when users install your app
- 🙋 **Registration Tracking** - Track when users sign up
- 🎯 **Custom Event Tracking** - Track any custom conversion events
- 🔗 **Attribution Matching** - Match app events to original click data
- 🛡️ **Privacy Compliant** - Respects iOS 14+ App Tracking Transparency
- 🏎️ **Lightweight** - Single file, minimal dependencies

## Installation

### Option 1: Manual Installation

1. Download `LyncAttribution.swift`
2. Drag it into your Xcode project
3. Make sure to add it to your target

### Option 2: Swift Package Manager (GitHub)

**In Xcode:**
1. Go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/YOUR_USERNAME/lync-attribution-ios`
3. Choose version (or branch)
4. Add to your target

**In Package.swift:**
```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/lync-attribution-ios", from: "1.0.0")
]
```

**Then import in your target:**
```swift
.target(
    name: "YourApp",
    dependencies: ["LyncAttribution"]
)
```

## Quick Start

### 1. Add to Your Project

**Swift Package Manager (Recommended):**
```
https://github.com/lync-so/lync-ios-sdk.git
```

### 2. Configure in Info.plist

Add these keys to your app's `Info.plist`:

```xml
<key>LyncAttributionAPIBaseURL</key>
<string>https://your-api-domain.com</string>
<key>LyncAttributionEntityID</key>
<string>your-entity-id-here</string>
<key>LyncAttributionAPIKey</key>
<string>sk_live_your_api_key_here</string>
<key>LyncAttributionDebug</key>
<true/>
```

### 3. Initialize in AppDelegate

```swift
import LyncAttribution

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure from Info.plist
        LyncAttribution.configure()
        
        // Track app install
        LyncAttribution.trackInstall()
        
        return true
    }
    
    // Handle deep links for attribution
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        LyncAttribution.handleDeepLink(url)
        return true
    }
}
```

### 4. Track Events

```swift
// Track user registration
LyncAttribution.trackRegistration(
    customerId: "user123",
    customerEmail: "user@example.com"
)

// Track custom events
LyncAttribution.trackEvent(
    type: .custom,
    name: "premium_upgrade",
    customProperties: ["plan": "yearly"]
)
```

## Alternative Configuration

If you prefer programmatic configuration:

```swift
LyncAttribution.configure(
    apiBaseURL: "https://your-api-domain.com",
    entityId: "your-entity-id",
    apiKey: "sk_live_your_api_key",
    debug: true
)
```

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
    if let clickId = LyncAttribution.extractClickId(from: url) {
        // Store the click_id for attribution
        attribution.setClickId(clickId)
        
        // Track install with attribution
        attribution.trackInstall(clickId: clickId)
    }
    
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
let config = LyncAttribution.Config(
    apiBaseURL: "https://api.yourdomain.com",
    entityId: "entity_123",
    apiKey: "sk_test_123", // For authenticated requests
    debug: false // Disable debug logs in production
)

let attribution = LyncAttribution(config: config)
```

### Batch Event Tracking

For apps that need to track multiple events:

```swift
// Track multiple events for the same user
let userId = "user123"

attribution.trackEvent(type: .custom, name: "Onboarding Complete", customerId: userId)
attribution.trackEvent(type: .custom, name: "First Purchase", customerId: userId)
attribution.trackEvent(type: .custom, name: "Subscription", customerId: userId)
```

### Error Handling

```swift
attribution.trackInstall { result in
    switch result {
    case .success:
        // Event tracked successfully
        print("✅ Event tracked")
        
    case .failure(let error):
        if let attributionError = error as? LyncAttributionError {
            switch attributionError {
            case .invalidURL:
                print("❌ Invalid API URL configured")
            case .invalidResponse:
                print("❌ Invalid response from server")
            case .apiError(let code, let message):
                print("❌ API Error \(code): \(message)")
            }
        } else {
            print("❌ Network error: \(error)")
        }
    }
}
```

## Testing

### Debug Mode

Enable debug mode to see detailed logs:

```swift
let config = LyncAttribution.Config(
    apiBaseURL: "https://your-test-api.com",
    entityId: "test_entity",
    debug: true // Enable detailed logging
)
```

You'll see logs like:
```
🚀 LyncAttribution initialized
📍 API URL: https://your-api.com
🏢 Entity ID: entity_123
📤 Sending event to: https://your-api.com/api/track/mobile
📦 Payload: {"entity_id":"entity_123",...}
📥 Response status: 200
✅ Event tracked: install - App Install
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
attribution.trackInstall()

// Replace event tracking
// OLD: Adjust.trackEvent(adjustEvent)  
// NEW:
attribution.trackEvent(type: .custom, name: "Event Name")
```

## Troubleshooting

### Common Issues

**Events not appearing in dashboard:**
- Check your `entityId` is correct
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

- [ ] SDK initialized with correct `apiBaseURL` and `entityId`
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