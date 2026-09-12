import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:vibration/vibration.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:access_map/core/services/tts_service.dart';
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

  HazardReport? _nearbyHazard;
  HazardReport? get nearbyHazard => _nearbyHazard;

  final Set<String> _announcedHazardIds = {};

  ExplorationService(this._ttsService, this._placeRepository);

  /// Dynamic walking route polyline from user position to active destination
  List<LatLng> get routePolylinePoints {
    if (_activeDestination == null) return [];
    final start = LatLng(currentEffectiveLat, currentEffectiveLng);
    final end = LatLng(_activeDestination!.latitude, _activeDestination!.longitude);
    final midLat = start.latitude + (end.latitude - start.latitude) * 0.45;
    final midLng = start.longitude + (end.longitude - start.longitude) * 0.55;
    return [start, LatLng(midLat, start.longitude), LatLng(midLat, midLng), end];
  }

  bool _isActive = false;
  bool get isActive => _isActive;

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  double? _currentHeading;
  double? get currentHeading => _currentHeading;

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
    return Geolocator.distanceBetween(
      currentEffectiveLat,
      currentEffectiveLng,
      _activeDestination!.latitude,
      _activeDestination!.longitude,
    );
  }

  /// Estimated walking time in minutes (~75m/min).
  int get estimatedWalkingMinutes {
    final d = distanceToDestination ?? 0;
    return (d / 75).ceil().clamp(1, 120);
  }

  /// Formatted direction & turn instruction.
  String get navigationInstruction {
    if (_activeDestination == null) return '';
    final d = (distanceToDestination ?? 0).round();
    final bearing = Geolocator.bearingBetween(
      currentEffectiveLat,
      currentEffectiveLng,
      _activeDestination!.latitude,
      _activeDestination!.longitude,
    );
    final relativeDir = _getRelativeDirection(_currentHeading ?? 0, bearing);
    return 'Head $relativeDir towards ${_activeDestination!.name} ($d m away)';
  }

  /// Turn hint for display
  String get nextTurnHint {
    if (_activeDestination == null) return '';
    final d = (distanceToDestination ?? 0).round();
    if (d <= 20) return 'Destination is right in front of you';
    if (d <= 50) return 'In ${d}m, approach the step-free entrance';
    return 'Continue straight for ${(d * 0.6).round()}m, then look for entrance signs';
  }

  Future<void> startExploration() async {
    if (_isActive) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _ttsService.speak('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await _ttsService.speak('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _ttsService.speak('Location permissions are permanently denied.');
      return;
    }

    _isActive = true;
    notifyListeners();

    if (_ttsService.isEnabled) {
      await _ttsService.speak('Accessible exploration mode started. Tap Where Am I to hear your surroundings.');
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _checkDestinationProximity();
      _checkHazardProximity();
      notifyListeners();
    });

    try {
      _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
        if (event.heading != null) {
          _currentHeading = event.heading;
          notifyListeners();
        }
      });
    } catch (_) {
      // Compass not available
    }
  }

  void stopExploration() {
    _isActive = false;
    _activeDestination = null;
    _nearbyHazard = null;
    _positionSub?.cancel();
    _compassSub?.cancel();
    _ttsService.stop();
    notifyListeners();
  }

  void setDestination(Place place) {
    _activeDestination = place;
    _announcedHazardIds.clear();
    notifyListeners();
    final d = (distanceToDestination ?? 0).round();
    if (_ttsService.isEnabled) {
      _ttsService.speak('Starting navigation to ${place.name}. Destination is $d meters away. $navigationInstruction');
    }
    _checkDestinationProximity();
    _checkHazardProximity();
  }

  void clearDestination() {
    _activeDestination = null;
    _nearbyHazard = null;
    notifyListeners();
    if (_ttsService.isEnabled) {
      _ttsService.speak('Navigation cancelled.');
    }
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

  void verifyHazardStillBlocked(String hazardId) {
    final index = _hazards.indexWhere((h) => h.id == hazardId);
    if (index != -1) {
      _hazards[index].confirmStillPresent();
      notifyListeners();
      if (_ttsService.isEnabled) {
        _ttsService.speak('Thank you. Hazard confirmed still active.');
      }
      onContributionEarned?.call(5, 'Verified ${_hazards[index].category.label} still present');
    }
  }

  void markHazardFixed(String hazardId) {
    final index = _hazards.indexWhere((h) => h.id == hazardId);
    if (index != -1) {
      final label = _hazards[index].category.label;
      _hazards[index].markFixed();
      if (_nearbyHazard?.id == hazardId) {
        _nearbyHazard = null;
      }
      notifyListeners();
      if (_ttsService.isEnabled) {
        _ttsService.speak('Hazard marked as fixed. Path cleared.');
      }
      onContributionEarned?.call(10, 'Verified $label resolved');
    }
  }

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
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
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
        _ttsService.speak('You have arrived at ${_activeDestination!.name}.');
      }
      _triggerHaptic(distance, arrival: true);
      _activeDestination = null;
      notifyListeners();
      return;
    }

    // Turn-by-turn simulation based on distance checkpoints
    if (_ttsService.isEnabled) {
      if (distance > 15 && distance < 30) {
        _ttsService.speak('${_activeDestination!.name} is approaching directly ahead.');
        _triggerHaptic(distance);
      } else if (distance > 40 && distance < 50) {
        _ttsService.speak('In 50 meters, destination is $nextTurnHint');
      }
    }
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
