import 'accessibility_feature.dart';
import 'place_category.dart';
import 'place_review.dart';
import 'dart:math' as math;

/// A place with accessibility data, scores, features, and reviews.
class Place {
  final String id;
  final String name;
  final PlaceCategory category;
  final String address;
  final String? phone;
  final String? website;

  /// Real Google Maps link for this venue (when known). Used by the
  /// directions action so users land on the actual place.
  final String? directionsUrl;
  final String description;

  final double latitude;
  final double longitude;

  // Scores out of 10
  final double friendlyScore;
  final double wheelchairScore;
  final double visualAccessibilityScore;
  final double hearingAccessibilityScore;
  final double communicationScore;

  final List<AccessibilityFeature> accessibilityFeatures;
  final List<PlaceReview> reviews;
  final List<String> imageUrls;

  // Score metadata
  final int totalReviews;
  final int communityConfirmations;
  final DateTime? lastVerified;

  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    this.phone,
    this.website,
    this.directionsUrl,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.friendlyScore,
    required this.wheelchairScore,
    required this.visualAccessibilityScore,
    required this.hearingAccessibilityScore,
    required this.communicationScore,
    required this.accessibilityFeatures,
    required this.reviews,
    this.imageUrls = const [],
    this.totalReviews = 0,
    this.communityConfirmations = 0,
    this.lastVerified,
  });

  /// Features that are confirmed available.
  List<AccessibilityFeature> get availableFeatures => accessibilityFeatures
      .where((f) => f.status == FeatureStatus.available)
      .toList();

  /// Features that are confirmed unavailable.
  List<AccessibilityFeature> get unavailableFeatures => accessibilityFeatures
      .where((f) => f.status == FeatureStatus.unavailable)
      .toList();

  /// Features with unknown status.
  List<AccessibilityFeature> get unknownFeatures => accessibilityFeatures
      .where((f) => f.status == FeatureStatus.unknown)
      .toList();

  /// Distance in kilometres from the given coordinates.
  double distanceKmFrom(double lat, double lng) {
    const r = 6371.0; // Earth radius in km.
    final dLat = _degToRad(latitude - lat);
    final dLng = _degToRad(longitude - lng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat)) *
            math.cos(_degToRad(latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  Place copyWith({
    List<PlaceReview>? reviews,
    double? friendlyScore,
    int? totalReviews,
    List<AccessibilityFeature>? accessibilityFeatures,
    String? directionsUrl,
  }) {
    return Place(
      id: id,
      name: name,
      category: category,
      address: address,
      phone: phone,
      website: website,
      description: description,
      latitude: latitude,
      longitude: longitude,
      friendlyScore: friendlyScore ?? this.friendlyScore,
      wheelchairScore: wheelchairScore,
      visualAccessibilityScore: visualAccessibilityScore,
      hearingAccessibilityScore: hearingAccessibilityScore,
      communicationScore: communicationScore,
      accessibilityFeatures: accessibilityFeatures ?? this.accessibilityFeatures,
      directionsUrl: directionsUrl ?? this.directionsUrl,
      reviews: reviews ?? this.reviews,
      imageUrls: imageUrls,
      totalReviews: totalReviews ?? this.totalReviews,
      communityConfirmations: communityConfirmations,
      lastVerified: lastVerified,
    );
  }
}
