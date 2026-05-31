# SimpleClock

![Platform](https://img.shields.io/badge/Platform-iOS-blue.svg)
![iOS](https://img.shields.io/badge/iOS-15.5%2B-lightgray.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
A powerful and intuitive iOS clock and timer application built with SwiftUI (Swift 5.9). SimpleClock provides a rich set of features including customizable timers, background audio, speech recognition, and seamless UI/UX design.

## Features

- **Intuitive UI**: Built entirely with SwiftUI, featuring distinct views for Timer Picker, Digital Clock, and Home.
- **Advanced Timer Logic**: Robust timer scheduling, background execution, and reminder cadence management.
- **Audio & Speech Integration**: Utilizes speech-to-timer flows, continuous background audio, and microphone support.
- **Robust Background Modes**: Timers and reminders continue to function seamlessly in the background with `BGTask` integration.

## Project Structure

- `SimpleClock/Views`: Renders the UI (`HomeView`, `TimerPickerView`, `DigitalClockView`).
- `SimpleClock/ViewModels`: Wraps timer logic and manages application state.
- `SimpleClock/Models`: Stores value types like `TimerSettings`.
- `SimpleClock/Utils`: Centralizes services (`AudioSessionManager`, `ContinuousAudioPlayer`, permissions, and speech).
- `SimpleClockTests/` & `SimpleClockUITests/`: Comprehensive unit logic testing and UI flow testing.

## Requirements

- iOS 17.5+
- Xcode 15+ (Swift 5.9)

## Getting Started

1. Clone the repository.
2. Open the project in Xcode:
   ```bash
   xed SimpleClock.xcodeproj
   ```
3. Build the project:
   ```bash
   xcodebuild -project SimpleClock.xcodeproj -scheme SimpleClock -configuration Debug build
   ```

## Testing

Run tests to ensure logic scheduling, reminder cadence, and UI flows are working as expected:

```bash
xcodebuild test -project SimpleClock.xcodeproj -scheme SimpleClock -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5'
```

## Permissions

SimpleClock requests notifications, speech, microphone, and background audio/refresh tasks. Ensure to grant permissions when prompted for the app to function properly.

## License

See the `LICENSE` file for more details.
