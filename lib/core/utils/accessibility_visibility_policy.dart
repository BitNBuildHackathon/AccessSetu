import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/user_profile.dart';

/// Centralized policy for what accessibility information to display
/// based on the user's profile. NEVER duplicate these conditions in UI code.
class AccessibilityVisibilityPolicy {
  const AccessibilityVisibilityPolicy();

  /// Whether to show the wheelchair-specific score for this profile.
  bool showWheelchairScore(UserProfile profile) {
    return profile.shouldShowWheelchairScore;
  }

  /// Whether to show visual accessibility score prominently.
  bool showVisualScore(UserProfile profile) {
    return profile.accessibilityNeeds.contains(AccessibilityNeed.blindLowVision);
  }

  /// Whether to show hearing accessibility score prominently.
  bool showHearingScore(UserProfile profile) {
    return profile.accessibilityNeeds.contains(AccessibilityNeed.deafHardOfHearing);
  }

  /// Whether to show communication score prominently.
  bool showCommunicationScore(UserProfile profile) {
    return profile.accessibilityNeeds.contains(AccessibilityNeed.speechCommunication);
  }

  /// Get the list of most relevant accessibility feature categories for
  /// this user's profile.
  List<String> relevantFeatureKeywords(UserProfile profile) {
    final keywords = <String>[];
    for (final need in profile.accessibilityNeeds) {
      switch (need) {
        case AccessibilityNeed.blindLowVision:
          keywords.addAll([
            'braille',
            'tactile',
            'audio',
            'staff assistance',
            'clear signage',
            'high-contrast',
          ]);
        case AccessibilityNeed.speechCommunication:
          keywords.addAll([
            'communication',
            'written',
            'digital',
            'visual',
            'patience',
          ]);
        case AccessibilityNeed.deafHardOfHearing:
          keywords.addAll([
            'visual announcements',
            'written communication',
            'sign language',
            'hearing loop',
          ]);
        case AccessibilityNeed.wheelchairMobility:
          keywords.addAll([
            'ramp',
            'elevator',
            'accessible restroom',
            'accessible parking',
            'step-free',
            'wide entrance',
          ]);
        case AccessibilityNeed.cognitiveNeuro:
          keywords.addAll([
            'quiet space',
            'clear signage',
            'simple navigation',
            'sensory-friendly',
          ]);
      }
    }
    return keywords;
  }
}
