import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Supported transportation profiles for OSRM routing.
enum OsrmProfile {
  walk,
  bike,
  car;

  String get endpoint {
    switch (this) {
      case OsrmProfile.car:
        return 'driving';
      case OsrmProfile.bike:
        return 'bike';
      case OsrmProfile.walk:
        return 'foot';
    }
  }

  String get displayName {
    switch (this) {
      case OsrmProfile.car:
        return 'Car';
      case OsrmProfile.bike:
        return 'Bike';
      case OsrmProfile.walk:
        return 'Walk';
    }
  }

  IconData get icon {
    switch (this) {
      case OsrmProfile.car:
        return Icons.directions_car;
      case OsrmProfile.bike:
        return Icons.directions_bike;
      case OsrmProfile.walk:
        return Icons.directions_walk;
    }
  }

  /// Estimated baseline speed in meters per minute (if device GPS speed is stationary/unknown)
  double get defaultSpeedMPerMin {
    switch (this) {
      case OsrmProfile.car:
        return 500.0; // ~30 km/h city driving
      case OsrmProfile.bike:
        return 250.0; // ~15 km/h cycling
      case OsrmProfile.walk:
        return 75.0;  // ~4.5 km/h walking
    }
  }
}

/// A single turn-by-turn navigation step decoded from OSRM.
class OsrmStep {
  final String instruction;
  final String roadName;
  final double distanceMeters;
  final double durationSeconds;
  final String maneuverType; // 'turn', 'depart', 'arrive', 'straight', etc.
  final String maneuverDirection; // 'left', 'right', 'straight', 'slight left', etc.
  final double bearingBefore; // degrees, bearing you're coming from
  final double bearingAfter;  // degrees, bearing to head after maneuver
  final LatLng location;
  final List<LatLng> geometry; // sub-polyline for this step

  const OsrmStep({
    required this.instruction,
    required this.roadName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuverType,
    required this.maneuverDirection,
    required this.bearingBefore,
    required this.bearingAfter,
    required this.location,
    required this.geometry,
  });
}

/// Full route returned by OSRM.
class OsrmRoute {
  final List<LatLng> fullPolyline;
  final List<OsrmStep> steps;
  final double totalDistanceMeters;
  final double totalDurationSeconds;

  const OsrmRoute({
    required this.fullPolyline,
    required this.steps,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });
}

/// Calls the OSRM public API with 'foot', 'bike', or 'driving' profiles.
/// No API key required.
class OsrmRoutingService {
  static const String _baseRouteUrl = 'https://router.project-osrm.org/route/v1';

  /// Fetch a route from [origin] to [destination] using [profile] (walk, bike, car).
  /// Returns null on any network/parse error.
  static Future<OsrmRoute?> getRoute(
    LatLng origin,
    LatLng destination, {
    OsrmProfile profile = OsrmProfile.walk,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseRouteUrl/${profile.endpoint}/${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=true&annotations=false',
      );

      final response =
          await http.get(url).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final totalDistance = (route['distance'] as num).toDouble();
      final totalDuration = (route['duration'] as num).toDouble();

      // Full polyline from GeoJSON
      final geoCoords =
          (route['geometry']['coordinates'] as List<dynamic>);
      final fullPolyline = geoCoords
          .map((c) {
            final coords = c as List<dynamic>;
            return LatLng(
                (coords[1] as num).toDouble(),
                (coords[0] as num).toDouble());
          })
          .toList();

      // Steps
      final legs = route['legs'] as List<dynamic>;
      final steps = <OsrmStep>[];
      for (final leg in legs) {
        final legSteps = leg['steps'] as List<dynamic>;
        for (final step in legSteps) {
          final stepMap = step as Map<String, dynamic>;
          final maneuver = stepMap['maneuver'] as Map<String, dynamic>;
          final name = (stepMap['name'] as String?) ?? '';
          final dist = (stepMap['distance'] as num).toDouble();
          final dur = (stepMap['duration'] as num).toDouble();
          final mType = (maneuver['type'] as String?) ?? 'straight';
          final mDir = (maneuver['modifier'] as String?) ?? 'straight';
          final bBefore = (maneuver['bearing_before'] as num?)?.toDouble() ?? 0.0;
          final bAfter = (maneuver['bearing_after'] as num?)?.toDouble() ?? 0.0;
          final locCoords =
              maneuver['location'] as List<dynamic>;
          final loc = LatLng(
              (locCoords[1] as num).toDouble(),
              (locCoords[0] as num).toDouble());

          // Step geometry
          final stepGeoCoords =
              (stepMap['geometry']['coordinates'] as List<dynamic>);
          final stepGeometry = stepGeoCoords
              .map((c) {
                final coords = c as List<dynamic>;
                return LatLng(
                    (coords[1] as num).toDouble(),
                    (coords[0] as num).toDouble());
              })
              .toList();

          final instruction = _buildInstruction(mType, mDir, dist, name);

          steps.add(OsrmStep(
            instruction: instruction,
            roadName: name.isNotEmpty ? name : 'unnamed path',
            distanceMeters: dist,
            durationSeconds: dur,
            maneuverType: mType,
            maneuverDirection: mDir,
            bearingBefore: bBefore,
            bearingAfter: bAfter,
            location: loc,
            geometry: stepGeometry,
          ));
        }
      }

      return OsrmRoute(
        fullPolyline: fullPolyline,
        steps: steps,
        totalDistanceMeters: totalDistance,
        totalDurationSeconds: totalDuration,
      );
    } catch (e) {
      // Network unavailable or parse error — caller falls back to straight line
      return null;
    }
  }

  /// Convenience helper for walking route.
  static Future<OsrmRoute?> getWalkingRoute(LatLng origin, LatLng destination) =>
      getRoute(origin, destination, profile: OsrmProfile.walk);

  /// Builds a human-readable instruction from OSRM maneuver data.
  static String _buildInstruction(
      String type, String direction, double distMeters, String name) {
    final dist = distMeters >= 1000
        ? '${(distMeters / 1000).toStringAsFixed(1)} km'
        : '${distMeters.round()} m';

    final road = name.isNotEmpty ? 'onto $name' : '';

    switch (type) {
      case 'depart':
        return 'Head ${_dirLabel(direction)} $road for $dist';
      case 'arrive':
        return 'Arrive at destination';
      case 'turn':
        return 'Turn ${_dirLabel(direction)} $road — $dist';
      case 'new name':
        return 'Continue ${_dirLabel(direction)} $road for $dist';
      case 'merge':
        return 'Merge ${_dirLabel(direction)} $road — $dist';
      case 'fork':
        return 'Take ${_dirLabel(direction)} fork $road — $dist';
      case 'end of road':
        return 'At end of road, turn ${_dirLabel(direction)} $road — $dist';
      case 'continue':
        return 'Continue ${_dirLabel(direction)} for $dist';
      case 'roundabout':
      case 'rotary':
        return 'Enter roundabout, take exit ${_dirLabel(direction)} — $dist';
      default:
        return 'Continue for $dist';
    }
  }

  static String _dirLabel(String direction) {
    switch (direction) {
      case 'left':
        return 'left';
      case 'right':
        return 'right';
      case 'slight left':
        return 'slightly left';
      case 'slight right':
        return 'slightly right';
      case 'sharp left':
        return 'sharp left';
      case 'sharp right':
        return 'sharp right';
      case 'uturn':
        return 'U-turn';
      default:
        return 'straight';
    }
  }
}
