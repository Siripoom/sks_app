# Repository Guidelines

## Project Structure & Module Organization

Application code lives in `lib/`. Organize UI by role under `lib/screens/{admin,driver,parent,teacher}` and reusable components under `lib/widgets/`; place cross-cutting constants, localization, and utilities in `lib/core/`. Data models, providers, services, and mock data belong in their matching top-level `lib/` directories. Flutter tests live in `test/`. Image assets are stored in `image/` and declared in `pubspec.yaml`. Platform shells are in `android/`, `ios/`, `web/`, `macos/`, `linux/`, and `windows/`. Firebase configuration, security rules, and indexes are at the repository root; callable/backend code is in `functions/`.

## Build, Test, and Development Commands

- `flutter pub get` installs Dart dependencies.
- `flutter run` launches the app on the selected emulator or device; use `flutter devices` to list targets.
- `flutter analyze` applies the analyzer and `flutter_lints` rules.
- `dart format .` formats Dart source and tests.
- `flutter test` runs the full test suite; pass a path such as `test/parent_schedule_tab_test.dart` for one file.
- `flutter build apk` or `flutter build web` creates production artifacts for a target platform.
- `cd functions && npm install` installs Cloud Functions dependencies. `npm run seed` seeds Firebase and should only be run against an explicitly verified project.

## Coding Style & Naming Conventions

Use Dart's standard two-space formatting and keep `flutter analyze` clean. Name files with `snake_case.dart`, classes and widgets with `UpperCamelCase`, and variables and methods with `lowerCamelCase`. Keep role-specific widgets in their role directory and move genuinely shared UI into `widgets/common`. Prefer small widgets, focused services, and provider-based state over adding unrelated logic to screens.

## Testing Guidelines

Tests use `flutter_test`. Name files `*_test.dart`, group related behavior with `group`, and use `testWidgets` for rendered interactions. Add or update tests for changed navigation, schedules, forms, and role-specific states. There is no configured coverage threshold; prioritize regression coverage and run `flutter test` before opening a pull request.

## Commit & Pull Request Guidelines

Recent commits use short imperative subjects such as `update`, `finish`, and `refactor`. Keep that imperative style, but make the scope explicit (for example, `Fix parent schedule filtering`). Pull requests should summarize user-visible behavior, list validation commands, link the relevant issue, and include screenshots or recordings for UI changes. Call out Firebase rule, index, or configuration changes and any required deployment steps.

## Security & Configuration

Do not commit service-account keys, private environment files, or production credentials. Review `firestore.rules` and `storage.rules` carefully, and test Firebase changes against an emulator or non-production project before deployment.
