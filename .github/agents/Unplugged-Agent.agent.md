---
description: Describe what this custom agent does and when to use it.
tools: ['create_file', 'insert_edit_into_file', 'fetch_webpage', 'file_search', 'grep_search', 'get_errors', 'get_terminal_output', 'list_dir', 'manage_todo_list', 'read_file', 'replace_string_in_file', 'run_subagent', 'run_in_terminal', 'validate_cves']
model: GPT-5.2-Codex (copilot)
handoffs:
  - label: Start Implementation
    agent: implementation
    prompt: Now implement the plan outlined above.
    send: true
---
# Unplugged – GitHub Copilot Agent Instructions (iOS)

**Current Date (YYYY-MM-DD):** 2026-05-05  
**Current user login:** KaSaNaa

This file is intended for **GitHub Copilot (coding agent)** to read at the start of a session.
It contains the project specification, architecture decisions, and development guidelines for the
**Unplugged** iOS app.

> **UI Source of Truth:** All screen designs are exported as PNGs in `docs/designs/`.
> Always open and match the relevant PNG **pixel-closely** before implementing any screen.

---

## App Overview

**Unplugged** is a gamified screen time management app for iOS. It turns daily phone usage into
a virtual pet experience. Users set a personal daily screen time limit, which becomes the health
of a virtual pet called **Pluggie**. As screen time accumulates, Pluggie's health drops in real
time. If the limit is exceeded, Pluggie dies and all connected friends are notified via push
notification.

**Core loop:** Keep Pluggie alive → stay under your limit → don’t be the one on the leaderboard
with a dead pet.

---

## Design References (Figma Exports)

Designs live in: `docs/designs/`

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

> If filenames differ, either rename PNGs to match this table or update the table.

---

## Design System Extraction (when needed)

If you need tokens, extract them from the PNG exports and consolidate into a Swift constants file:

- Colour palette (background/surface/accent/text as hex)
- Typography (font names, sizes, weights for headings/body/captions)
- Corner radii
- Spacing/padding patterns
- Recurring components (cards/buttons/chips)

Output format: `DesignSystem.swift` with constants.

---

## Tech Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI
- **Minimum target:** iOS 17.0
- **Local storage:** Core Data
- **Screen Time:** ScreenTime API (`ManagedSettings`, `FamilyControls`, `DeviceActivity`)
- **Cloud/social:** CloudKit (iCloud)
- **Notifications:** UserNotifications
- **Auth:** AuthenticationServices (Sign in with Apple) + LocalAuthentication (Face ID / Touch ID)
- **Widget:** WidgetKit
- **Animations:** SwiftUI animations + Lottie (if needed)

---

## Project Structure

```
Unplugged/
├── CLAUDE.md
├── Unplugged.xcodeproj
├── Unplugged/
│   ├── App/
│   │   ├── UnpluggedApp.swift
│   │   └── AppDelegate.swift
│   ├── Models/
│   │   ├── PluggieState.swift
│   │   ├── UserProfile.swift
│   │   ├── FriendEntry.swift
│   │   └── DayRecord.swift
│   ├── ViewModels/
│   │   ├── PluggieViewModel.swift
│   │   ├── LeaderboardViewModel.swift
│   │   ├── HistoryViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views/
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── PluggieView.swift
│   │   ├── Leaderboard/
│   │   │   └── LeaderboardView.swift
│   │   ├── History/
│   │   │   ├── HistoryView.swift
│   │   │   └── DayDetailSheet.swift
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   └── AppBlockingView.swift
│   │   └── Auth/
│   │       ├── LoginView.swift
│   │       └── SignUpView.swift
│   ├── Services/
│   │   ├── ScreenTimeService.swift
│   │   ├── CloudKitService.swift
│   │   ├── NotificationService.swift
│   │   └── BiometricService.swift
│   ├── Persistence/
│   │   ├── CoreDataStack.swift
│   │   └── Unplugged.xcdatamodeld
│   └── Resources/
│       ├── Assets.xcassets
│       └── Localizable.strings
├── UnpluggedWidget/
│   ├── UnpluggedWidget.swift
│   └── WidgetEntry.swift
└── UnpluggedTests/
```

---

## Feature Specifications

### 1) Authentication & Security
- Sign Up / Login with **Sign in with Apple** (preferred) or email
- Biometric auth via `LocalAuthentication` (Face ID / Touch ID)
- Biometric lock on Settings: prevent changing daily limit without auth
- Store credentials securely in **Keychain**

### 2) Push Notifications & Reminders
- User sets reminder interval (30 min, 1 hr, etc.)
- Local notification at each interval of accumulated screen-time usage
- Near-death warning at **90%** of daily limit
- Death broadcast to CloudKit-connected friends at **100%**
- Local notifications: `UNUserNotificationCenter`
- Friend death broadcast: CloudKit push/subscriptions

### 3) Pluggie Virtual Pet (Home)
Mood changes by **percent used** (usage/limit):

| Health % used | State | Visual |
|---|---|---|
| 0–25% | Thriving | Bright green, bouncing, sparkles, happy eyes |
| 25–50% | Content | Calm, gentle sway, small smile |
| 50–75% | Worried | Yellow tint, sweat drop, nervous fidget |
| 75–90% | Struggling | Orange tint, tired eyes, visible cracks |
| 90–99% | Critical | Red tint, dizzy spiral eyes, flickering, alarm |
| 100% | Dead | Grey, X eyes, cracks, lying flat, halo, ghost puff |

- Resets at midnight daily
- Respect Reduce Motion: gate animations behind `@Environment(\.accessibilityReduceMotion)`

### 4) Daily Limit & Tracking
- Daily limit set during onboarding and in Settings
- Health % used = `currentUsage / dailyLimit * 100`
- Use `DeviceActivityMonitor`, `ManagedSettings`, `FamilyControls`
- Auto-reset at midnight using `DeviceActivitySchedule`
- Requires entitlement: `com.apple.developer.family-controls`

### 5) App Blocking
- Select apps to block via `FamilyActivityPicker`
- Block with `ManagedSettingsStore` shields
- While blocking is active, **freeze health timer** (usage during block excluded)
- Show a clear “frozen” state indicator on Home

### 6) Social Leaderboard
- Rank connected friends by current health %
- Top 3 in podium layout
- Dead entries greyed + skull/death badge
- CloudKit public DB for leaderboard
- CloudKit subscriptions for real-time updates
- Handle “not signed into iCloud” gracefully

### 7) History & Streak
- Monthly calendar grid (custom SwiftUI)
- Each day cell shows Pluggie icon: green (survived) / grey (failed)
- Tap day → bottom sheet detail
- Current streak + Best streak
- Source: Core Data `DayRecord`

### 8) Core Data Model
Entities:

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

## Advanced Notes / Gotchas (Read Before Implementing)

1. **ScreenTime API needs a real device**; simulator won’t work for `FamilyControls`.
2. The **FamilyControls entitlement must be requested** in the Apple Developer portal.
3. `DeviceActivityMonitor` runs in a separate extension process. Use **App Groups** shared storage
   (`UserDefaults(suiteName:)` or shared Core Data store) for communication.
4. CloudKit requires iCloud sign-in; show an unauthenticated/disabled state if unavailable.
5. Midnight reset: use `DeviceActivitySchedule`, and also listen for calendar/day-boundary fallback.
6. Widget data: main app + widget must share an **App Group**.

---

## Accessibility Requirements (Non‑negotiable)

- **VoiceOver:** every interactive element + Pluggie states + leaderboard rows must have
  `.accessibilityLabel` and `.accessibilityValue`
- **Dynamic Type:** use system fonts (`.font(.body)` etc.) / scaling; no fixed sizes
- **Reduce Motion:** gate animations behind `@Environment(\.accessibilityReduceMotion)`
- **Contrast:** WCAG AA (4.5:1 normal, 3:1 large)
- **Haptics:** use `UIImpactFeedbackGenerator` and `UINotificationFeedbackGenerator`
  for blocking activation and death events

---

## Architecture & Coding Conventions

- **MVVM** throughout
- Views are driven by `@ObservableObject` or `@Observable` (iOS 17)
- No business logic in Views
- `async/await` for async work (no completion handlers)
- CloudKit calls must be wrapped in `CloudKitService` (Views never call CloudKit directly)
- Use a typed error enum `AppError: Error` (do not silently swallow errors)
- Unit test ViewModel logic; UI tests for critical flows (login, limit setup)
- Commit messages: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`

---

## Suggested Development Phases

1. Foundation: project setup, Core Data, Auth, navigation shell
2. Pluggie core: HomeView, PluggieView, mood states + animations, mock usage
3. Real screen time: ScreenTime API integration, DeviceActivityMonitor extension, blocking
4. Notifications: local scheduling, near-death, midnight reset
5. Social: CloudKit, leaderboard, friends, death broadcast
6. History: calendar view, streak logic, Core Data
7. Widget: WidgetKit + App Groups sharing
8. Polish: accessibility audit, haptics, Dynamic Type/VoiceOver/contrast

---

## Common Commands

```bash
open Unplugged.xcodeproj

xcodebuild -scheme Unplugged -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

xcodebuild test -scheme Unplugged -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```
