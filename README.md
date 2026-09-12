# AccessSetu (एक्सेस सेतु)

> **Bridging Accessible Mobility, Spoken Guidance, and Community Confidence**

AccessSetu is an accessibility-first Flutter application designed to empower individuals with physical, sensory, and communication needs. Engineered around real-world accessibility infrastructure in Goa, India, AccessSetu combines spatial mapping, spoken landmark navigation, offline resilience, digital disability credentials, and emergency tools into a unified, privacy-focused mobile experience.

---

## Core Features

### 1. Accessible Map & Spatial Discovery
- **Interactive Geospatial Map**: OpenStreetMap rendering powered by `flutter_map` and `latlong2`.
- **Multi-Style Map Layers**: Toggle between Standard OSM, Satellite View, and Public Transport layers.
- **3D Perspective Tilt Mode**: Perspective tilt and rotation for depth perception and street orientation.
- **Live GPS Tracking**: One-tap center-and-follow positioning with real-time accuracy and weak-signal fallbacks.
- **Accessibility Filtering**: Filter places by category (Hospitals, Restaurants, Transit, Pharmacies), high friendliness threshold (8.5+), and travel mode suitability.

### 2. Spoken Audio Navigation & Landmark Guidance
- **Strict Blind-Only Voice Policy**: Spoken cues, auditory turn prompts, and landmark announcements are strictly gated to the **Blind / Low Vision** persona.
- **"Where Am I?" Spatial Orientation**: Spoken announcement providing heading, street location, and nearest verified landmark.
- **Audio Landmark Scanning**: Rapid category exploration for nearby transit, medical facilities, banks, and dining venues.
- **Proximity Hazard Alerts**: Audio warnings when approaching reported obstacles (broken ramps, construction, missing tactile paving).

### 3. Digital Disability Pass & UDID Medical ID
- **Offline Assistance ID Card**: High-contrast digital ID modeled after official credentials for transit conductors and staff.
- **UDID Verification & Details**: Displays UDID number, disability category, percentage, issuing authority, and dates.
- **Smart Document Scanner (OCR)**: On-device optical character recognition via Google ML Kit to extract UDID certificate numbers from physical documents.
- **ICE Medical Card & Emergency QR**: Instant access to blood group, conditions, allergy notes, and emergency medical QR code.

### 4. Smart SOS Safety Beacon
- **Accidental-Tap Protection**: 3-second interactive countdown with cancel button and vibration feedback.
- **Audible Siren Beacon**: High-volume repeating siren loop for immediate personal safety and bystander alerting.
- **Voice Help Broadcast**: Synthesized emergency speech loop announcing identity and distress message.
- **1-Tap ICE Dialer**: Pre-configured emergency contacts (family, doctor, helpline) with direct phone and SMS dispatch.

### 5. Offline Map Package Management
- **Regional Offline Packs**: Download focused offline tile packages:
  - **Panaji City Center & Mandovi** (~45 MB)
  - **North Goa Coastal Belt** (~85 MB)
  - **South Goa Heritage & Margao** (~65 MB)
- **Storage Management**: Progress-tracked downloads, local storage accounting, and one-tap deletion.

### 6. Community Verification & Reviews
- **Feature Confirmation (+3 Points)**: Verify individual accessibility features (step-free ramps, wide doors, braille, elevators).
- **Structured 1-10 Reviews (+5 Points)**: Multi-dimensional ratings across staff, communication, assistance, physical access, and restrooms.
- **Community Points & History**: Earn points toward local access advocate badges with activity tracking.

---

## Tech Stack

- **Framework**: Flutter 3.x / Dart 3.x
- **State Management**: `provider` (`AppState`)
- **Map & Geolocation**: `flutter_map`, `latlong2`, `geolocator`
- **Speech & Audio**: `flutter_tts`, `speech_to_text`, `audioplayers`
- **Machine Learning**: `google_mlkit_text_recognition`
- **Hardware & Utilities**: `image_picker`, `url_launcher`, `qr_flutter`
- **Testing**: `flutter_test`

---

## Project Structure

```text
lib/
├── app/
│   ├── access_map_app.dart         # Root MaterialApp
│   └── app_state.dart              # Main state coordinator
├── core/
│   ├── services/                   # TTS, exploration, offline maps, OCR, voice services
│   ├── theme/                      # App theme, typography, colors
│   └── utils/                      # Visibility policies and math helpers
├── features/
│   ├── contributions/              # Points, activity history, and review summaries
│   ├── emergency/                  # SOS beacon, siren, and ICE contacts
│   ├── map/                        # MapScreen, 3D tilt, Discover tab, navigation HUD
│   ├── onboarding/                 # Welcome onboarding & persona selection
│   ├── places/                     # Place details, friendly score sheets, directions
│   ├── profile/                    # Profile settings, Disability Pass, Offline Maps
│   └── reviews/                    # Structured 1-10 review submission
└── shared/
    ├── models/                     # Place, UserProfile, Hazard, MapStyle models
    └── widgets/                    # Buttons, search bar, cards, bottom sheets
```

---

## Quickstart

### Run Locally

```bash
flutter pub get
flutter run
```

### Run Tests

```bash
flutter test
flutter analyze lib test
```

---

## Merging with `main`

To sync and merge this branch into `main`:

```bash
git checkout access-setu
git fetch origin
git merge origin/main
flutter test
git checkout main
git merge access-setu
git push origin main
```
