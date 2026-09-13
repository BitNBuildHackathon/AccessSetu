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

### 2. Multi-Modal Navigation & Spoken Turn Guidance (OSRM)
- **Open-Source Pedestrian & Vehicle Routing**: Direct integration with OSRM (Open Source Routing Machine) for real street navigation:
  - 🚶 **Walk**: Sidewalks, pedestrian crossings, footpaths, and step-free routes.
  - 🚴 **Bike**: Cycling corridors and bike-friendly roads.
  - 🚗 **Car**: Vehicular driving routes.
- **15-Second Periodic Voice Guidance**: When navigating, if stationary or paused, spoken prompts announce exact turn degrees and remaining distance (e.g., *"Turn 19 degrees right, then walk 45 meters"*).
- **Gyroscope & Compass Dial**: Real-time compass heading with live relative angle badge (`R19°`, `L25°`, `0°`) pointing directly toward the next maneuver.
- **Dynamic Travel Time & Speed**: ETA adjusts in real-time based on live GPS walking/driving speed.
- **"Where Am I?" Spatial Orientation**: Spoken announcement providing heading, street location, and nearest verified landmark.
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

### 6. Community Place Submission & Reviews
- **5-Step Location Submission Wizard**: Add missing places with interactive map pin picker, reverse geocoding, duplicate detection, tri-state accessibility survey, photo placeholders, and +10 Community Points.
- **Local Persistence**: Community submissions persist offline via SharedPreferences alongside seed demo places.
- **Feature Confirmation (+3 Points)**: Verify individual accessibility features (step-free ramps, wide doors, braille, elevators).
- **Structured 1-10 Reviews (+5 Points)**: Multi-dimensional ratings across staff, communication, assistance, physical access, and restrooms.
- **Community Points & History**: Earn points toward local access advocate badges with activity tracking.

---

## Tech Stack

- **Framework**: Flutter 3.x / Dart 3.x
- **State Management**: `provider` (`AppState`)
- **Map & Geolocation**: `flutter_map`, `latlong2`, `geolocator`, `geocoding` (`GeocodingService`)
- **Routing Engine**: OSRM API (Walk `/foot`, Bike `/bike`, Car `/driving`)
- **Speech & Audio**: `flutter_tts`, `speech_to_text`, `audioplayers`
- **Machine Learning**: `google_mlkit_text_recognition`
- **Hardware & Sensors**: `flutter_compass`, `vibration`, `image_picker`, `qr_flutter`
- **CI/CD**: GitHub Actions automated release pipeline

---

## Project Structure

```text
.github/
└── workflows/
    └── release.yml                 # Automated APK release pipeline
lib/
├── app/
│   ├── access_map_app.dart         # Root MaterialApp
│   └── app_state.dart              # Main state coordinator
├── core/
│   ├── services/                   # OSRM routing, TTS, exploration, offline maps, OCR
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

### Build Release APK

```bash
flutter build apk --release
```

Output APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

### Automated GitHub Release (CI/CD)

Tag any commit with `v*` to automatically trigger the GitHub Actions release workflow:

```bash
git tag v1.0.0
git push origin access-setu --tags
```

The workflow will compile a production release APK and publish it directly to your repository's **Releases** page as `AccessSetu-release.apk`.
