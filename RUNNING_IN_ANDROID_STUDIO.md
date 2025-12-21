# Running in Android Studio

## iOS Simulator

When running the app on an iOS simulator from Android Studio, you **must** select the appropriate run configuration:

### Steps to Run:

1. In Android Studio, click the run configuration dropdown (top toolbar, next to the device selector)
2. Select **"development"** from the list of configurations
3. Select your iOS simulator from the device dropdown
4. Click the Run button (▶️)

### Available Run Configurations:

- **development** - Runs the development flavor with `lib/main/main_development.dart`
- **production** - Runs the production flavor with `lib/main/main_production.dart`
- **gallery** - Runs the gallery (if available)

### Why This is Required:

The iOS build uses flavor-specific GoogleService-Info.plist files located in:
- `ios/Runner/development/GoogleService-Info.plist` (for development)
- `ios/Runner/production/GoogleService-Info.plist` (for production)

The Xcode build script automatically copies the correct file based on the build configuration. If you don't select a run configuration, the build may fail with:

```
Error (Xcode): Could not get GOOGLE_APP_ID in Google Services file from build environment
```

### Command Line Alternative:

You can also run directly from the command line:

```bash
# For iOS Simulator (development)
flutter run --target=lib/main/main_development.dart --flavor=development

# For Android (development)
flutter run --target=lib/main/main_development.dart --flavor=development
```

### Troubleshooting:

If you still get the GoogleService error:

1. Make sure you've selected the "development" run configuration
2. Clean the project: `flutter clean`
3. Get dependencies: `flutter pub get`
4. Try running again

## Android

Android builds work similarly - select the "development" configuration for development builds.
