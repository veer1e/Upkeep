# Life Maintenance — Flutter

A production-ready Flutter port of the Life Maintenance Tracker app.

---

## Tech Stack

| Concern | Package |
|---|---|
| State management | `provider ^6.1.2` |
| Local persistence | `shared_preferences ^2.2.3` |
| Navigation | Flutter `Navigator` (in-app routing via `AppShell`) |
| Date formatting | Native Dart `DateTime` |

---

## Project Structure

```
lib/
├── main.dart                     # Entry point + AppShell + BottomNav + FAB
├── theme/
│   └── app_theme.dart            # Colors, typography, MaterialTheme
├── models/
│   └── task.dart                 # Task model + all utility functions + seed data
├── providers/
│   └── app_provider.dart         # ChangeNotifier state + SharedPreferences
├── screens/
│   ├── home_screen.dart          # Dashboard: overdue / today / upcoming
│   ├── tasks_screen.dart         # All tasks sorted by status
│   ├── task_details_screen.dart  # Task hero + stats + history timeline
│   ├── add_task_screen.dart      # 3-step multi-step add flow
│   └── settings_screen.dart     # Stats + toggles + data management
└── widgets/
    ├── task_card.dart            # Reusable task card with Done + Details buttons
    └── completion_sheet.dart     # Modal bottom sheet for marking done
```

---

## Setup

### 1. Prerequisites

- Flutter SDK ≥ 3.2.0 installed (`flutter --version`)
- Android Studio or VS Code with Flutter plugin
- Android emulator or physical device

### 2. Add Inter Font

Download Inter from https://fonts.google.com/specimen/Inter and add these files to `assets/fonts/`:

```
Inter-Regular.ttf
Inter-Medium.ttf
Inter-SemiBold.ttf
Inter-Bold.ttf
Inter-ExtraBold.ttf
```

> **Shortcut:** If you don't want to bundle the font, remove the `fonts` section from `pubspec.yaml` and the font family references will fall back to the system font automatically.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run

```bash
flutter run
```

---

## Google Play Deployment Checklist

### App identity
- [ ] Update `name` in `pubspec.yaml` to your final app name
- [ ] Update `applicationId` in `android/app/build.gradle`
- [ ] Create a proper launcher icon (use `flutter_launcher_icons` package)
- [ ] Create a splash screen (use `flutter_native_splash` package)

### Build config (`android/app/build.gradle`)
```groovy
defaultConfig {
    applicationId "com.yourcompany.lifemaintenance"
    minSdkVersion 21
    targetSdkVersion 34
    versionCode 1
    versionName "1.0.0"
}
```

### Signing
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Add `key.properties` to `android/` (and `.gitignore` it):
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=upload
storeFile=<path-to>/upload-keystore.jks
```

### Build release APK / AAB
```bash
# AAB (required for Play Store)
flutter build appbundle --release

# APK (for sideloading / testing)
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Feature Roadmap (Post-MVP)

- [ ] Push notifications when tasks are due
- [ ] Smart scheduling: ML pattern learning from history
- [ ] Conditional triggers (e.g. weather, mileage)
- [ ] Dark mode
- [ ] iCloud / Google Drive backup
- [ ] Widget (home screen)
- [ ] Wear OS companion
