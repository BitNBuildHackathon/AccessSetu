import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:vibration/vibration.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:access_map/core/services/tts_service.dart';
import 'package:access_map/core/services/osrm_routing_service.dart';
import 'package:access_map/features/map/data/mock_place_repository.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/hazard_report.dart';

class ExplorationService extends ChangeNotifier {
  final TTSService _ttsService;
  final PlaceRepository _placeRepository;

  void Function(int points, String description)? onContributionEarned;

  final List<HazardReport> _hazards = [
    HazardReport(
      id: 'hazard_panaji_ramp',
      category: HazardCategory.rampBlocked,
      description: 'Entrance ramp obstructed by construction debris',
      latitude: 15.4925,
      longitude: 73.8290,
      reportedAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    HazardReport(
      id: 'hazard_gmc_lift',
      category: HazardCategory.liftBroken,
      description: 'Main wing elevator under maintenance',
      latitude: 15.4645,
      longitude: 73.8550,
      reportedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    HazardReport(
      id: 'hazard_margao_stairs',
      category: HazardCategory.unexpectedStairs,
      description: 'Side pathway has 4 unexpected steps without ramp',
      latitude: 15.2750,
      longitude: 73.9600,
      reportedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    HazardReport(
      id: 'hazard_davorlim_water',
      category: HazardCategory.waterlogging,
      description: 'Deep puddle & slippery sidewalk near crossing',
      latitude: 15.2850,
      longitude: 73.9700,
      reportedAt: DateTime.now().subtract(const Duration(minutes: 40)),
    ),
  ];

  List<HazardReport> get activeHazards => _hazards.where((h) => !h.isResolved).toList();

  /// All hazards including resolved (for showing history on map)
  List<HazardReport> get allHazards => List.unmodifiable(_hazards);

  HazardReport? _nearbyHazard;
  HazardReport? get nearbyHazard => _nearbyHazard;

  final Set<String> _announcedHazardIds = {};

  ExplorationService(this._ttsService, this._placeRepository);

  List<NavigationStep> _navigationSteps = [];
  List<NavigationStep> get navigationSteps => _navigationSteps;

  int _currentStepIndex = 0;
  int get currentStepIndex => _currentStepIndex;

  double _simulatedWalkDistance = 0;

  NavigationStep? get currentStep {
    if (_navigationSteps.isEmpty) return null;
    if (_currentStepIndex >= _navigationSteps.length) {
      return _navigationSteps.last;
    }
    return _navigationSteps[_currentStepIndex];
  }

  double get currentStepRemainingMeters {
    if (currentStep == null) return 0;
    return currentStep!.distanceMeters;
  }

  List<LatLng> _routePolyline = [];

  /// Dynamic walking route polyline from user position to active destination
  List<LatLng> get routePolylinePoints {
    if (_activeDestination == null) return [];
    if (_routePolyline.isNotEmpty) return _routePolyline;
    final start = LatLng(currentEffectiveLat, currentEffectiveLng);
    final end = LatLng(_activeDestination!.latitude, _activeDestination!.longitude);
    return [start, end];
  }

  bool _isActive = false;
  bool get isActive => _isActive;

  bool _isRouting = false;
  bool get isRouting => _isRouting;

  Timer? _periodicGuidanceTimer;
  LatLng? _lastGuidancePosition;

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  double? _currentHeading;
  double? get currentHeading => _currentHeading;

  OsrmProfile _currentRoutingProfile = OsrmProfile.walk;
  OsrmProfile get currentRoutingProfile => _currentRoutingProfile;

  void setRoutingProfile(OsrmProfile profile) {
    if (_currentRoutingProfile == profile) return;
    _currentRoutingProfile = profile;
    notifyListeners();

    if (_activeDestination != null) {
      final startLat = currentEffectiveLat;
      final startLng = currentEffectiveLng;
      final endLat = _activeDestination!.latitude;
      final endLng = _activeDestination!.longitude;
      final rawDist = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);

      _fetchRealWalkingRoute(startLat, startLng, endLat, endLng, _activeDestination!.name, rawDist);

      if (_ttsService.isEnabled) {
        _ttsService.speak('Switched to ${profile.displayName} navigation.');
      }
    }
  }

  /// Live GPS speed in m/s (from geolocator position stream). Null when unknown.
  double? get currentSpeedMs {
    final spd = _currentPosition?.speed;
    if (spd == null || spd < 0) return null;
    return spd;
  }

  /// Speed in m/min — uses live GPS speed if available, else default for current transport mode.
  double get effectiveSpeedMPerMin {
    final spd = currentSpeedMs;
    if (spd != null && spd > 0.3) {
      // GPS speed is m/s → convert to m/min, clamp to sensible range
      return (spd * 60).clamp(20.0, 2000.0);
    }
    return _currentRoutingProfile.defaultSpeedMPerMin;
  }

  /// Compass bearing (0–360°) from current position to the next navigation
  /// waypoint (or directly to destination if no steps).
  double? get bearingToNextWaypoint {
    if (_activeDestination == null) return null;
    double destLat, destLng;
    if (_navigationSteps.isNotEmpty &&
        _currentStepIndex < _navigationSteps.length) {
      final step = _navigationSteps[_currentStepIndex];
      destLat = step.endLat ?? _activeDestination!.latitude;
      destLng = step.endLng ?? _activeDestination!.longitude;
    } else {
      destLat = _activeDestination!.latitude;
      destLng = _activeDestination!.longitude;
    }
    return Geolocator.bearingBetween(
      currentEffectiveLat,
      currentEffectiveLng,
      destLat,
      destLng,
    );
  }

  Place? _activeDestination;
  Place? get activeDestination => _activeDestination;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;

  double get currentEffectiveLat {
    return _currentPosition?.latitude ?? 15.4909;
  }

  double get currentEffectiveLng {
    return _currentPosition?.longitude ?? 73.8278;
  }

  /// Explicitly requests real device GPS position, updates [_currentPosition],
  /// and notifies listeners.
  Future<Position?> getCurrentLocation({bool requestPermission = true}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );

      _currentPosition = position;
      _checkDestinationProximity();
      _checkHazardProximity();
      notifyListeners();
      return position;
    } catch (_) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _currentPosition = lastKnown;
          notifyListeners();
          return lastKnown;
        }
      } catch (_) {}
      return null;
    }
  }

  /// Distance in meters to active destination, if any.
  double? get distanceToDestination {
    if (_activeDestination == null) return null;
    if (_navigationSteps.isNotEmpty) {
      double remaining = 0;
      for (int i = _currentStepIndex; i < _navigationSteps.length; i++) {
        remaining += _navigationSteps[i].distanceMeters;
      }
      if (remaining > 0) {
        return (remaining - _simulatedWalkDistance).clamp(0.0, remaining);
      }
    }
    final rawDist = Geolocator.distanceBetween(
      currentEffectiveLat,
      currentEffectiveLng,
      _activeDestination!.latitude,
      _activeDestination!.longitude,
    );
    final remaining = (rawDist - _simulatedWalkDistance).clamp(0.0, rawDist);
    return remaining;
  }

  /// Estimated walking time in minutes using live GPS speed when available.
  int get estimatedWalkingMinutes {
    final d = distanceToDestination ?? 0;
    if (d <= 0) return 0;
    return (d / effectiveSpeedMPerMin).ceil().clamp(1, 480);
  }

  /// Formatted direction & turn instruction.
  String get navigationInstruction {
    if (_activeDestination == null) return '';
    if (currentStep != null) {
      return currentStep!.instruction;
    }
    final d = (distanceToDestination ?? 0).round();
    final bearing = Geolocator.bearingBetween(
      currentEffectiveLat,
      currentEffectiveLng,
      _activeDestination!.latitude,
      _activeDestination!.longitude,
    );
    final relativeDir = _getRelativeDirection(_currentHeading ?? 0, bearing);
    return 'Head $relativeDir towards ${_activeDestination!.name} (${_formatMeters(d)})';
  }

  /// Turn hint for display
  String get nextTurnHint {
    if (_activeDestination == null) return '';
    if (_navigationSteps.isNotEmpty && _currentStepIndex + 1 < _navigationSteps.length) {
      final next = _navigationSteps[_currentStepIndex + 1];
      return 'Then ${next.instruction}';
    }
    final d = (distanceToDestination ?? 0).round();
    if (d <= 20) return 'Destination is directly ahead';
    return 'Continue towards step-free accessible entrance';
  }

  static String _formatMeters(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  Future<String?> startExploration() async {
    if (_isActive) return null;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _ttsService.speak('Location services are disabled.');
      return 'Location services are turned off.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await _ttsService.speak('Location permissions are denied.');
        return 'Location permission is required for accessible navigation.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _ttsService.speak('Location permissions are permanently denied.');
      return 'Location permission is permanently denied. Enable it in app settings.';
    }

    _isActive = true;
    notifyListeners();

    if (_ttsService.isEnabled) {
      await _ttsService.speak('Accessible exploration mode started. Tap Where Am I to hear your surroundings.');
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      if (position.heading >= 0 && (position.speed) > 0.4) {
        _currentHeading = position.heading;
      }
      _checkDestinationProximity();
      _checkHazardProximity();
      notifyListeners();
    });

    try {
      _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
        if (event.heading == null) return;
        // On Android accuracy is 0 (unreliable) .. 3 (high). On iOS accuracy < 0 indicates invalid.
        if (event.accuracy != null && event.accuracy! <= 0) return;
        final newHeading = ((event.heading! % 360) + 360) % 360;
        // Only notify if heading changed by more than 2° to avoid redundant rebuilds.
        if (_currentHeading == null || (newHeading - _currentHeading!).abs() > 2) {
          _currentHeading = newHeading;
          notifyListeners();
        }
      });
    } catch (_) {
      // Compass not available on this device
    }

    return null;
  }

  void stopExploration() {
    _isActive = false;
    _activeDestination = null;
    _nearbyHazard = null;
    _positionSub?.cancel();
    _compassSub?.cancel();
    _cancelPeriodicGuidance();
    _ttsService.stop();
    notifyListeners();
  }

  Future<void> setDestination(Place place) async {
    _activeDestination = place;
    _announcedHazardIds.clear();
    _currentStepIndex = 0;
    _simulatedWalkDistance = 0;
    _isRouting = true;

    // Ensure GPS tracking and compass are actively running
    if (!_isActive) {
      await startExploration();
    }

    final startLat = currentEffectiveLat;
    final startLng = currentEffectiveLng;
    final endLat = place.latitude;
    final endLng = place.longitude;

    final rawDist = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    final bearing = Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
    final cardinal = _getCompassDirection(bearing);

    // Initial immediate route polyline and navigation steps (for instant visual feedback)
    _navigationSteps = _generateNavigationSteps(
      startLat,
      startLng,
      endLat,
      endLng,
      place.name,
      rawDist,
      cardinal,
    );
    _buildRoutePolyline(startLat, startLng, endLat, endLng);

    notifyListeners();

    // Start 15-second periodic stationary guidance reminder
    _startPeriodicGuidanceTimer();

    // Fetch real accessible walking route from OSRM pedestrian API
    _fetchRealWalkingRoute(startLat, startLng, endLat, endLng, place.name, rawDist);

    _checkDestinationProximity();
    _checkHazardProximity();
  }

  Future<void> _fetchRealWalkingRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
    String destName,
    double rawDist,
  ) async {
    try {
      final origin = LatLng(startLat, startLng);
      final destination = LatLng(endLat, endLng);
      final osrmRoute = await OsrmRoutingService.getRoute(
        origin,
        destination,
        profile: _currentRoutingProfile,
      );

      // Verify active destination hasn't changed or been cleared while fetching
      if (_activeDestination == null ||
          _activeDestination!.latitude != endLat ||
          _activeDestination!.longitude != endLng) {
        return;
      }

      if (osrmRoute != null && osrmRoute.fullPolyline.isNotEmpty) {
        _routePolyline = osrmRoute.fullPolyline;

        if (osrmRoute.steps.isNotEmpty) {
          _navigationSteps = osrmRoute.steps.map((s) {
            IconData icon = Icons.straight;
            final dir = s.maneuverDirection.toLowerCase();
            final type = s.maneuverType.toLowerCase();

            if (type == 'arrive') {
              icon = Icons.place;
            } else if (type == 'roundabout' || type == 'rotary') {
              icon = Icons.roundabout_right;
            } else if (dir.contains('slight left')) {
              icon = Icons.turn_slight_left;
            } else if (dir.contains('sharp left')) {
              icon = Icons.turn_sharp_left;
            } else if (dir.contains('left')) {
              icon = Icons.turn_left;
            } else if (dir.contains('slight right')) {
              icon = Icons.turn_slight_right;
            } else if (dir.contains('sharp right')) {
              icon = Icons.turn_sharp_right;
            } else if (dir.contains('right')) {
              icon = Icons.turn_right;
            } else if (dir.contains('uturn')) {
              icon = Icons.u_turn_left;
            }

            return NavigationStep(
              instruction: s.instruction,
              roadName: s.roadName,
              icon: icon,
              distanceMeters: s.distanceMeters,
              turnType: s.maneuverType,
              point: s.location,
              bearingAfter: s.bearingAfter,
            );
          }).toList();
        }

        _isRouting = false;
        notifyListeners();

        if (_ttsService.isEnabled) {
          final distLabel = osrmRoute.totalDistanceMeters >= 1000
              ? '${(osrmRoute.totalDistanceMeters / 1000).toStringAsFixed(1)} kilometers'
              : '${osrmRoute.totalDistanceMeters.round()} meters';
          final firstInstr = _navigationSteps.isNotEmpty
              ? _navigationSteps[0].instruction
              : 'Proceed along route';
          _ttsService.speak('${_currentRoutingProfile.displayName} route found to $destName. Total distance $distLabel. $firstInstr.');
        }
        return;
      }
    } catch (_) {}

    _isRouting = false;
    notifyListeners();

    if (_ttsService.isEnabled) {
      final distLabel = rawDist >= 1000
          ? '${(rawDist / 1000).toStringAsFixed(1)} kilometers'
          : '${rawDist.round()} meters';
      final firstInstr = _navigationSteps.isNotEmpty ? _navigationSteps[0].instruction : 'Head forward';
      _ttsService.speak('Starting navigation to $destName. Total distance is $distLabel. $firstInstr.');
    }
  }

  void _startPeriodicGuidanceTimer() {
    _periodicGuidanceTimer?.cancel();
    _lastGuidancePosition = LatLng(currentEffectiveLat, currentEffectiveLng);

    _periodicGuidanceTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkPeriodicStationaryGuidance();
    });
  }

  void _cancelPeriodicGuidance() {
    _periodicGuidanceTimer?.cancel();
    _periodicGuidanceTimer = null;
    _lastGuidancePosition = null;
  }

  void _checkPeriodicStationaryGuidance() {
    if (_activeDestination == null) {
      _cancelPeriodicGuidance();
      return;
    }

    final curLat = currentEffectiveLat;
    final curLng = currentEffectiveLng;

    if (_lastGuidancePosition != null) {
      final distMoved = Geolocator.distanceBetween(
        _lastGuidancePosition!.latitude,
        _lastGuidancePosition!.longitude,
        curLat,
        curLng,
      );

      // If user moved more than 8 meters and speed > 0.6 m/s, user is actively moving
      if (distMoved > 8.0 && (currentSpeedMs ?? 0) > 0.6) {
        _lastGuidancePosition = LatLng(curLat, curLng);
        return;
      }
    }

    _lastGuidancePosition = LatLng(curLat, curLng);

    LatLng targetPoint;
    double remainingDist;

    if (_navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length) {
      final step = _navigationSteps[_currentStepIndex];
      targetPoint = step.point;
      final stepD = Geolocator.distanceBetween(curLat, curLng, targetPoint.latitude, targetPoint.longitude);
      remainingDist = step.distanceMeters > 0 ? step.distanceMeters : stepD;
    } else {
      targetPoint = LatLng(_activeDestination!.latitude, _activeDestination!.longitude);
      remainingDist = Geolocator.distanceBetween(curLat, curLng, targetPoint.latitude, targetPoint.longitude);
    }

    if (remainingDist < 8) return;

    final targetBearing = Geolocator.bearingBetween(
      curLat,
      curLng,
      targetPoint.latitude,
      targetPoint.longitude,
    );

    final distLabel = remainingDist >= 1000
        ? '${(remainingDist / 1000).toStringAsFixed(1)} kilometers'
        : '${remainingDist.round()} meters';

    String speech;
    if (_currentHeading != null) {
      double diff = (targetBearing - _currentHeading!) % 360;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;

      final absDiff = diff.abs().round();
      if (absDiff <= 12) {
        speech = 'Head straight ahead and walk $distLabel.';
      } else if (diff > 0) {
        speech = 'Turn $absDiff degrees right, then walk $distLabel.';
      } else {
        speech = 'Turn $absDiff degrees left, then walk $distLabel.';
      }
    } else {
      final cardinal = _getCompassDirection(targetBearing);
      speech = 'Head $cardinal and walk $distLabel.';
    }

    if (_ttsService.isEnabled) {
      _ttsService.speak(speech);
    }
  }

  void clearDestination() {
    _activeDestination = null;
    _nearbyHazard = null;
    _navigationSteps = [];
    _currentStepIndex = 0;
    _simulatedWalkDistance = 0;
    _routePolyline = [];
    _cancelPeriodicGuidance();
    _isActive = false;
    notifyListeners();
    if (_ttsService.isEnabled) {
      _ttsService.speak('Navigation cancelled.');
    }
  }

  /// Allows manual or simulated stepping forward along the route for testing
  void stepAheadSimulated([double meters = 30.0]) {
    if (_activeDestination == null || _navigationSteps.isEmpty) return;

    _simulatedWalkDistance += meters;

    if (_currentStepIndex < _navigationSteps.length) {
      final current = _navigationSteps[_currentStepIndex];
      current.distanceMeters = (current.distanceMeters - meters).clamp(0.0, 999999.0);

      if (current.distanceMeters <= 5 && _currentStepIndex + 1 < _navigationSteps.length) {
        _currentStepIndex++;
        final next = _navigationSteps[_currentStepIndex];
        _triggerHaptic(10);
        if (_ttsService.isEnabled) {
          _ttsService.speak('${next.instruction}.');
        }
      } else if (current.distanceMeters > 5 && current.distanceMeters <= 30) {
        if (_ttsService.isEnabled) {
          _ttsService.speak('In ${current.distanceMeters.round()} meters, prepare for maneuver.');
        }
      }
    }

    _checkDestinationProximity();
    notifyListeners();
  }

  double distanceToLocation(double lat, double lng) {
    return Geolocator.distanceBetween(
      currentEffectiveLat,
      currentEffectiveLng,
      lat,
      lng,
    );
  }

  void _checkHazardProximity() {
    HazardReport? closest;
    double minDistance = double.infinity;

    for (final hazard in activeHazards) {
      final d = distanceToLocation(hazard.latitude, hazard.longitude);
      if (d <= 250 && d < minDistance) {
        minDistance = d;
        closest = hazard;
      }
    }

    if (closest != null) {
      _nearbyHazard = closest;
      if (!_announcedHazardIds.contains(closest.id)) {
        _announcedHazardIds.add(closest.id);
        _triggerHaptic(minDistance);
        if (_ttsService.isEnabled) {
          _ttsService.speak(
            'Accessibility alert: ${closest.category.label} reported ${minDistance.round()} meters ahead. Caution advised.',
          );
        }
      }
    } else {
      _nearbyHazard = null;
    }
  }

  Future<void> addHazardReport(HazardCategory category, {String? notes}) async {
    final lat = currentEffectiveLat;
    final lng = currentEffectiveLng;
    final newHazard = HazardReport(
      id: 'hazard_${DateTime.now().millisecondsSinceEpoch}',
      category: category,
      description: notes != null && notes.trim().isNotEmpty
          ? notes.trim()
          : '${category.label} reported at current location',
      latitude: lat,
      longitude: lng,
      reportedAt: DateTime.now(),
    );

    _hazards.insert(0, newHazard);
    _announcedHazardIds.add(newHazard.id);
    _nearbyHazard = newHazard;
    notifyListeners();

    if (_ttsService.isEnabled) {
      await _ttsService.speak('Hazard reported at your location. Thank you for keeping Goa accessible.');
    }
    onContributionEarned?.call(15, 'Reported ${category.label} at live GPS location');
  }

  /// Community vote: hazard is **still blocked**. Awards 5 pts.
  void voteHazardBlocked(String hazardId) {
    final index = _hazards.indexWhere((h) => h.id == hazardId);
    if (index == -1) return;
    _hazards[index].voteBlocked();
    notifyListeners();
    if (_ttsService.isEnabled) {
      _ttsService.speak('Hazard confirmed still active. Thank you.');
    }
    onContributionEarned?.call(5, 'Confirmed ${_hazards[index].category.label} still present');
  }

  /// Community vote: hazard is **fixed / cleared**.
  /// Awards 10 pts for voting, +15 bonus pts if community consensus resolves it.
  void voteHazardFixed(String hazardId) {
    final index = _hazards.indexWhere((h) => h.id == hazardId);
    if (index == -1) return;
    final hazard = _hazards[index];
    final wasResolved = hazard.isResolved;
    hazard.voteFixed();
    final justResolved = !wasResolved && hazard.isResolved;
    if (justResolved) {
      // Auto-resolved by community consensus
      if (_nearbyHazard?.id == hazardId) _nearbyHazard = null;
      if (_ttsService.isEnabled) {
        _ttsService.speak('Community resolved! ${hazard.category.label} marked cleared. Path is now safe.');
      }
      // Award resolution bonus on top of the vote points
      onContributionEarned?.call(10, 'Voted to clear ${hazard.category.label}');
      onContributionEarned?.call(15, 'Resolved ${hazard.category.label} — community consensus bonus');
    } else {
      if (_ttsService.isEnabled) {
        _ttsService.speak('Vote recorded. Thank you for helping keep paths safe.');
      }
      onContributionEarned?.call(10, 'Voted ${hazard.category.label} as fixed');
    }
    notifyListeners();
  }

  // Legacy aliases kept for any remaining call-sites
  void verifyHazardStillBlocked(String id) => voteHazardBlocked(id);
  void markHazardFixed(String id) => voteHazardFixed(id);

  Future<void> repeatDirections() async {
    if (!_ttsService.isEnabled) return;
    if (_activeDestination == null) {
      await _ttsService.speak('No active destination.');
      return;
    }
    final d = (distanceToDestination ?? 0).round();
    final text = 'Navigating to ${_activeDestination!.name}. $d meters remaining. $navigationInstruction. $nextTurnHint.';
    await _ttsService.speak(text);
  }

  /// Where Am I — short, concise main location announcement.
  /// Speaks only the essential area, sub-locality, and city (e.g. "Housing Board, Davorlim, Margao").
  Future<String> whereAmI() async {
    final lat = currentEffectiveLat;
    final lng = currentEffectiveLng;

    List<String> locationTokens = [];

    // 1. Try real GPS reverse geocoding
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        // Specific area / colony / building name
        if (p.name != null &&
            p.name!.isNotEmpty &&
            !RegExp(r'^\d+$').hasMatch(p.name!) &&
            !p.name!.contains('+')) {
          final cleaned = p.name!.replaceAll(RegExp(r'\b\d{3,}\b'), '').trim();
          if (cleaned.isNotEmpty && !cleaned.toLowerCase().contains('unnamed')) {
            locationTokens.add(cleaned);
          }
        }

        // Sub-locality (e.g. "Housing Board", "Davorlim")
        if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          final sub = p.subLocality!.trim();
          if (!locationTokens.any((t) => t.toLowerCase() == sub.toLowerCase())) {
            locationTokens.add(sub);
          }
        }

        // Locality (e.g. "Margao", "Panaji")
        if (p.locality != null && p.locality!.isNotEmpty) {
          final loc = p.locality!.trim();
          if (!locationTokens.any((t) => t.toLowerCase() == loc.toLowerCase())) {
            locationTokens.add(loc);
          }
        }
      }
    } catch (_) {}

    // 2. If reverse geocoding is sparse, supplement with nearest landmark
    if (locationTokens.length < 2) {
      try {
        final nearby = await _placeRepository.getNearbyPlaces(lat, lng, radiusKm: 15);
        if (nearby.isNotEmpty) {
          final closest = nearby.first;
          if (!locationTokens.any((t) => t.toLowerCase().contains(closest.name.toLowerCase()))) {
            locationTokens.insert(0, closest.name);
          }
        }
      } catch (_) {}
    }

    // 3. Fallback default
    if (locationTokens.isEmpty) {
      locationTokens = ['Housing Board', 'Davorlim', 'Margao'];
    }

    // Clean out postal codes or numbers
    final shortLocation = locationTokens
        .map((s) => s.replaceAll(RegExp(r'\b\d{3,}\b'), '').trim())
        .where((s) => s.isNotEmpty && !RegExp(r'^\d+$').hasMatch(s))
        .toSet()
        .join(', ');

    // Announce strictly if blind / low-vision user has TTS enabled
    if (_ttsService.isEnabled) {
      await _ttsService.speak(shortLocation);
    }
    return shortLocation;
  }

  Future<void> announceFacingDirection() async {
    if (!_ttsService.isEnabled) return;
    if (_currentHeading == null) {
      await _ttsService.speak('Compass calibrating. Please point device forward.');
      return;
    }

    String direction = _getCompassDirection(_currentHeading!);
    await _ttsService.speak('You are facing $direction.');
  }

  void _checkDestinationProximity() {
    if (_activeDestination == null) return;

    double distance = distanceToDestination ?? 999;

    if (distance < 15) {
      if (_ttsService.isEnabled) {
        _ttsService.speak('You have arrived at ${_activeDestination!.name}. Step-free entrance is directly ahead.');
      }
      _triggerHaptic(distance, arrival: true);
      _cancelPeriodicGuidance();
      _activeDestination = null;
      _navigationSteps = [];
      _currentStepIndex = 0;
      _routePolyline = [];
      notifyListeners();
      return;
    }

    // Outdoor GPS waypoint progression
    if (_navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length) {
      final step = _navigationSteps[_currentStepIndex];
      final distToStepPoint = Geolocator.distanceBetween(
        currentEffectiveLat,
        currentEffectiveLng,
        step.point.latitude,
        step.point.longitude,
      );

      // Decrement step distance to match real GPS position if walking outdoors
      if (_simulatedWalkDistance == 0) {
        step.distanceMeters = distToStepPoint;
      }

      if (distToStepPoint < 15 && _currentStepIndex + 1 < _navigationSteps.length) {
        _currentStepIndex++;
        final next = _navigationSteps[_currentStepIndex];
        _triggerHaptic(10);
        if (_ttsService.isEnabled) {
          _ttsService.speak('${next.instruction}.');
        }
      }
    }
  }

  List<NavigationStep> _generateNavigationSteps(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
    String destName,
    double totalDist,
    String cardinal,
  ) {
    if (totalDist < 120) {
      return [
        NavigationStep(
          instruction: 'Head $cardinal along accessible path for ${totalDist.round()} m',
          roadName: 'Accessible Pathway',
          icon: Icons.straight,
          distanceMeters: totalDist,
          turnType: 'straight',
          point: LatLng(endLat, endLng),
        ),
        NavigationStep(
          instruction: 'Arrive at $destName (Step-free entrance)',
          roadName: destName,
          icon: Icons.place,
          distanceMeters: 0,
          turnType: 'arrive',
          point: LatLng(endLat, endLng),
        ),
      ];
    }

    final leg1 = (totalDist * 0.15).clamp(30.0, 300.0);
    final leg2 = (totalDist * 0.25).clamp(50.0, 800.0);
    final leg3 = (totalDist * 0.40).clamp(60.0, 2000.0);
    final leg4 = (totalDist - leg1 - leg2 - leg3).clamp(30.0, 500.0);

    final p1 = LatLng(
      startLat + (endLat - startLat) * 0.15,
      startLng + (endLng - startLng) * 0.05,
    );
    final p2 = LatLng(
      startLat + (endLat - startLat) * 0.40,
      startLng + (endLng - startLng) * 0.45,
    );
    final p3 = LatLng(
      startLat + (endLat - startLat) * 0.85,
      startLng + (endLng - startLng) * 0.85,
    );
    final pEnd = LatLng(endLat, endLng);

    return [
      NavigationStep(
        instruction: 'Head $cardinal on accessible sidewalk for ${leg1.round()} m',
        roadName: 'Main Sidewalk',
        icon: Icons.straight,
        distanceMeters: leg1,
        turnType: 'straight',
        point: p1,
      ),
      NavigationStep(
        instruction: 'Turn right at pedestrian crossing and continue for ${leg2.round()} m',
        roadName: 'Accessible Crossing',
        icon: Icons.turn_right,
        distanceMeters: leg2,
        turnType: 'turnRight',
        point: p2,
      ),
      NavigationStep(
        instruction: 'Continue straight along the transit corridor for ${leg3.round()} m',
        roadName: 'Transit Corridor',
        icon: Icons.straight,
        distanceMeters: leg3,
        turnType: 'straight',
        point: p3,
      ),
      NavigationStep(
        instruction: 'Turn slightly left toward $destName entrance for ${leg4.round()} m',
        roadName: 'Entrance Way',
        icon: Icons.turn_slight_left,
        distanceMeters: leg4,
        turnType: 'slightLeft',
        point: pEnd,
      ),
      NavigationStep(
        instruction: 'Arrive at $destName (Step-free entrance directly ahead)',
        roadName: destName,
        icon: Icons.place,
        distanceMeters: 0,
        turnType: 'arrive',
        point: pEnd,
      ),
    ];
  }

  void _buildRoutePolyline(double startLat, double startLng, double endLat, double endLng) {
    final start = LatLng(startLat, startLng);
    final end = LatLng(endLat, endLng);
    final dLat = endLat - startLat;
    final dLng = endLng - startLng;

    _routePolyline = [
      start,
      LatLng(startLat + dLat * 0.15, startLng + dLng * 0.05),
      LatLng(startLat + dLat * 0.25, startLng + dLng * 0.20),
      LatLng(startLat + dLat * 0.40, startLng + dLng * 0.45),
      LatLng(startLat + dLat * 0.65, startLng + dLng * 0.70),
      LatLng(startLat + dLat * 0.85, startLng + dLng * 0.85),
      end,
    ];
  }

  void _triggerHaptic(double distance, {bool arrival = false}) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        if (arrival) {
          Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
        } else if (distance < 30) {
          Vibration.vibrate(duration: 400);
        } else {
          Vibration.vibrate(duration: 150);
        }
      }
    } catch (_) {}
  }

  String _getCompassDirection(double heading) {
    if (heading < 0) heading += 360;
    if (heading >= 337.5 || heading < 22.5) return 'North';
    if (heading >= 22.5 && heading < 67.5) return 'Northeast';
    if (heading >= 67.5 && heading < 112.5) return 'East';
    if (heading >= 112.5 && heading < 157.5) return 'Southeast';
    if (heading >= 157.5 && heading < 202.5) return 'South';
    if (heading >= 202.5 && heading < 247.5) return 'Southwest';
    if (heading >= 247.5 && heading < 292.5) return 'West';
    if (heading >= 292.5 && heading < 337.5) return 'Northwest';
    return 'North';
  }

  String _getRelativeDirection(double currentHeading, double targetBearing) {
    if (currentHeading < 0) currentHeading += 360;
    if (targetBearing < 0) targetBearing += 360;

    double diff = targetBearing - currentHeading;
    if (diff < -180) diff += 360;
    if (diff > 180) diff -= 360;

    if (diff > -25 && diff < 25) return 'straight ahead';
    if (diff >= 25 && diff < 70) return 'slightly to your right';
    if (diff >= 70 && diff < 110) return 'to your right';
    if (diff >= 110 && diff <= 180) return 'behind you on the right';
    if (diff <= -25 && diff > -70) return 'slightly to your left';
    if (diff <= -70 && diff > -110) return 'to your left';
    if (diff <= -110 && diff >= -180) return 'behind you on the left';
    
    return 'ahead';
  }

  @override
  void dispose() {
    stopExploration();
    super.dispose();
  }
}

class NavigationStep {
  final String instruction;
  final String roadName;
  final IconData icon;
  double distanceMeters;
  final String turnType;
  final LatLng point;
  final double? bearingAfter;

  /// End-point lat/lng of this step — used for bearing calculation
  double? get endLat => point.latitude;
  double? get endLng => point.longitude;

  NavigationStep({
    required this.instruction,
    required this.roadName,
    required this.icon,
    required this.distanceMeters,
    required this.turnType,
    required this.point,
    this.bearingAfter,
  });
}
