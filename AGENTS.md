# Repository Guidelines

## Project Structure & Module Organization
- `SimpleClock/` hosts the SwiftUI app: `Views/` renders UI (HomeView, TimerPickerView, DigitalClockView), `ViewModels/` wraps timer logic, `Models/` stores value types (`TimerSettings`), and `Utils/` centralizes services (audio session, speech, permissions, purchase stubs).
- `Assets.xcassets`, `Info.plist`, and `SimpleClock.entitlements` configure theming, strings, and background modes; edit them together whenever you add BGTask IDs or permission descriptions.
- Tests sit beside the app: `SimpleClockTests/` covers logic via the `Testing` package, and `SimpleClockUITests/` adds XCTest-based smoke and launch checks.

## Build, Test, and Development Commands
- `xed SimpleClock.xcodeproj` — open the SimpleClock scheme in Xcode.
- `xcodebuild -project SimpleClock.xcodeproj -scheme SimpleClock -configuration Debug build` — reproducible debug build for CI or local verification.
- `xcodebuild test -project SimpleClock.xcodeproj -scheme SimpleClock -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5'` — run unit + UI tests headlessly; update the destination to match your simulator.

## Coding Style & Naming Conventions
- Use Swift 5.9 defaults: four-space indentation, braces on the same line, and descriptive camelCase members (`timeAdjustmentOffset`, `setupDeviceStateObservers`).
- SwiftUI view files stay PascalCase and mirror their type name; helpers in `Utils/` should become singletons only when they manage global resources (`AudioSessionManager.shared`, `ContinuousAudioPlayer.shared`).
- Keep side effects in `ViewModels/` so `Views/` stay declarative; comment only when clarifying background work or permission flows.

## Testing Guidelines
- Logic tests belong in `SimpleClockTests`—exercise scheduling, reminder cadence, design system math, and user defaults using `#expect` inside `test<Action>_<Expectation>()` functions.
- UI flows (launch timing, VoiceOver state, notification prompts) stay under `SimpleClockUITests`; any change touching `TimerViewModel`, permissions, or audio must add a unit test, and UI-impacting work needs an updated XCUI test.

## Commit & Pull Request Guidelines
- Follow the existing Git history (`feat: restore theme chooser`, `fix: reminder interval clamp`, `chore: clean assets`): lowercase type, colon, concise (~70 char) summary, and reference issue numbers when applicable.
- Pull requests must describe the change, call out user-facing or accessibility updates, list commands/tests executed (`xcodebuild test`, devices used), and attach screenshots or short videos for UI shifts.

## Permissions & Background Modes
- The app requests notifications, speech, microphone, and background audio/refresh tasks (see `SimpleClockApp.requestAllPermissions()` and the entitlements file). Keep `Info.plist` usage descriptions, BGTask identifiers, and entitlements synchronized whenever you add capabilities.
- After editing permissions or entitlements, re-run notification delivery, speech-to-timer flows, and background audio on both simulator and device to ensure timers keep firing.
