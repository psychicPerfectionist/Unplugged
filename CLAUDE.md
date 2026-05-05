# Unplugged – iOS App Project Context

> This file is automatically read by Claude Code at session start.
> It contains the full project specification, architecture decisions, and development guidelines.
> **Design references live in `docs/designs/` — always check the relevant PNG before implementing any screen.**

---

## App Overview

**Unplugged** is a gamified screen time management app for iOS. It turns daily phone usage into
a virtual pet experience. Users set a personal daily screen time limit, which becomes the health
of a virtual pet called **Pluggie**. As screen time accumulates, Pluggie's health drops in real
time. If the limit is exceeded, Pluggie dies and all connected friends are notified via push
notification.

**Core loop:** Keep Pluggie alive → stay under your limit → don't be the one on the leaderboard
with a dead pet.

---

## Design References (Figma Exports)

> All screen designs are exported as PNGs and stored in `docs/designs/`.
> **These are the source of truth for UI/UX — always implement to match them pixel-closely.**
> When implementing any screen, start by reading the corresponding PNG with `@docs/designs/<file>.png`

### Design File Map

| Screen / Feature | File |
|---|---|
| Login Screen | `docs/designs/Login.png` |
| Splash Screen | `docs/designs/Splash Screen.png` |
| Add New Reminder Screen | `docs/designs/add new reminder.png` |
| App Lock Screen | `docs/designs/app lock.png` |
| Block Apps Screen | `docs/designs/block apps.png` |
| Daily Limit Screen | `docs/designs/daily limit.png` |
| Death Screen | `docs/designs/death screen.png` |
| Delete Account Screen | `docs/designs/delete account.png` |
| Dynamic Type Screen | `docs/designs/dynamic type.png` |
| Edit Profile Screen | `docs/designs/edit profile.png` |
| Face ID Setup Screen 1 | `docs/designs/face ID setting up screen 1.png` |
| Face ID Setup Screen 2 | `docs/designs/face ID setting up screen 2.png` |
| Face ID Setup Screen 3 | `docs/designs/face ID setting up screen 3.png` |
| Forgot Password Screen | `docs/designs/forgot password.png` |
| Friends Screen | `docs/designs/friends screen.png` |
| History Bottom Sheet 1 | `docs/designs/history bottom sheet1.png` |
| History Bottom Sheet 2 | `docs/designs/history bottom sheet2.png` |
| History Screen | `docs/designs/history.png` |
| Home Screen | `docs/designs/home screen.png` |
| Leaderboard Screen | `docs/designs/leaderboard screen.png` |
| Onboarding Screen 1 | `docs/designs/onboarding screen1.png` |
| Onboarding Screen 2 | `docs/designs/onboarding screen2.png` |
| Onboarding Screen 3 | `docs/designs/onboarding screen 3.png` |
| PIN Lock Setup Screen 1 | `docs/designs/pin lock setting uo screen 1.png` |
| PIN Lock Setup Screen 2 | `docs/designs/pin lock setting uo screen 2.png` |
| PIN Lock Setup Screen 3 | `docs/designs/pin lock setting uo screen 3.png` |
| Reset Time Screen | `docs/designs/reset time.png` |
| Send Message Screen | `docs/designs/send message.png` |
| Settings Screen | `docs/designs/settings.png` |
| Sign Up Screen | `docs/designs/sign up.png` |
| Usage Reminders Screen | `docs/designs/usage reminders.png` |
| VoiceOver Labels Screen | `docs/designs/voiceover labels.png` |
| Widget | `docs/designs/widget.png` |

> **Rename your PNG files to match the table above**, or update the table to match your actual filenames.
> If a screen isn't listed, add it to the table with a descriptive name.

### Design System – Extract from Figma PNGs

When you first start a session, run this prompt in Claude Code to extract the design tokens:

```
@docs/designs/home-thriving.png @docs/designs/leaderboard.png @docs/designs/settings.png
Analyse these screens and extract:
1. Colour palette (background, surface, accent, text colours as hex)
2. Typography (font names, sizes, weights used for headings, body, captions)
3. Corner radius values
4. Spacing/padding patterns
5. Any recurring UI components (cards, buttons, chips)
Output as a Swift DesignSystem.swift constants file.
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Minimum Target | iOS 17.0 |
| Local Storage | Core Data |
| Screen Time | ScreenTime API (ManagedSettings, FamilyControls, DeviceActivity) |
| Cloud/Social | CloudKit (iCloud) |
| Notifications | UserNotifications framework |
| Auth | AuthenticationServices (Sign in with Apple) + LocalAuthentication (Face ID / Touch ID) |
| Widget | WidgetKit |
| Animations | SwiftUI animations + Lottie (if needed) |

---

## Project Structure

```
Unplugged/
├── CLAUDE.md                        ← you are here
├── Unplugged.xcodeproj
├── Unplugged/
│   ├── App/
│   │   ├── UnpluggedApp.swift       ← @main entry point
│   │   └── AppDelegate.swift
│   ├── Models/
│   │   ├── PluggieState.swift       ← health % → mood enum
│   │   ├── UserProfile.swift
│   │   ├── FriendEntry.swift        ← leaderboard model
│   │   └── DayRecord.swift          ← history/streak model
│   ├── ViewModels/
│   │   ├── PluggieViewModel.swift   ← core health logic
│   │   ├── LeaderboardViewModel.swift
│   │   ├── HistoryViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views/
│   │   ├── Home/
│   │   │   ├── HomeView.swift       ← Pluggie lives here
│   │   │   └── PluggieView.swift    ← animated pet character
│   │   ├── Leaderboard/
│   │   │   └── LeaderboardView.swift
│   │   ├── History/
│   │   │   ├── HistoryView.swift    ← calendar grid
│   │   │   └── DayDetailSheet.swift
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   └── AppBlockingView.swift
│   │   └── Auth/
│   │       ├── LoginView.swift
│   │       └── SignUpView.swift
│   ├── Services/
│   │   ├── ScreenTimeService.swift  ← ScreenTime API wrapper
│   │   ├── CloudKitService.swift    ← leaderboard + friend sync
│   │   ├── NotificationService.swift
│   │   └── BiometricService.swift
│   ├── Persistence/
│   │   ├── CoreDataStack.swift
│   │   └── Unplugged.xcdatamodeld
│   └── Resources/
│       ├── Assets.xcassets
│       └── Localizable.strings
├── UnpluggedWidget/                 ← WidgetKit extension target
│   ├── UnpluggedWidget.swift
│   └── WidgetEntry.swift
└── UnpluggedTests/
```

---

## Feature Specifications

### Feature 1 – Authentication & Security
- Sign Up / Login with Sign in with Apple (preferred) or email
- Biometric auth via `LocalAuthentication` (Face ID / Touch ID)
- Biometric lock on Settings screen prevents users changing their own screen time limit
- Keychain storage for credentials

### Feature 2 – Push Notifications & Reminders
- User configures reminder interval (30 min, 1 hr, etc.)
- Notification fires at each interval of accumulated screen time usage
- **Near-death warning** fires at 90% of daily limit reached
- **Death broadcast** fires to all CloudKit-connected friends when limit is exceeded (100%)
- Use `UNUserNotificationCenter` for local notifications
- Use CloudKit push for friend death broadcasts

### Feature 3 – Pluggie Virtual Pet (Home Screen)
Pluggie is a round creature living in an illustrated cozy room. His mood, colour, and animations
change based on the health percentage:

| Health % | State | Visual |
|---|---|---|
| 0–25% used | **Thriving** | Bright green, bouncing, sparkles, happy eyes |
| 25–50% used | **Content** | Calm, gentle sway, small smile |
| 50–75% used | **Worried** | Yellow tint, sweat drop, nervous fidget |
| 75–90% used | **Struggling** | Orange tint, tired eyes, visible cracks |
| 90–99% used | **Critical** | Red tint, dizzy spiral eyes, flickering, alarm |
| 100% used | **Dead** | Fully grey, X eyes, cracks, lying flat, halo, ghost puff |

- Pluggie resets to full health automatically at midnight each day
- Animations must respect `UIAccessibility.isReduceMotionEnabled`

### Feature 4 – Daily Screen Time Limit & Tracking
- User sets a daily usage limit (in hours/minutes) during onboarding and in Settings
- Uses `DeviceActivityMonitor` and `ManagedSettings` from the Screen Time API
- Health % = `currentUsage / dailyLimit * 100`
- Auto-reset at midnight via `DeviceActivitySchedule`
- Requires `com.apple.developer.family-controls` entitlement

### Feature 5 – App Blocking
- User selects apps to block via `FamilyActivityPicker`
- Blocking activates `ManagedSettingsStore` to lock selected apps at OS level
- While blocking is active, Pluggie's health timer is **frozen** (usage during block period excluded)
- Frozen state visually indicated on HomeView

### Feature 6 – Social Leaderboard
- Shows all connected friends ranked by current Pluggie health %
- Top 3 displayed in a podium layout
- Dead Pluggie entries shown with grey indicator + skull/death badge
- Real-time sync via CloudKit public database
- Friend connections stored in CloudKit, discoverable via iCloud contacts
- Updates pushed via CloudKit subscriptions

### Feature 7 – History & Streak Tracking
- Monthly calendar grid (custom SwiftUI component)
- Each day cell shows a small Pluggie icon: green (survived) or grey (failed/dead)
- Tap any day → bottom sheet with total screen time and limit comparison
- **Current streak** counter: consecutive days survived
- **Best streak** counter: all-time record
- Data source: Core Data `DayRecord` entities

### Feature 8 – Core Data & Local Storage
Entities to model:
```
DayRecord
  - date: Date
  - totalUsageSeconds: Int64
  - limitSeconds: Int64
  - survived: Bool

UsageLog
  - timestamp: Date
  - durationSeconds: Int64
  - appBundleID: String?

UserSettings
  - dailyLimitSeconds: Int64
  - notificationInterval: Int16
  - isBiometricEnabled: Bool
  - blockedApps: [String] (transformable)

StreakRecord
  - currentStreak: Int32
  - bestStreak: Int32
  - lastUpdated: Date
```

---

## Advanced Features

### Advanced Feature 1 – ScreenTime API
**Frameworks:** `FamilyControls`, `ManagedSettings`, `DeviceActivity`
- Requires device entitlement (cannot be tested on simulator — must use real device)
- `DeviceActivityMonitor` extension runs in a separate process
- Usage data read from `DeviceActivityReport`
- App blocking via `ManagedSettingsStore.shield.applications`

### Advanced Feature 2 – CloudKit
**Framework:** `CloudKit`
- Use `CKContainer.default()` with a public database for leaderboard
- Use private database for user-specific data (friend list, settings backup)
- `CKSubscription` for real-time push updates to leaderboard
- `CKRecord` types: `UserRecord`, `FriendConnection`, `LeaderboardEntry`

### Advanced Feature 3 – WidgetKit
**Framework:** `WidgetKit`
- Widget displays Pluggie's current mood state and health %
- Updates via `WidgetCenter.shared.reloadAllTimelines()`
- Shares data with main app via `App Groups` and `UserDefaults(suiteName:)`
- Supports small and medium widget sizes

---

## Accessibility Requirements (Non-negotiable)

- **VoiceOver:** All interactive elements, Pluggie states, and leaderboard rows must have `.accessibilityLabel` and `.accessibilityValue`
- **Dynamic Type:** All text uses `.font(.body)` style system fonts or `scaledFont` — no hardcoded sizes
- **Reduce Motion:** All Pluggie animations gated behind `@Environment(\.accessibilityReduceMotion)`
- **Colour Contrast:** Meet WCAG AA (4.5:1 for normal text, 3:1 for large text)
- **Haptics:** Use `UIImpactFeedbackGenerator` and `UINotificationFeedbackGenerator` for blocking activation and Pluggie death events

---

## Key Constraints & Gotchas

1. **ScreenTime API requires a real device** — the `FamilyControls` entitlement will not work on the simulator. Build and test on device for all screen time features.
2. **FamilyControls entitlement must be requested** from Apple via the developer portal before building — it is not automatically granted.
3. **DeviceActivityMonitor runs as a separate extension** — it cannot directly call back into the main app. Use App Groups (`UserDefaults` shared suite or a shared Core Data store) to pass data.
4. **CloudKit requires iCloud sign-in** on the device — handle the unauthenticated state gracefully in the leaderboard UI.
5. **Midnight reset** — use `DeviceActivitySchedule` with a daily interval to trigger the reset, and also listen for `Calendar` notifications as a fallback.
6. **Widget data sharing** — main app and widget extension must be in the same App Group to share `UserDefaults` or Core Data.

---

## Coding Conventions

- Use **MVVM** architecture throughout
- All Views are driven by `@ObservableObject` or `@Observable` (iOS 17) ViewModels
- No business logic inside View files
- Use `async/await` for all async operations (no completion handlers)
- All CloudKit calls wrapped in `CloudKitService` — views never call CloudKit directly
- Error handling: use typed `enum AppError: Error` — never silently swallow errors
- Unit test all ViewModel logic; UI tests for critical flows (login, limit setup)
- Commit message format: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`

---

## Development Phases (Suggested Order)

1. **Phase 1 – Foundation:** Xcode project setup, Core Data stack, Auth (Face ID + Sign in with Apple), basic navigation shell
2. **Phase 2 – Pluggie Core:** HomeView, PluggieView with all 6 mood states and animations, mock screen time data
3. **Phase 3 – Real Screen Time:** ScreenTime API integration, DeviceActivityMonitor extension, App Blocking
4. **Phase 4 – Notifications:** Local notification scheduling, near-death warning, midnight reset
5. **Phase 5 – Social:** CloudKit setup, leaderboard, friend connections, death broadcast
6. **Phase 6 – History:** Calendar view, streak logic, Core Data persistence
7. **Phase 7 – Widget:** WidgetKit extension, App Groups data sharing
8. **Phase 8 – Polish:** Accessibility audit, haptics, accessibility labels, Dynamic Type testing, WCAG contrast check

---

## Common Claude Code Commands for This Project

```bash
# Open project
open Unplugged.xcodeproj

# Build from CLI (requires xcode-select)
xcodebuild -scheme Unplugged -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Run tests
xcodebuild test -scheme Unplugged -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Generate Xcode project from SPM (if using tuist or SPM)
swift package generate-xcodeproj
```