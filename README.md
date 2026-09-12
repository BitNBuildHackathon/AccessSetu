# AccessSetu (एक्सेस सेतु)

> **Bridging Accessible Mobility, Spoken Guidance, and Community Confidence**

AccessSetu is an accessibility-first Flutter application designed to empower individuals with diverse physical, sensory, and communication needs. Engineered around real-world accessibility infrastructure in Goa, India, AccessSetu combines high-precision spatial mapping, spoken landmark navigation, offline resilience, digital disability credentials, and smart emergency tools into a unified, privacy-focused experience.

---

## Core Capabilities & Features

### 1. Accessible Map & Spatial Discovery
- **Interactive Geospatial Map**: High-performance OpenStreetMap rendering powered by `flutter_map` and `latlong2`.
- **Multi-Style Map Layers**: Toggle between **Standard OSM**, **Satellite View**, and **Public Transport** layers on demand.
- **3D Perspective Tilt Mode**: Toggle 3D rotation and viewing angles for enhanced streetscape depth perception.
- **Live GPS Tracking ("My Location")**: Instant center-and-follow positioning with real-time accuracy indicators and graceful weak-signal fallbacks.
- **Dynamic Feature Filtering**: Filter places by category (Hospitals, Restaurants, Transit, Pharmacies, etc.), high friendliness threshold (8.5+), and travel mode suitability (Solo vs. Assistant-supported).

### 2. Lazarillo 360° Spoken Audio Guidance
- **Strict Blind-Only Voice Policy**: Text-to-speech landmark guidance, auditory turn prompts, and direction cues are strictly gated to users with the **Blind / Low Vision** persona to preserve sensory comfort for others.
- **"Where Am I?" Spatial Orientation**: One-tap spoken announcements providing current heading, road location, and nearest verified accessible landmark.
- **Lazarillo Landmark Scanning**: Categorized audio radar for rapid discovery of nearby transit, medical facilities, banks, and dining venues.
- **Proximity Hazard Alerts**: Spoken warnings when approaching reported hazards (e.g., broken ramps, construction barriers, missing tactile paving).

### 3. Digital Disability Pass & UDID Medical ID
- **Offline Assistance ID Card**: Clean, high-contrast digital card modeled after official disability credentials for transit conductors, station staff, and officials.
- **UDID Verification & Details**: Displays UDID number, disability category, disability percentage, issuing authority, and validity dates.
- **Smart Document Scanner (OCR)**: On-device optical character recognition via Google ML Kit to scan physical UDID certificates and extract certificate numbers automatically.
- **ICE Medical Card & Emergency QR**: Instant access to blood group, chronic conditions, allergy notes, and quick-scan emergency medical QR code.

### 4. Smart SOS Safety Beacon
- **Accidental-Tap Protection**: 3-second interactive countdown with vibration feedback to cancel false alarms.
- **Audible Siren Beacon**: High-volume repeating siren loop for personal safety and attracting immediate bystander assistance.
- **Voice Help Broadcast**: Synthesized emergency speech loop announcing identity, condition, and distress message.
- **1-Tap ICE Dialer**: Pre-configured emergency contacts (family, doctor, helpline) with direct phone launch and SMS coordinate dispatch.

### 5. Offline Map Package Management
- **Localized Regional Packs**: Download focused offline tile packages rather than bulky global data:
  - **Panaji City Center & Mandovi** (~45 MB)
  - **North Goa Coastal Belt** (~85 MB)
  - **South Goa Heritage & Margao** (~65 MB)
- **Storage & State Controls**: Progress-tracked downloads, local storage accounting, and one-tap deletion.

### 6. Community Verification & Reviews
- **Feature Confirmation (+3 Points)**: Community members confirm or dispute individual accessibility amenities (step-free ramps, wide doorways, braille signage, elevators) with timestamped verification.
- **Structured 1-10 Reviews (+5 Points)**: Multi-dimensional ratings evaluating staff awareness, communication patience, assistance readiness, physical accessibility, and restroom facilities.
- **Community Points & History**: Earn points toward local access advocate badges, complete with an activity feed in the Profile & Community tabs.

---

## Technology Stack

- **Framework**: Flutter 3.x / Dart 3.x (Null-safe)
- **State Management**: `provider` (`AppState` architecture)
- **Map & Geolocation**: `flutter_map`, `latlong2`, `geolocator`
- **Speech & Audio**: `flutter_tts`, `speech_to_text`, `audioplayers`
- **Machine Learning**: `google_mlkit_text_recognition`
- **Hardware Integration**: `image_picker`, `url_launcher`, `qr_flutter`
- **Testing**: `flutter_test` (Unit, Widget, and End-to-End Acceptance Suites)

---

## Project Structure

```text
lib/
├── app/
│   ├── access_map_app.dart         # Root MaterialApp with theme & navigation
│   └── app_state.dart              # Unified central business logic & services coordinator
├── core/
│   ├── services/                   # Service layer (TTS, Exploration, Offline Maps, OCR, Voice)
│   ├── theme/                      # Design tokens, typography, radii, and color palettes
│   └── utils/                      # Visibility policies and mathematical helpers
├── features/
│   ├── contributions/              # Community points, activity logs, and review summaries
│   ├── emergency/                  # Smart SOS beacon, audible alarm, and ICE contacts
│   ├── map/                        # MapScreen, 3D tilt, Discover tab, Lazarillo HUD overlay
│   ├── onboarding/                 # Accessible Welcome onboarding & persona configuration
│   ├── places/                     # Place details, friendly score sheets, and directions
│   ├── profile/                    # Profile management, Disability Pass, and Offline Maps
│   └── reviews/                    # Structured 1-10 review submission flow
└── shared/
    ├── models/                     # Place, UserProfile, Hazard, MapStyle, Category, Feature models
    └── widgets/                    # Accessible buttons, search bar, cards, and bottom sheets
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.6.0` or later)
- Android Studio / VS Code with Flutter extensions
- Android device or emulator with API Level 24+

### Installation & Run

```bash
# Clone the repository
git clone https://github.com/virtuallysarvad/access_app.git
cd access_app

# Fetch dependencies
flutter pub get

# Launch the app on an active device or emulator
flutter run
```

---

## Automated Test Suite

All tests are verified and passing:

```bash
# Run all 29 tests across unit, geo, widget, and acceptance suites
flutter test

# Run static analysis
flutter analyze lib test
```

### Test Coverage Highlights:
- **`test/models_test.dart` (10 tests)**: Accessibility visibility policies, travel mode suitability, and score calculations.
- **`test/geo_test.dart` (8 tests)**: Great-circle Haversine distances, compass bearings, and navigation deviation math.
- **`test/widget_test.dart` (2 tests)**: Onboarding flow and main shell navigation.
- **`test/acceptance_flow_test.dart` (9 tests)**: End-to-end user journeys including onboarding, map search, Discover tab, review submission with points accumulation, helpful votes, and feature confirmations.

---

## Merging with `origin/main`

If you are syncing this feature branch with teammate commits from `origin/main` (e.g. Community Location Submission Wizard and Adaptive Launcher Icons):

```bash
# 1. Ensure you are on this branch
git checkout access-setu

# 2. Fetch and merge upstream changes
git fetch origin
git merge origin/main

# 3. Resolve any conflicts in lib/app/app_state.dart and lib/shared/models/place.dart
# (Keep both Lazarillo/Offline services and their community location submission methods)

# 4. Verify the test suite
flutter test

# 5. Merge back to main and push
git checkout main
git merge access-setu
git push origin main
```

---

## License

This project is developed for the Google Developer Groups (GDG) hackathon. All rights reserved.
