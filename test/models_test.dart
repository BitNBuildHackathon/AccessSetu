import 'package:access_map/core/services/navigation_service.dart';
import 'package:access_map/core/utils/accessibility_visibility_policy.dart';
import 'package:access_map/features/map/data/mock_place_repository.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:access_map/shared/models/place_review.dart';
import 'package:access_map/shared/models/travel_mode.dart';
import 'package:access_map/shared/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:access_map/shared/models/accessibility_feature.dart';

void main() {
  group('Place mode suitability', () {
    test('suitableForMode logic for Solo vs PA', () {
      final placeWithStepFree = Place(
        id: '1', name: 'A', category: PlaceCategory.cafe, address: '', description: '',
        latitude: 0, longitude: 0, friendlyScore: 0, wheelchairScore: 0, visualAccessibilityScore: 0, hearingAccessibilityScore: 0, communicationScore: 0,
        reviews: const [],
        accessibilityFeatures: const [
          AccessibilityFeature(id: 'f1', name: 'Step-free entrance', category: AccessibilityCategory.physical, icon: Icons.accessible, status: FeatureStatus.available),
        ],
      );

      final placeWithStaffAssistance = Place(
        id: '2', name: 'B', category: PlaceCategory.cafe, address: '', description: '',
        latitude: 0, longitude: 0, friendlyScore: 0, wheelchairScore: 0, visualAccessibilityScore: 0, hearingAccessibilityScore: 0, communicationScore: 0,
        reviews: const [],
        accessibilityFeatures: const [
          AccessibilityFeature(id: 'f2', name: 'Staff assistance available', category: AccessibilityCategory.physical, icon: Icons.accessible, status: FeatureStatus.available),
        ],
      );

      // Step-free is suitable for both
      expect(placeWithStepFree.suitableForMode(TravelMode.solo), isTrue);
      expect(placeWithStepFree.suitableForMode(TravelMode.paAssisted), isTrue);

      // Staff assistance is only suitable for PA, not Solo
      expect(placeWithStaffAssistance.suitableForMode(TravelMode.solo), isFalse);
      expect(placeWithStaffAssistance.suitableForMode(TravelMode.paAssisted), isTrue);
    });
  });

  group('AccessibilityVisibilityPolicy', () {
    const policy = AccessibilityVisibilityPolicy();

    test('wheelchair score hidden for visual-only profile', () {
      final profile = UserProfile.empty().copyWith(accessibilityNeeds: [AccessibilityNeed.blindLowVision]);
      expect(policy.showWheelchairScore(profile), isFalse);
    });

    test('shouldShowWheelchairScore returns true when physical needs exist', () {
      final user = UserProfile.empty().copyWith(
        accessibilityNeeds: [AccessibilityNeed.wheelchairMobility],
      );
      expect(user.shouldShowWheelchairScore, isTrue);
    });

    test('shouldShowWheelchairScore returns false when no physical needs exist', () {
      final user = UserProfile.empty().copyWith(
        accessibilityNeeds: [AccessibilityNeed.blindLowVision],
      );
      expect(user.shouldShowWheelchairScore, isFalse);
    });

    test('visual score promoted for cannotSee profile', () {
      final profile = UserProfile.empty().copyWith(accessibilityNeeds: [AccessibilityNeed.blindLowVision]);
      expect(policy.showVisualScore(profile), isTrue);
      expect(policy.showHearingScore(profile), isFalse);
      expect(policy.showCommunicationScore(profile), isFalse);
    });

    test('communication score promoted for cannotSpeak profile', () {
      final profile = UserProfile.empty()
          .copyWith(accessibilityNeeds: [AccessibilityNeed.speechCommunication]);
      expect(policy.showCommunicationScore(profile), isTrue);
    });

    test('copyWith updates fields correctly', () {
      final user = UserProfile.empty();
      final updated = user.copyWith(
        displayName: 'New Name',
        accessibilityNeeds: [AccessibilityNeed.speechCommunication],
      );
      expect(updated.displayName, 'New Name');
    });
  });

  group('MockPlaceRepository', () {
    late MockPlaceRepository repo;

    setUp(() {
      repo = MockPlaceRepository();
    });

    test('provides at least 10 varied demo places', () async {
      final places = await repo.getNearbyPlaces(15.4909, 73.8278);
      expect(places.length, greaterThanOrEqualTo(10));
      expect(places.map((p) => p.category).toSet().length, greaterThanOrEqualTo(8));
    });

    test('places have varied accessibility profiles (not binary)', () async {
      final places = await repo.getNearbyPlaces(15.4909, 73.8278);
      final wheelchairScores = places.map((p) => p.wheelchairScore).toList()
        ..sort();
      // Spread across the scale: worst below 6, best above 9.
      expect(wheelchairScores.first, lessThan(6.0));
      expect(wheelchairScores.last, greaterThan(9.0));
    });

    test('places carry features with confirmation data and scores', () async {
      final places = await repo.getNearbyPlaces(15.4909, 73.8278);
      for (final place in places) {
        expect(place.friendlyScore, inInclusiveRange(0, 10));
        expect(place.accessibilityFeatures, isNotEmpty);
        expect(place.communityConfirmations, greaterThan(0));
        expect(place.lastVerified, isNotNull);
      }
    });

    test('major places have realistic reviews with context', () async {
      final places = await repo.getNearbyPlaces(15.4909, 73.8278);
      final withReviews =
          places.where((p) => p.reviews.length >= 2).toList();
      expect(withReviews.length, greaterThanOrEqualTo(8));
      for (final place in withReviews) {
        for (final review in place.reviews) {
          expect(review.reviewerContext.displayLabel, isNotEmpty);
          expect(review.overallRating, inInclusiveRange(1, 10));
        }
      }
      // Reviews should not all be positive — honesty matters.
      final ratings = withReviews.expand((p) => p.reviews).map((r) => r.overallRating);
      expect(ratings.any((r) => r <= 7), isTrue);
    });

    test('searchPlaces matches name and category', () async {
      final byName = await repo.searchPlaces('fishka');
      expect(byName, isNotEmpty);
      final byCategory = await repo.searchPlaces('hospital');
      expect(byCategory, isNotEmpty);
      expect(byCategory.every((p) => p.name.toLowerCase().contains('hospital') ||
          p.category == PlaceCategory.hospital ||
          p.category == PlaceCategory.clinic), isTrue);
    });

    test('getPlaceById returns place or null', () async {
      final place = await repo.getPlaceById('place-1');
      expect(place, isNotNull);
      expect(place!.name, 'Fishka Restaurant');
      expect(await repo.getPlaceById('nope'), isNull);
    });

    test('addReview inserts review and increments totals', () async {
      final review = PlaceReview(
        id: 'test-r',
        placeId: 'place-1',
        userId: 'u-test',
        userName: 'Tester',
        overallRating: 8,
        comment: 'Test comment for repository insertion.',
        createdAt: DateTime.now(),
        reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo),
      );
      await repo.addReview('place-1', review);
      final updated = await repo.getPlaceById('place-1');
      expect(updated!.reviews.any((r) => r.id == 'test-r'), isTrue);
      expect(updated.totalReviews, 44);
    });

    test('every place has a real Google Maps link and it is used', () async {
      final places = await repo.getNearbyPlaces(15.4909, 73.8278);
      for (final place in places) {
        expect(place.directionsUrl, isNotNull,
            reason: '${place.name} is missing a directionsUrl');
        final uri = Uri.parse(place.directionsUrl!);
        expect(uri.scheme, 'https');
        expect(uri.host, 'www.google.com');
        expect(
          uri.path,
          anyOf('/maps/search/', '/maps/dir/'),
          reason: '${place.name} has unexpected maps path: ${uri.path}',
        );
        expect(
          uri.queryParameters['api'],
          '1',
          reason: '${place.name} link missing api=1',
        );
        expect(
          uri.queryParameters['query'] ?? uri.queryParameters['destination'],
          isNotNull,
          reason: '${place.name} link missing target',
        );
      }
    });

    test('directions URI targets the place on Google Maps', () {
      final place = Place(
        id: 'x', name: 'Fishka Restaurant', category: PlaceCategory.cafe,
        address: 'a', description: 'd',
        latitude: 15.5553, longitude: 73.7514,
        friendlyScore: 8, wheelchairScore: 8, visualAccessibilityScore: 8,
        hearingAccessibilityScore: 8, communicationScore: 8,
        accessibilityFeatures: const [],
        reviews: const [],
      );
      final service = NavigationService();

      final uri = service.buildDirectionsUri(place);
      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['destination'], '15.5553,73.7514');
      expect(uri.queryParameters['travelmode'], 'driving');

      // A place with a real link must use it verbatim.
      final withLink = place.copyWith(directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Real+Venue');
      final realUri = service.buildDirectionsUri(withLink);
      expect(realUri.toString(), contains('query=Real+Venue'));

      final geo = service.buildGeoUri(place);
      expect(geo.scheme, 'geo');
      expect(geo.path, '15.5553,73.7514');
      expect(geo.queryParameters['q'], contains('Fishka Restaurant'));
    });

    test('distance calc is plausible (haversine sanity)', () {
      final place = Place(
        id: 'x', name: 'X', category: PlaceCategory.cafe,
        address: 'a', description: 'd',
        latitude: 15.4909, longitude: 73.8278,
        friendlyScore: 8, wheelchairScore: 8, visualAccessibilityScore: 8,
        hearingAccessibilityScore: 8, communicationScore: 8,
        accessibilityFeatures: const [],
        reviews: const [],
      );
      // Same point → 0 km.
      expect(place.distanceKmFrom(15.4909, 73.8278), closeTo(0, 0.001));
      // Roughly 1 degree of latitude ≈ 111 km.
      expect(place.distanceKmFrom(16.4909, 73.8278), closeTo(111.2, 2));
    });
  });
}
