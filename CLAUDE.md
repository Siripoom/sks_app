# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**sks** is a Flutter mobile application. It's currently a starter template with basic Material Design setup. The project supports multiple platforms: Android, iOS, macOS, Linux, and Windows.

- **Language**: Dart
- **SDK Requirement**: ^3.8.1
- **Key Dependencies**: Flutter, Cupertino Icons, Flutter Lints

## Build and Run Commands

### Development
- **Run app on default device/emulator**: `flutter run`
- **Run app on specific device**: `flutter run -d <device_id>` (use `flutter devices` to list available devices)
- **Hot reload during development**: Save files in the editor or press `r` in the terminal
- **Full hot restart** (resets state): Press `R` in the terminal

### Testing
- **Run all tests**: `flutter test`
- **Run a specific test file**: `flutter test test/widget_test.dart`
- **Run tests with verbose output**: `flutter test --verbose`

### Analysis and Linting
- **Analyze code for errors and warnings**: `flutter analyze`
- **Format code**: `dart format lib/` (or `dart format .` for entire project)

### Building
- **Build APK (Android)**: `flutter build apk`
- **Build app bundle (Android)**: `flutter build appbundle`
- **Build for web**: `flutter build web`
- **Build for iOS**: `flutter build ios`
- **Build for Windows**: `flutter build windows`
- **Build for macOS**: `flutter build macos`

### Dependency Management
- **Get/update dependencies**: `flutter pub get`
- **Upgrade dependencies**: `flutter pub upgrade`
- **Check for outdated packages**: `flutter pub outdated`
- **Clean build artifacts**: `flutter clean`

## Project Structure

```
lib/
  main.dart           # Application entry point and root widget
test/
  widget_test.dart    # Widget testing example
android/             # Android-specific platform code
ios/                 # iOS-specific platform code
macos/               # macOS-specific platform code
linux/               # Linux-specific platform code
windows/             # Windows-specific platform code
web/                 # Web-specific configuration
pubspec.yaml         # Dart package specification (dependencies, metadata)
pubspec.lock         # Locked dependency versions
analysis_options.yaml # Dart analyzer and linter configuration
```

## Code Style and Analysis

- **Linting Rules**: Uses `package:flutter_lints/flutter.yaml` (recommended lints for Flutter apps)
- **Run `flutter analyze`** before committing to catch style issues and errors
- **Code Formatting**: Use `dart format` to maintain consistent formatting
- Individual lint rules can be disabled per-file using `// ignore_for_file: rule_name` or per-line with `// ignore: rule_name`

## Architecture Notes

- **State Management**: Currently using basic `StatefulWidget` and `setState()`. For larger apps, consider state management solutions like Provider, Riverpod, or Bloc.
- **Main Entry Point**: [lib/main.dart](lib/main.dart) contains the entire app currently (MyApp root widget and MyHomePage stateful widget)
- **Material Design**: App uses Material Design 3 with `ColorScheme.fromSeed()` for theming
- As the app grows, refactor widgets into separate files organized by feature or by widget type

## Common Development Tasks

### Adding New Dependencies
1. Add to `pubspec.yaml` under `dependencies:` or `dev_dependencies:`
2. Run `flutter pub get`
3. Import and use in code

### Creating New Screens/Pages
Create new Dart files in `lib/` following the existing widget pattern:
- For simple UI: Extend `StatelessWidget`
- For interactive UI with state: Extend `StatefulWidget` and create a corresponding `State` class

### Running Tests
- Widget tests belong in `test/` directory
- Use `flutter test` to run the test suite
- Tests use the `flutter_test` package with `testWidgets()` for widget-level testing

## Platform-Specific Development

Each platform has its own directory at the root level:
- **Android** (`android/`): Configure in `android/app/build.gradle` and `AndroidManifest.xml`
- **iOS** (`ios/`): Configure in `ios/Runner.xcodeproj` and `ios/Runner/Info.plist`
- **Web** (`web/`): Static assets and index.html
- **Desktop** (linux/, macos/, windows/): Platform-specific native code and configuration

For platform-specific changes, refer to the Flutter documentation for the target platform.
