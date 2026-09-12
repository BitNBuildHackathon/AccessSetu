import 'package:flutter/material.dart';

enum HazardCategory {
  rampBlocked,
  liftBroken,
  unexpectedStairs,
  sidewalkBlocked,
  unsafeCrossing,
  constructionObstruction,
  waterlogging,
  other,
}

extension HazardCategoryExtension on HazardCategory {
  String get label {
    switch (this) {
      case HazardCategory.rampBlocked:
        return 'Ramp Blocked';
      case HazardCategory.liftBroken:
        return 'Broken Elevator / Lift';
      case HazardCategory.unexpectedStairs:
        return 'Unexpected Stairs';
      case HazardCategory.sidewalkBlocked:
        return 'Sidewalk Blocked';
      case HazardCategory.unsafeCrossing:
        return 'Unsafe Road Crossing';
      case HazardCategory.constructionObstruction:
        return 'Construction Obstruction';
      case HazardCategory.waterlogging:
        return 'Waterlogging / Potholes';
      case HazardCategory.other:
        return 'Accessibility Hazard';
    }
  }

  IconData get icon {
    switch (this) {
      case HazardCategory.rampBlocked:
        return Icons.block;
      case HazardCategory.liftBroken:
        return Icons.elevator;
      case HazardCategory.unexpectedStairs:
        return Icons.stairs;
      case HazardCategory.sidewalkBlocked:
        return Icons.do_not_disturb_on;
      case HazardCategory.unsafeCrossing:
        return Icons.warning_amber_rounded;
      case HazardCategory.constructionObstruction:
        return Icons.construction;
      case HazardCategory.waterlogging:
        return Icons.water_drop;
      case HazardCategory.other:
        return Icons.report_problem;
    }
  }

  Color get color {
    switch (this) {
      case HazardCategory.rampBlocked:
      case HazardCategory.unexpectedStairs:
        return const Color(0xFFDC2626); // Red
      case HazardCategory.liftBroken:
      case HazardCategory.constructionObstruction:
        return const Color(0xFFEA580C); // Deep Orange
      case HazardCategory.waterlogging:
        return const Color(0xFF0284C7); // Sky blue
      default:
        return const Color(0xFFD97706); // Amber
    }
  }
}

class HazardReport {
  final String id;
  final HazardCategory category;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime reportedAt;
  DateTime lastConfirmedAt;
  int confirmationCount;
  int disputeCount;
  bool isResolved;

  HazardReport({
    required this.id,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    DateTime? reportedAt,
    DateTime? lastConfirmedAt,
    this.confirmationCount = 1,
    this.disputeCount = 0,
    this.isResolved = false,
  })  : reportedAt = reportedAt ?? DateTime.now(),
        lastConfirmedAt = lastConfirmedAt ?? (reportedAt ?? DateTime.now());

  Duration get age => DateTime.now().difference(lastConfirmedAt);

  String get ageLabel {
    if (age.inMinutes < 1) return 'just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  void confirmStillPresent() {
    confirmationCount += 1;
    lastConfirmedAt = DateTime.now();
  }

  void markFixed() {
    isResolved = true;
    lastConfirmedAt = DateTime.now();
  }

  void dispute() {
    disputeCount += 1;
  }
}
