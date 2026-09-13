# AccessApp (एक्सेस ऐप)

> **Community-Powered Accessibility Discovery, Verified Venue Ratings, and Inclusive Mobility — Built for India.**

---

## The Story Behind AccessApp

Every day, millions of people with disabilities, elderly citizens, and parents with strollers face journeys that look trivial on conventional map apps. A venue says *"500 meters — 6 min walk"*.

**What conventional maps don't tell you:**
- Does the clinic entrance have five stairs and no ramp?
- Are interior doorways, elevators, and restrooms wide enough for a wheelchair?
- For someone who is non-verbal or deaf, is the staff patient and trained in alternative communication?
- For someone with low vision, is there tactile paving, braille signage, or high-contrast navigation?
- When boarding public transit or entering government buildings, how do you quickly verify accessibility without making anxious phone calls in advance?

For a wheelchair user or a person with visual impairment in cities like Panaji or Margao, a journey doesn't fail because the destination is missing. It fails because of the **invisible barriers** at the venue and along the way.

We built **AccessApp** to bridge that gap. It is an open-source, lightweight mobile platform that turns OpenStreetMap into a living accessibility companion — guiding users with profile-aware friendly scores, transparent feature breakdowns, crowdsourced 5-step accessibility audits, and voice-assisted discovery.

---

### Download the App
**Direct APK Download:** [Download AccessApp APK (Latest Release)](https://github.com/virtuallysarvad/AccessApp/releases/latest) | [View All GitHub Releases](https://github.com/virtuallysarvad/AccessApp/releases)

---

## What Makes AccessApp Different

### 1. Profile-Aware Accessibility Scoring
- **Personalized Friendly Scores**: Adapts 1–10 venue accessibility scores dynamically based on user-selected needs (Wheelchair, Low Vision, Speech Impairment, Hearing).
- **Dedicated Wheelchair-Friendly Index**: Highlights step-free entrances, automatic doors, ramp slopes, elevator widths, and accessible restrooms.
- **Transparent Score Breakdown**: 1-tap "Why this score?" bottom sheet detailing exact feature weights, sub-category progress bars, and community review statistics.

### 2. Gamified 5-Step Community Venue Audits
- **Comprehensive "Add Location" Flow**: Intuitive wizard covering Map Pin Placement, Basic Info, Tri-State Accessibility Checklist (Yes / No / Partial), and Review.
- **Instant Community Impact Points**: Contributors earn **+10 points** per submitted location, stored reliably offline via `SharedPreferences`.
- **Provisional "New" Badging**: New submissions display provisional tags until peer-confirmed by the community.

### 3. Feature Confirmation & Multi-Dimensional Reviews
- **1-Tap Feature Confirmations**: Community members can verify existing accessibility attributes (e.g., *"Ramp verified 2 days ago"*) to earn **+3 points**.
- **Structured 1–10 Review Criteria**: Detailed ratings evaluating Staff Empathy, Communication Support, Physical Access, Restrooms, and Overall Experience.
- **Community Trust**: Upvoting helpful reviews and reporting inaccurate or outdated venue information.

### 4. Interactive Map & Voice Search (Zero API Cost)
- **Interactive OpenStreetMap**: Custom accessibility map pins, category filters (Clinics, Public Transit, Libraries, Cafes, Government Offices), and High-Friendly toggles via `flutter_map`.
- **Curated Discover Feed**: Quick-access carousels for *"Popular Near You"*, *"Highly Rated by Community"*, and *"Recently Added"*.
- **Hands-Free Voice Search**: Fast voice search powered by `speech_to_text` with local geocoding fallback for low-connectivity environments.
- **Direct Navigation Hand-Off**: "Get Directions" links directly to official Google Maps venue locations with coordinate fallbacks.

---

## Tech Stack

- **Mobile Framework**: Flutter 3.x / Dart 3.x
- **State Management**: Provider (`AppState`)
- **Maps & Spatial**: OpenStreetMap, `flutter_map`, `latlong2` (Zero API licensing cost)
- **Audio & Geolocation**: `speech_to_text`, `geolocator`, `geocoding`
- **Storage & Launchers**: `shared_preferences`, `url_launcher`, `go_router`, `intl`
- **Future & Roadmap Modules**: `flutter_tts`, `flutter_compass`, `google_mlkit_text_recognition`, `qr_flutter`, Google Firebase

---

## Project Architecture

```text
lib/
├── app/
│   ├── access_map_app.dart         # Root application & routing
│   └── app_state.dart              # Global Provider state coordinator
├── core/
│   ├── services/
│   │   ├── geocoding_service.dart       # Search & reverse geocoding
│   │   ├── navigation_service.dart      # Real-world Google Maps & routing launcher
│   │   └── voice_search_service.dart    # Hands-free speech-to-text search
│   ├── theme/
│   │   └── app_theme.dart               # High-contrast accessible design system
│   └── utils/                           # Visibility policy & score calculations
├── features/
│   ├── onboarding/                      # PA Assisted vs Solo & need selection
│   ├── map/                             # MapScreen, DiscoverScreen, main shell
│   ├── places/                          # PlaceDetailsScreen, scoring breakdown
│   ├── reviews/                         # Multi-criteria 1-10 review submission
│   ├── profile/                         # User profile & accessibility preferences
│   ├── contribute/                      # 5-step Add Location flow & survey
│   └── contributions/                   # Leaderboard, badges, & point history
└── shared/
    ├── models/                          # Place, Feature, Need, Review, Profile models
    └── widgets/                         # Search bar, chips, score badges & UI kit
```

---

## Future Scope and Roadmap

### 1. Spoken Turn Guidance & Live Azimuth Compass (Hands-Free)
- **OSRM Pedestrian Routing**: Integrate real street and sidewalk routing that prioritizes curb cuts, footpaths, and ramps while routing around stairs and highways.
- **15-Second Stationary Voice Prompts**: When stopped or hesitating, announces precise relative turn angles and distances (*"Turn 19 degrees right, then walk 45 meters"*).
- **Live Azimuth Compass HUD**: Compass dial overlay showing relative turn angle (`R19°`, `L25°`, `0°`) directly toward the next walking maneuver.
- **"Where Am I?" Voice Readout**: 1-tap spoken readout of current street name, nearby cross-streets, and closest landmark.

### 2. Offline Digital Disability Pass (UDID) & Camera OCR
- **On-Device UDID Pass**: Secure local storage for Unique Disability ID credentials with an offline scannable QR code for transit staff and bus conductors.
- **Built-In Camera OCR Scanner**: Uses Google ML Kit text recognition to scan and extract details from physical UDID cards directly via smartphone camera.

### 3. Emergency SOS Beacon & ICE Medical Profile
- **Accidental-Tap Guard**: 3-second hold protection to prevent accidental activations in crowded pockets or bags.
- **Audible Siren & Spoken Loop**: High-volume repeating siren and looping spoken distress message announcing the user's need for assistance and GPS coordinates.
- **1-Tap ICE Dialer & Medical ID**: Instant emergency calling to In-Case-of-Emergency contacts, with quick-view medical data (blood group, emergency contacts, conditions).

### 4. Dynamic Community Sidewalk Hazard Alerts
- **1-Tap Hazard Reporting**: Crowdsourced reporting for waterlogging, potholes, broken sidewalks, or blocked ramps with instant **+15 community impact points**.
- **Temporal Expiry**: Real-time obstacle warnings with automatic expiry and community confirmation voting.

### 5. Offline Regional Map Tile Downloads
- **Offline Map Service**: Download and cache regional OpenStreetMap tile packs locally (`offline_map_service`), allowing full map browsing and navigation in zero-connectivity or remote areas.

### 6. Haptic Vibration Feedback for Low-Vision Navigation
- **Directional Vibration Pulses**: Distinct haptic feedback patterns to notify users of upcoming turns, intersection crossings, and nearby hazard alerts hands-free without looking at the screen.

### 7. Edge AI & Computer Vision Obstacle Detection
- **Camera-Based Hazard Detection**: Lightweight, on-device Edge AI vision models (YOLO / MobileNet) that inspect forward-facing camera feeds to detect sidewalk drop-offs, open drains, potholes, and stairs in real time with audio alerts.

### 8. Public Transit Fleet Integration (GTFS)
- **Live Accessible Bus Tracking**: Partner with public transit operators (such as Goa's Kadamba KTCL) to ingest live GTFS feeds, highlighting wheelchair-accessible low-floor buses, boarding ramps, and automated stop announcements.

### 9. Multilingual Voice Guidance
- **Regional Indian Languages**: Expand spoken navigation and voice search beyond English to regional languages including Konkani, Hindi, Marathi, Tamil, and Kannada.

### 10. "Saathi" Volunteer Companion Dispatch
- **On-Demand Companion Network**: Connect individuals requiring on-site physical guidance with vetted local volunteers and NGO partners for last-mile assistance.

### 11. Firebase Cloud Sync & Government Portal Integration (Swavlamban API)
- **Cloud Synchronization**: Migrate local cache stores to Firebase Cloud Firestore for real-time live synchronization across thousands of active volunteers nationwide.
- **Swavlamban Card API**: Direct integration with the Ministry of Social Justice and Empowerment for automated, tamper-proof verification of disability certificates.

---

## Getting Started

### Prerequisites
- Flutter SDK (3.24+ recommended)
- Android SDK (API 29+) or an Android device connected via USB

### Run Locally
```bash
# 1. Clone repository
git clone https://github.com/virtuallysarvad/access_app.git
cd access_app

# 2. Install dependencies
flutter pub get

# 3. Launch on connected device
flutter run
```

### Run Tests & Analysis
```bash
# Run all 40 unit, acceptance, and flow tests
flutter test

# Static analysis
flutter analyze
```

### Automated GitHub Release (CI/CD)
To compile and publish a production APK automatically via GitHub Actions:
```bash
git tag v1.0.0
git push origin main --tags
```
The workflow will compile and publish the single release APK directly on the GitHub Releases page.

### Build Production APK Locally
```bash
# Build Android debug APK
flutter build apk --debug

# Or use Gradle wrapper directly
cd android && ./gradlew assembleDebug
```

---

## Team
Built for accessible mobility at **Bit & Build 2026**.

