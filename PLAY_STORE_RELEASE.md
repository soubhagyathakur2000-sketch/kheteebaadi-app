# Kheteebaadi - Play Store Release Checklist

## Build Commands (Run on Your Machine)

```bash
cd flutter_app/

# Step 1: Validate everything is ready
./validate-release.sh

# Step 2: Build the .aab for Play Store
./build-release.sh

# Step 3 (optional): Also build APK for direct testing
./build-release.sh --apk
```

### Build Output Locations
- **AAB (Play Store):** `build/app/outputs/bundle/release/app-release.aab`
- **APK (Testing):** `build/app/outputs/flutter-apk/app-release.apk`
- **Debug symbols:** `build/debug-info/` (upload to Play Console for crash reports)

---

## Play Store Console Setup

### 1. Create Developer Account
- Go to https://play.google.com/console
- Pay one-time $25 registration fee
- Complete identity verification (takes 1-2 days)

### 2. Create App
- Click "Create app"
- App name: **Kheteebaadi**
- Default language: **English (India)**
- App type: **App** (not game)
- Free or paid: **Free**

### 3. Store Listing
Fill in these fields:

| Field | Value |
|-------|-------|
| App name | Kheteebaadi |
| Short description | Agricultural marketplace connecting farmers with mandis across India |
| Full description | (See below) |
| App icon | 512x512 PNG (high-res version of your app icon) |
| Feature graphic | 1024x500 PNG (banner image) |
| Screenshots | Min 2, recommended 8 (phone screenshots) |
| App category | Business or Shopping |
| Tags | Agriculture, Farming, Marketplace, Mandi |
| Contact email | soubhagyathakur2000@gmail.com |
| Privacy policy URL | (Required - host one on your website) |

### Suggested Full Description:
```
Kheteebaadi connects farmers directly with mandis (agricultural markets)
across rural India. Get real-time mandi prices, create crop listings,
manage orders, and receive payments — all in Hindi, Marathi, and English.

Features:
- Live mandi prices updated every 15 minutes
- Create and manage crop listings with photos
- Voice search in Hindi for easy navigation
- Works offline on low-end Android devices
- Secure OTP-based login (no password needed)
- Order tracking and payment via Razorpay
- Multilingual: English, Hindi, Marathi

Built for Indian farmers, by Indian farmers.
```

### 4. App Content (Policy Declarations)
- **Privacy policy:** Required. Must describe data collection (phone number, location, photos).
- **Ads:** Select "No ads"
- **Target audience:** 18+ (financial transactions)
- **Data safety:** Declare phone number, location, photos collected

### 5. Release Track
- Use **Internal testing** first (up to 100 testers)
- Then **Closed testing** (larger group)
- Then **Open testing** or **Production**

### 6. Upload AAB
- Go to Release > Production > Create new release
- Upload `app-release.aab`
- Enable **Play App Signing** (Google manages the actual key, you keep the upload key)
- Upload debug symbols from `build/debug-info/`

### 7. Review & Submit
- Google review takes 1-7 days for new apps
- First submission usually takes longer

---

## Flutter Build Flags Reference

```bash
# Production build (recommended)
flutter build appbundle --release \
  --dart-define=ENV=production \
  --obfuscate \
  --split-debug-info=build/debug-info

# With custom Razorpay key
flutter build appbundle --release \
  --dart-define=ENV=production \
  --dart-define=RAZORPAY_KEY=rzp_live_XXXXX \
  --obfuscate \
  --split-debug-info=build/debug-info

# Debug APK for testing
flutter build apk --debug --dart-define=ENV=development

# Analyze APK size
flutter build apk --analyze-size --dart-define=ENV=production
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Keystore was tampered with` | Wrong password in key.properties |
| `minSdkVersion 16 cannot be smaller` | Already set to 21 in build.gradle |
| `Execution failed for task ':app:minifyReleaseWithR8'` | Check proguard-rules.pro |
| `Could not resolve all files for configuration` | Run `flutter clean && flutter pub get` |
| Build OOM error | Increase Gradle JVM: `-Xmx4G` in gradle.properties |
| `Namespace not specified` | Already set to `com.kheteebaadi.app` in build.gradle |
