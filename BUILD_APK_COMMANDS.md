# Commands to Build Release APK

## Method 1: Standard Release APK (Recommended)

```bash
# Clean the build first
flutter clean

# Get dependencies
flutter pub get

# Build release APK (for Android)
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

## Method 2: APK with Specific Name

```bash
# Build with custom name
flutter build apk --release --build-name=1.0.0 --build-number=1

# Or rename after building
# The APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

## Method 3: Split APKs (by Architecture)

```bash
# Build separate APKs for different CPU architectures
flutter build apk --release --split-per-abi

# This generates:
# - app-armeabi-v7a-release.apk (32-bit devices)
# - app-arm64-v8a-release.apk (64-bit devices)
# - app-x86_64-release.apk (emulators)

# Location: build/app/outputs/flutter-apk/
```

## Method 4: App Bundle (For Google Play Store)

```bash
# Build Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab
```

## Method 5: Build for Specific Flavor (if you have flavors)

```bash
# Build for production flavor
flutter build apk --release --flavor=production

# Build for development flavor
flutter build apk --release --flavor=development
```

## Complete Build Process (Step by Step)

### Step 1: Navigate to your project
```bash
cd D:\Freelance\ThanePolice\snehaband
```

### Step 2: Clean previous builds
```bash
flutter clean
```

### Step 3: Upgrade dependencies (optional but recommended)
```bash
flutter pub upgrade
```

### Step 4: Get dependencies
```bash
flutter pub get
```

### Step 5: Run tests (optional)
```bash
flutter test
```

### Step 6: Build release APK
```bash
flutter build apk --release
```

### Step 7: Find your APK
The APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Verify APK Before Distributing

### Check APK size
```bash
# Windows
dir build\app\outputs\flutter-apk\

# Linux/Mac
ls -lh build/app/outputs/flutter-apk/
```

### Install APK on device for testing
```bash
# Connect device via USB
adb devices

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or install with replacement
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Common Issues and Solutions

### Issue 1: "Keystore not found"
**Solution:** Make sure you have configured signing in `android/app/build.gradle`

### Issue 2: "MIN_SDK_VERSION not met"
**Solution:** Update `android/app/build.gradle`:
```gradle
minSdkVersion 21
```

### Issue 3: Build fails
**Solution:**
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## Additional Build Options

### Build with obfuscation (smaller APK size)
```bash
flutter build apk --release --obfuscate --split-debug-info=./build/app/outputs/symbols
```

### Build with specific target platform
```bash
# Android only
flutter build apk --release --target-platform android-arm64

# For both architectures (larger APK)
flutter build apk --release --target-platform android-arm
```

## Signing Your APK

### Debug signing (default)
The APK is automatically signed with debug keys.

### Release signing (recommended)
Create a keystore:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then update `android/app/build.gradle`:
```gradle
android {
    signingConfigs {
        release {
            storeFile file('path/to/upload-keystore.jks')
            storePassword 'YOUR_PASSWORD'
            keyAlias 'upload'
            keyPassword 'YOUR_PASSWORD'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

## Quick Command (Copy-Paste)

For Windows (PowerShell or Command Prompt):
```powershell
cd D:\Freelance\ThanePolice\snehaband
flutter clean
flutter pub get
flutter build apk --release
```

The APK will be at:
```
D:\Freelance\ThanePolice\snehaband\build\app\outputs\flutter-apk\app-release.apk
```

## Verify the APK

### Check APK info
```bash
# Using aapt (Android Asset Packaging Tool)
aapt dump badging build/app/outputs/flutter-apk/app-release.apk

# Or using apkanalyzer
flutter build apk --analyze --target-platform android-arm64
```

## Upload to Google Play (Optional)

If you're publishing to Play Store:
1. Create App Bundle instead:
   ```bash
   flutter build appbundle --release
   ```
2. Upload the `.aab` file to Google Play Console

## Summary

**For distribution to users:**
```bash
flutter build apk --release
```

**For Google Play Store:**
```bash
flutter build appbundle --release
```

**For testing:**
```bash
flutter build apk --debug
```

Your release APK will be ready in `build/app/outputs/flutter-apk/app-release.apk` 🚀
