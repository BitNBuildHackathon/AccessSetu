import 'package:flutter/material.dart';

/// Core accessibility needs — clean, non-overlapping categories.
enum AccessibilityNeed {
  wheelchairMobility,
  blindLowVision,
  deafHardOfHearing,
  speechCommunication,
  cognitiveNeuro;

  String get displayName {
    switch (this) {
      case AccessibilityNeed.wheelchairMobility:
        return 'Wheelchair / Mobility';
      case AccessibilityNeed.blindLowVision:
        return 'Blind / Low Vision';
      case AccessibilityNeed.deafHardOfHearing:
        return 'Deaf / Hard of Hearing';
      case AccessibilityNeed.speechCommunication:
        return 'Speech / Communication';
      case AccessibilityNeed.cognitiveNeuro:
        return 'Cognitive / Neurodiverse';
    }
  }

  String get description {
    switch (this) {
      case AccessibilityNeed.wheelchairMobility:
        return 'I use a wheelchair or have physical mobility challenges.';
      case AccessibilityNeed.blindLowVision:
        return 'I am blind or have low vision.';
      case AccessibilityNeed.deafHardOfHearing:
        return 'I am deaf or have hearing impairment.';
      case AccessibilityNeed.speechCommunication:
        return 'I have difficulty with speech or verbal communication.';
      case AccessibilityNeed.cognitiveNeuro:
        return 'I have cognitive, neurological, or learning needs.';
    }
  }

  IconData get icon {
    switch (this) {
      case AccessibilityNeed.wheelchairMobility:
        return Icons.accessible;
      case AccessibilityNeed.blindLowVision:
        return Icons.visibility_off;
      case AccessibilityNeed.deafHardOfHearing:
        return Icons.hearing_disabled;
      case AccessibilityNeed.speechCommunication:
        return Icons.speaker_notes_off;
      case AccessibilityNeed.cognitiveNeuro:
        return Icons.psychology;
    }
  }

  /// Whether this need is related to physical/wheelchair accessibility.
  bool get isPhysicalAccessibility =>
      this == wheelchairMobility;
}
