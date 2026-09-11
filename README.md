# AccessMap

AccessMap is an accessibility-first community map for discovering places that are welcoming and usable for people with different accessibility needs.

The MVP starts directly with onboarding, stores a mock user profile, and runs on demo data so it can be shown reliably without authentication, backend setup, or API keys.

## Features

- PA Assisted and Solo onboarding modes
- Accessibility need selection for Can't Talk, Can't Speak, and Can't See
- Extensible accessibility profile model, including wheelchair and physical accessibility needs
- Interactive OpenStreetMap map using `flutter_map`
- Accessibility-focused search, category filters, and high-friendly filtering
- Tappable place markers with preview cards (score, distance, confirmations)
- "Get Directions" opens the venue's real Google Maps entry (each demo place carries an actual Google Maps link; falls back to coordinate-based routing)
- Full place detail pages with Friendly Score, profile-aware Wheelchair-Friendly score, category scores with progress bars, score explanation sheets, tags, confirmations, and reviews
- Tap-any-score explanation ("Based on: 43 community reviews ...")
- Feature-level community confirmation (+3 points) with last-confirmed dates
- Structured 1-10 review submission across staff, communication, assistance, physical access, facilities, and overall experience
- Helpful votes, report review, community points, and contribution history
- Discover screen with category chips, Popular Near You, and Highly Rated by Community
- Profile editor with a demo wheelchair profile toggle for showing personalization behavior

## Tech Stack

- Flutter and Dart
- Provider for state management
- `flutter_map` with OpenStreetMap demo tiles
- `speech_to_text` behind a `VoiceSearchService` abstraction
- `url_launcher` behind a `NavigationService`
- Mock repositories for places and reviews

## Running the Project

```bash
flutter pub get
flutter run
```

Run tests with:

```bash
flutter test          # 24 tests: unit + acceptance flow
flutter analyze       # static analysis
```

Build and install the Android APK:

```bash
flutter build apk --debug   # or: cd android && ./gradlew assembleDebug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

If `flutter build apk` fails with an NDK version error on your machine, use the Gradle wrapper directly (`cd android && ./gradlew assembleDebug`) — both produce the same APK.

## Environment Variables and API Keys

No API key is required for the MVP demo mode.

The current map uses OpenStreetMap tiles through `flutter_map`. If the app later moves to Google Maps, Mapbox, or another provider, add the provider key through platform configuration or environment-specific files. Do not hard-code keys in source.

## Architecture

```text
lib/
  app/                  App root and Provider state controller
  core/                 Theme, services, visibility policy
  features/             Onboarding, map, places, reviews, profile, contributions
  shared/models/        User, place, review, feature, category models
  shared/widgets/       Reusable UI components
```

The UI talks to `AppState`, which calls repository/service abstractions. `MockPlaceRepository` is the current backend substitute and can be replaced by API-backed repositories later.

## Known Limitations

- Place data and reviews are mock demo data.
- Location permission is represented as a demo action; manual search remains usable.
- Voice search depends on platform speech availability and falls back to a clear message when unavailable.
- Photo upload is modeled as a future backend-backed action.
- Accessibility-aware routing is intentionally not implemented in this MVP.

## Acceptance Checklist

- Launches into onboarding without sign-up
- Select PA Assisted or Solo
- Select an accessibility need
- Opens a map with multiple accessibility-focused places
- Search and select places
- View Friendly Score and relevant accessibility information
- Read contextual community reviews
- Submit a structured review and earn points
- Open profile and contributions
- Add wheelchair need in profile and see Wheelchair-Friendly scores appear
