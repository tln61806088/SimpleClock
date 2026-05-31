# SimpleClock

![Platform](https://img.shields.io/badge/Platform-iOS-blue.svg)
![iOS](https://img.shields.io/badge/iOS-15.5%2B-lightgray.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
SimpleClock is an accessible iOS clock and timer application specifically designed for the **blind and visually impaired community** (or anyone who finds standard alarm clocks difficult to use). Built with SwiftUI, it features complete VoiceOver support and can be entirely controlled via **voice commands** to set, start, stop, and modify timers.

## Features

- **Accessibility First**: Designed from the ground up for visually impaired users with complete VoiceOver support, comprehensive TTS broadcasting, and haptic feedback.
- **Smart Voice Control**: Fully controllable via voice commands. Users can seamlessly set alarms, turn them on/off, and modify timer durations using natural speech.
- **Intuitive UI**: Built entirely with SwiftUI, offering 31 dynamic themes, automatic dark mode support, and adaptive layouts supporting all devices from iPhone 6s to iPhone 16.
- **Advanced Timer Logic & Background Execution**: Robust timer scheduling that continues to function seamlessly in the background with `BGTask` and continuous audio session integration.

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

## Contributing 💖

SimpleClock is an open-source public welfare project. We strongly believe in making technology accessible to everyone. We welcome and encourage developers from all over the world to join us in improving this app!

We are particularly looking for contributions in:
- **Multi-language Support**: Expanding voice recognition and TTS commands to support more languages.
- **Accessibility Enhancements**: Further optimizing the VoiceOver and voice-control experience.

Feel free to open issues, submit pull requests, or share your ideas to help the visually impaired community globally.

## License

See the `LICENSE` file for more details.
