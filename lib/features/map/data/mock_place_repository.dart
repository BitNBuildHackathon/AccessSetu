import 'package:flutter/material.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:access_map/shared/models/accessibility_feature.dart';
import 'package:access_map/shared/models/place_review.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/travel_mode.dart';

/// Abstract place repository — mock now, API later.
abstract class PlaceRepository {
  Future<List<Place>> getNearbyPlaces(double lat, double lng, {double radiusKm = 10});
  Future<List<Place>> searchPlaces(String query);
  Future<Place?> getPlaceById(String id);
  Future<List<Place>> getPlacesByCategory(PlaceCategory category);
  Future<void> addReview(String placeId, PlaceReview review);
}

/// Mock implementation with 12 realistic places around Goa, India.
class MockPlaceRepository implements PlaceRepository {
  late final List<Place> _places;

  MockPlaceRepository() {
    _places = _buildMockPlaces();
  }

  @override
  Future<List<Place>> getNearbyPlaces(double lat, double lng, {double radiusKm = 50}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sorted = List<Place>.from(_places);
    sorted.sort((a, b) => a.distanceKmFrom(lat, lng).compareTo(b.distanceKmFrom(lat, lng)));
    return sorted.where((p) => p.distanceKmFrom(lat, lng) <= radiusKm).toList();
  }

  @override
  Future<List<Place>> searchPlaces(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final q = query.toLowerCase();
    return _places.where((p) =>
      p.name.toLowerCase().contains(q) ||
      p.category.displayName.toLowerCase().contains(q) ||
      p.address.toLowerCase().contains(q) ||
      p.description.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Future<Place?> getPlaceById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _places.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Place>> getPlacesByCategory(PlaceCategory category) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _places.where((p) => p.category == category).toList();
  }

  @override
  Future<void> addReview(String placeId, PlaceReview review) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _places.indexWhere((p) => p.id == placeId);
    if (idx != -1) {
      final place = _places[idx];
      final newReviews = [review, ...place.reviews];
      _places[idx] = place.copyWith(
        reviews: newReviews,
        totalReviews: place.totalReviews + 1,
      );
    }
  }

  List<Place> _buildMockPlaces() {
    return [
      // 1. Restaurant — excellent accessibility
      Place(
        id: 'place-1',
        name: 'Fishka Restaurant',
        category: PlaceCategory.restaurant,
        address: 'Calangute Road, Baga, Goa 403516',
        phone: '+91 832 227 1234',
        website: 'https://fishkagoa.com',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Fishka+Restaurant+Calangute+Goa',
        description: 'A popular beachside restaurant known for its seafood and stunning views. The restaurant has invested significantly in accessibility features including ramps, accessible restrooms, and trained staff.',
        latitude: 15.5553,
        longitude: 73.7514,
        friendlyScore: 9.2,
        wheelchairScore: 9.5,
        visualAccessibilityScore: 8.9,
        hearingAccessibilityScore: 8.1,
        communicationScore: 9.1,
        totalReviews: 43,
        communityConfirmations: 28,
        lastVerified: DateTime.now().subtract(const Duration(days: 3)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f1', name: 'Ramp', icon: Icons.accessible, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 18, lastConfirmed: DateTime.now().subtract(const Duration(days: 3))),
          AccessibilityFeature(id: 'f2', name: 'Step-free entrance', icon: Icons.door_front_door, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 22, lastConfirmed: DateTime.now().subtract(const Duration(days: 5))),
          AccessibilityFeature(id: 'f3', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 15, lastConfirmed: DateTime.now().subtract(const Duration(days: 7))),
          AccessibilityFeature(id: 'f4', name: 'Accessible parking', icon: Icons.local_parking, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 12, lastConfirmed: DateTime.now().subtract(const Duration(days: 10))),
          AccessibilityFeature(id: 'f5', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 25, lastConfirmed: DateTime.now().subtract(const Duration(days: 2))),
          AccessibilityFeature(id: 'f6', name: 'Clear signage', icon: Icons.signpost, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 10, lastConfirmed: DateTime.now().subtract(const Duration(days: 14))),
          AccessibilityFeature(id: 'f7', name: 'Elevator', icon: Icons.elevator, category: AccessibilityCategory.physical, status: FeatureStatus.unavailable),
          AccessibilityFeature(id: 'f8', name: 'Tactile guidance', icon: Icons.touch_app, category: AccessibilityCategory.visual, status: FeatureStatus.unknown),
          AccessibilityFeature(id: 'f9', name: 'Braille menu', icon: Icons.menu_book, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 8, lastConfirmed: DateTime.now().subtract(const Duration(days: 20))),
        ],
        reviews: [
          PlaceReview(
            id: 'r1', placeId: 'place-1', userId: 'u1', userName: 'Priya M.',
            overallRating: 9, staffInteractionRating: 10, communicationRating: 9, assistanceRating: 10, physicalAccessibilityRating: 9, facilitiesRating: 9,
            comment: 'Entrance has a proper ramp and staff were very helpful. They guided me to my table and read out the menu. Braille menu was also available. Restroom was accessible too.',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.blindLowVision]),
            helpfulVotes: 24,
          ),
          PlaceReview(
            id: 'r2', placeId: 'place-1', userId: 'u2', userName: 'Rahul K.',
            overallRating: 9, staffInteractionRating: 9, physicalAccessibilityRating: 10, facilitiesRating: 9,
            comment: 'I visited with my wheelchair and had no issues at all. The ramp is well-maintained, tables have good clearance, and the accessible parking spot is right near the entrance.',
            createdAt: DateTime.now().subtract(const Duration(days: 12)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.wheelchairMobility]),
            helpfulVotes: 18,
          ),
          PlaceReview(
            id: 'r3', placeId: 'place-1', userId: 'u3', userName: 'Aisha D.',
            overallRating: 9, staffInteractionRating: 9, communicationRating: 8,
            comment: 'I visited with my friend who uses a wheelchair. The main entrance was accessible. Staff were patient and willing to communicate through writing when needed.',
            createdAt: DateTime.now().subtract(const Duration(days: 20)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.paAssisted),
            helpfulVotes: 12,
          ),
          PlaceReview(
            id: 'r4', placeId: 'place-1', userId: 'u4', userName: 'Miguel S.',
            overallRating: 8, staffInteractionRating: 8, communicationRating: 9,
            comment: 'Great food and the staff were accommodating. Wish they had tactile guidance from the entrance to the seating area, but staff helped me navigate without any issues.',
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.blindLowVision]),
            helpfulVotes: 9,
          ),
        ],
      ),

      // 2. Hospital — very good accessibility
      Place(
        id: 'place-2',
        name: 'Goa Medical College',
        category: PlaceCategory.hospital,
        address: 'Bambolim, Goa 403202',
        phone: '+91 832 245 8727',
        website: 'https://gmc.goa.gov.in',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Goa+Medical+College+Bambolim',
        description: 'The premier government medical institution in Goa with comprehensive medical services. Extensive accessibility infrastructure throughout the campus.',
        latitude: 15.4579,
        longitude: 73.8681,
        friendlyScore: 8.8,
        wheelchairScore: 9.0,
        visualAccessibilityScore: 7.5,
        hearingAccessibilityScore: 7.8,
        communicationScore: 8.4,
        totalReviews: 67,
        communityConfirmations: 45,
        lastVerified: DateTime.now().subtract(const Duration(days: 1)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f10', name: 'Ramp', icon: Icons.accessible, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 35, lastConfirmed: DateTime.now().subtract(const Duration(days: 1))),
          AccessibilityFeature(id: 'f11', name: 'Elevator', icon: Icons.elevator, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 40, lastConfirmed: DateTime.now().subtract(const Duration(days: 2))),
          AccessibilityFeature(id: 'f12', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 30, lastConfirmed: DateTime.now().subtract(const Duration(days: 4))),
          AccessibilityFeature(id: 'f13', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 38, lastConfirmed: DateTime.now().subtract(const Duration(days: 1))),
          AccessibilityFeature(id: 'f14', name: 'Accessible parking', icon: Icons.local_parking, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 25, lastConfirmed: DateTime.now().subtract(const Duration(days: 5))),
          AccessibilityFeature(id: 'f15', name: 'Visual announcements', icon: Icons.tv, category: AccessibilityCategory.hearing, status: FeatureStatus.available, confirmationCount: 15, lastConfirmed: DateTime.now().subtract(const Duration(days: 10))),
          AccessibilityFeature(id: 'f16', name: 'Braille', icon: Icons.menu_book, category: AccessibilityCategory.visual, status: FeatureStatus.unknown),
          AccessibilityFeature(id: 'f17', name: 'Tactile guidance', icon: Icons.touch_app, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 8, lastConfirmed: DateTime.now().subtract(const Duration(days: 30))),
        ],
        reviews: [
          PlaceReview(
            id: 'r5', placeId: 'place-2', userId: 'u5', userName: 'Sunita R.',
            overallRating: 9, staffInteractionRating: 9, assistanceRating: 10, physicalAccessibilityRating: 9,
            comment: 'Excellent accessibility infrastructure. Elevators work well, ramps at every entrance, and hospital staff are trained to assist patients with disabilities.',
            createdAt: DateTime.now().subtract(const Duration(days: 8)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.paAssisted, accessibilityNeeds: [AccessibilityNeed.wheelchairMobility]),
            helpfulVotes: 31,
          ),
          PlaceReview(
            id: 'r6', placeId: 'place-2', userId: 'u6', userName: 'Deepak V.',
            overallRating: 8, staffInteractionRating: 8, communicationRating: 7,
            comment: 'Navigating independently was manageable with tactile guidance on the ground floor, but upper floors lack it. Staff were helpful when asked.',
            createdAt: DateTime.now().subtract(const Duration(days: 15)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.blindLowVision]),
            helpfulVotes: 14,
          ),
          PlaceReview(
            id: 'r7', placeId: 'place-2', userId: 'u7', userName: 'Fatima N.',
            overallRating: 8, communicationRating: 8, assistanceRating: 8,
            comment: 'Communication was okay — some staff were patient with written communication, while others weren\'t aware of how to help speech-impaired patients.',
            createdAt: DateTime.now().subtract(const Duration(days: 25)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.speechCommunication]),
            helpfulVotes: 10,
          ),
        ],
      ),

      // 3. Park — mixed accessibility
      Place(
        id: 'place-3',
        name: 'Miramar Beach Park',
        category: PlaceCategory.park,
        address: 'Miramar, Panaji, Goa 403001',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Miramar+Beach+Panaji',
        description: 'A beautiful beachfront park in Panaji with walking paths, benches, and gardens. Accessibility varies across different areas of the park.',
        latitude: 15.4725,
        longitude: 73.8072,
        friendlyScore: 7.1,
        wheelchairScore: 5.8,
        visualAccessibilityScore: 6.5,
        hearingAccessibilityScore: 8.5,
        communicationScore: 7.3,
        totalReviews: 28,
        communityConfirmations: 15,
        lastVerified: DateTime.now().subtract(const Duration(days: 14)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f18', name: 'Paved paths', icon: Icons.directions_walk, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 12, lastConfirmed: DateTime.now().subtract(const Duration(days: 14))),
          AccessibilityFeature(id: 'f19', name: 'Step-free entrance', icon: Icons.door_front_door, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 10, lastConfirmed: DateTime.now().subtract(const Duration(days: 20))),
          AccessibilityFeature(id: 'f20', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical, status: FeatureStatus.unavailable),
          AccessibilityFeature(id: 'f21', name: 'Accessible parking', icon: Icons.local_parking, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 6, lastConfirmed: DateTime.now().subtract(const Duration(days: 30))),
          AccessibilityFeature(id: 'f22', name: 'Ramp to beach', icon: Icons.accessible, category: AccessibilityCategory.physical, status: FeatureStatus.unavailable),
          AccessibilityFeature(id: 'f23', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual, status: FeatureStatus.unknown),
        ],
        reviews: [
          PlaceReview(
            id: 'r8', placeId: 'place-3', userId: 'u8', userName: 'Kavita P.',
            overallRating: 6, physicalAccessibilityRating: 5, facilitiesRating: 4,
            comment: 'The main walking path is paved and wheelchair-friendly, but the beach itself is inaccessible. No accessible restroom nearby. Beautiful views though.',
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.paAssisted, accessibilityNeeds: [AccessibilityNeed.wheelchairMobility]),
            helpfulVotes: 20,
          ),
          PlaceReview(
            id: 'r9', placeId: 'place-3', userId: 'u9', userName: 'Jorge F.',
            overallRating: 7, staffInteractionRating: 7, communicationRating: 7,
            comment: 'Nice park for a walk. The paths are mostly flat, but navigating solo with visual impairment requires some caution near the beach area. Benches are well-spaced.',
            createdAt: DateTime.now().subtract(const Duration(days: 22)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.blindLowVision]),
            helpfulVotes: 8,
          ),
        ],
      ),

      // 4. Mall — good accessibility
      Place(
        id: 'place-4',
        name: 'Caculo Mall',
        category: PlaceCategory.mall,
        address: 'St. Inez, Panaji, Goa 403001',
        phone: '+91 832 242 5555',
        website: 'https://caculomall.com',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Caculo+Mall+Panaji',
        description: 'Modern shopping mall in Panaji with multiple floors, food court, and entertainment. Well-equipped with accessibility features throughout.',
        latitude: 15.4909,
        longitude: 73.8278,
        friendlyScore: 8.7,
        wheelchairScore: 9.1,
        visualAccessibilityScore: 7.8,
        hearingAccessibilityScore: 8.5,
        communicationScore: 8.2,
        totalReviews: 52,
        communityConfirmations: 35,
        lastVerified: DateTime.now().subtract(const Duration(days: 5)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f24', name: 'Ramp', icon: Icons.accessible, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 28, lastConfirmed: DateTime.now().subtract(const Duration(days: 5))),
          AccessibilityFeature(id: 'f25', name: 'Elevator', icon: Icons.elevator, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 30, lastConfirmed: DateTime.now().subtract(const Duration(days: 3))),
          AccessibilityFeature(id: 'f26', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 22, lastConfirmed: DateTime.now().subtract(const Duration(days: 8))),
          AccessibilityFeature(id: 'f27', name: 'Accessible parking', icon: Icons.local_parking, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 20, lastConfirmed: DateTime.now().subtract(const Duration(days: 7))),
          AccessibilityFeature(id: 'f28', name: 'Wide entrance', icon: Icons.door_front_door, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 25, lastConfirmed: DateTime.now().subtract(const Duration(days: 5))),
          AccessibilityFeature(id: 'f29', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 18, lastConfirmed: DateTime.now().subtract(const Duration(days: 10))),
          AccessibilityFeature(id: 'f30', name: 'High-contrast signs', icon: Icons.signpost, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 12, lastConfirmed: DateTime.now().subtract(const Duration(days: 15))),
          AccessibilityFeature(id: 'f31', name: 'Tactile guidance', icon: Icons.touch_app, category: AccessibilityCategory.visual, status: FeatureStatus.unavailable),
        ],
        reviews: [
          PlaceReview(
            id: 'r10', placeId: 'place-4', userId: 'u10', userName: 'Neha S.',
            overallRating: 9, staffInteractionRating: 9, physicalAccessibilityRating: 10, facilitiesRating: 9,
            comment: 'Excellent mall for wheelchair users! Every floor accessible by elevator, wide aisles, accessible restrooms on each floor. Staff at the info desk were very helpful.',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.wheelchairMobility]),
            helpfulVotes: 15,
          ),
          PlaceReview(
            id: 'r11', placeId: 'place-4', userId: 'u11', userName: 'Arjun M.',
            overallRating: 8, staffInteractionRating: 8, communicationRating: 8,
            comment: 'Staff were friendly, but there was no tactile guidance inside. High-contrast signage was helpful. Would benefit from audio announcements for visually impaired visitors.',
            createdAt: DateTime.now().subtract(const Duration(days: 18)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.blindLowVision]),
            helpfulVotes: 11,
          ),
          PlaceReview(
            id: 'r12', placeId: 'place-4', userId: 'u12', userName: 'Lata G.',
            overallRating: 8, communicationRating: 9, assistanceRating: 8,
            comment: 'Shopping experience was comfortable. Some store staff were accommodating with written communication, though not all stores are equally accessible.',
            createdAt: DateTime.now().subtract(const Duration(days: 28)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.paAssisted, accessibilityNeeds: [AccessibilityNeed.speechCommunication]),
            helpfulVotes: 7,
          ),
        ],
      ),

      // 5. Tourist attraction — excellent visual accessibility
      Place(
        id: 'place-5',
        name: 'Basilica of Bom Jesus',
        category: PlaceCategory.touristAttraction,
        address: 'Old Goa, Goa 403402',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Basilica+of+Bom+Jesus+Old+Goa',
        phone: '+91 832 228 5790',
        description: 'UNESCO World Heritage Site and one of the most famous churches in Goa. Recent accessibility improvements have made the site more inclusive.',
        latitude: 15.5009,
        longitude: 73.9116,
        friendlyScore: 8.4,
        wheelchairScore: 7.2,
        visualAccessibilityScore: 9.3,
        hearingAccessibilityScore: 8.0,
        communicationScore: 8.5,
        totalReviews: 38,
        communityConfirmations: 22,
        lastVerified: DateTime.now().subtract(const Duration(days: 7)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f32', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 20, lastConfirmed: DateTime.now().subtract(const Duration(days: 7))),
          AccessibilityFeature(id: 'f33', name: 'Audio guide', icon: Icons.headphones, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 16, lastConfirmed: DateTime.now().subtract(const Duration(days: 10))),
          AccessibilityFeature(id: 'f34', name: 'Tactile exhibits', icon: Icons.touch_app, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 10, lastConfirmed: DateTime.now().subtract(const Duration(days: 15))),
          AccessibilityFeature(id: 'f35', name: 'Ramp', icon: Icons.accessible, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 14, lastConfirmed: DateTime.now().subtract(const Duration(days: 9))),
          AccessibilityFeature(id: 'f36', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical, status: FeatureStatus.unavailable),
          AccessibilityFeature(id: 'f37', name: 'Step-free entrance', icon: Icons.door_front_door, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 12, lastConfirmed: DateTime.now().subtract(const Duration(days: 12))),
        ],
        reviews: [
          PlaceReview(
            id: 'r13', placeId: 'place-5', userId: 'u13', userName: 'Maria C.',
            overallRating: 9, staffInteractionRating: 10, assistanceRating: 10,
            comment: 'The audio guide was fantastic — very detailed descriptions of the architecture and artwork. Staff member walked with me through the entire basilica explaining everything. Truly inclusive experience.',
            createdAt: DateTime.now().subtract(const Duration(days: 6)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.blindLowVision]),
            helpfulVotes: 28,
          ),
          PlaceReview(
            id: 'r14', placeId: 'place-5', userId: 'u14', userName: 'Vikram T.',
            overallRating: 7, physicalAccessibilityRating: 6, facilitiesRating: 5,
            comment: 'The ramp at the entrance works but it\'s quite steep. Inside, some areas have steps that are challenging with a wheelchair. No accessible restroom on-site.',
            createdAt: DateTime.now().subtract(const Duration(days: 20)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.paAssisted, accessibilityNeeds: [AccessibilityNeed.wheelchairMobility]),
            helpfulVotes: 16,
          ),
        ],
      ),

      // 6. Hotel — good overall
      Place(
        id: 'place-6',
        name: 'Cidade de Goa Resort',
        category: PlaceCategory.hotel,
        address: 'Vainguinim Beach, Dona Paula, Goa 403004',
        phone: '+91 832 245 4545',
        website: 'https://cidadedegoa.com',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Cidade+de+Goa+Dona+Paula',
        description: 'Heritage resort by the beach with excellent accessibility features, accessible rooms, and dedicated assistance staff.',
        latitude: 15.4527,
        longitude: 73.8484,
        friendlyScore: 9.0,
        wheelchairScore: 8.8,
        visualAccessibilityScore: 8.5,
        hearingAccessibilityScore: 8.2,
        communicationScore: 9.0,
        totalReviews: 55,
        communityConfirmations: 38,
        lastVerified: DateTime.now().subtract(const Duration(days: 2)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f38', name: 'Ramp', icon: Icons.accessible, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 30, lastConfirmed: DateTime.now().subtract(const Duration(days: 2))),
          AccessibilityFeature(id: 'f39', name: 'Elevator', icon: Icons.elevator, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 32, lastConfirmed: DateTime.now().subtract(const Duration(days: 3))),
          AccessibilityFeature(id: 'f40', name: 'Accessible rooms', icon: Icons.hotel, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 20, lastConfirmed: DateTime.now().subtract(const Duration(days: 5))),
          AccessibilityFeature(id: 'f41', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 24, lastConfirmed: DateTime.now().subtract(const Duration(days: 4))),
          AccessibilityFeature(id: 'f42', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 28, lastConfirmed: DateTime.now().subtract(const Duration(days: 2))),
          AccessibilityFeature(id: 'f43', name: 'Written communication', icon: Icons.edit_note, category: AccessibilityCategory.communication, status: FeatureStatus.available, confirmationCount: 12, lastConfirmed: DateTime.now().subtract(const Duration(days: 10))),
          AccessibilityFeature(id: 'f44', name: 'Accessible parking', icon: Icons.local_parking, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 18, lastConfirmed: DateTime.now().subtract(const Duration(days: 6))),
        ],
        reviews: [
          PlaceReview(
            id: 'r15', placeId: 'place-6', userId: 'u15', userName: 'Sanjay B.',
            overallRating: 9, staffInteractionRating: 10, assistanceRating: 10, physicalAccessibilityRating: 9, facilitiesRating: 9,
            comment: 'One of the best accessible hotel experiences in Goa. The accessible room was spacious with grab bars, roll-in shower, and lowered amenities. Staff were incredibly attentive.',
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.wheelchairMobility]),
            helpfulVotes: 22,
          ),
          PlaceReview(
            id: 'r16', placeId: 'place-6', userId: 'u16', userName: 'Elena R.',
            overallRating: 9, staffInteractionRating: 9, communicationRating: 9,
            comment: 'Staff were amazing. They offered written communication, were patient, and always had a notepad ready. The room had visual alerts for the doorbell and phone.',
            createdAt: DateTime.now().subtract(const Duration(days: 14)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.speechCommunication]),
            helpfulVotes: 15,
          ),
        ],
      ),

      // 7. Cafe — moderate accessibility
      Place(
        id: 'place-7',
        name: 'Artjuna Garden Cafe',
        category: PlaceCategory.cafe,
        address: 'Anjuna, Goa 403509',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Artjuna+Cafe+Anjuna+Goa',
        description: 'Bohemian garden cafe with organic food and a relaxed atmosphere. Limited physical accessibility but very welcoming staff.',
        latitude: 15.5826,
        longitude: 73.7412,
        friendlyScore: 7.5,
        wheelchairScore: 4.5,
        visualAccessibilityScore: 7.0,
        hearingAccessibilityScore: 8.0,
        communicationScore: 8.5,
        totalReviews: 22,
        communityConfirmations: 10,
        lastVerified: DateTime.now().subtract(const Duration(days: 21)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f45', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 8, lastConfirmed: DateTime.now().subtract(const Duration(days: 21))),
          AccessibilityFeature(id: 'f46', name: 'Step-free entrance', icon: Icons.door_front_door, category: AccessibilityCategory.physical, status: FeatureStatus.unavailable),
          AccessibilityFeature(id: 'f47', name: 'Ramp', icon: Icons.accessible, category: AccessibilityCategory.physical, status: FeatureStatus.unavailable),
          AccessibilityFeature(id: 'f48', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical, status: FeatureStatus.unavailable),
          AccessibilityFeature(id: 'f49', name: 'Patience with speech-impaired', icon: Icons.chat, category: AccessibilityCategory.communication, status: FeatureStatus.available, confirmationCount: 6, lastConfirmed: DateTime.now().subtract(const Duration(days: 25))),
        ],
        reviews: [
          PlaceReview(
            id: 'r17', placeId: 'place-7', userId: 'u17', userName: 'Tara J.',
            overallRating: 7, staffInteractionRating: 9, communicationRating: 9, physicalAccessibilityRating: 3,
            comment: 'Staff are lovely and very patient, but the entrance has two steps and the garden paths are uneven gravel — very difficult with a wheelchair. Great food though!',
            createdAt: DateTime.now().subtract(const Duration(days: 15)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.paAssisted, accessibilityNeeds: [AccessibilityNeed.wheelchairMobility]),
            helpfulVotes: 18,
          ),
          PlaceReview(
            id: 'r18', placeId: 'place-7', userId: 'u18', userName: 'Ravi P.',
            overallRating: 8, staffInteractionRating: 9, communicationRating: 8,
            comment: 'Nice atmosphere. Staff helped me find a table and described the menu items. The garden setting is peaceful but navigation requires assistance.',
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.paAssisted, accessibilityNeeds: [AccessibilityNeed.blindLowVision]),
            helpfulVotes: 6,
          ),
        ],
      ),

      // 8. Government office
      Place(
        id: 'place-8',
        name: 'Panaji Municipal Corporation',
        category: PlaceCategory.governmentOffice,
        address: 'Panaji City, Goa 403001',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Panaji+Municipal+Corporation',
        phone: '+91 832 222 6481',
        description: 'Main municipal office in Panaji. Recently renovated with improved accessibility features.',
        latitude: 15.4989,
        longitude: 73.8282,
        friendlyScore: 6.8,
        wheelchairScore: 7.0,
        visualAccessibilityScore: 5.5,
        hearingAccessibilityScore: 6.0,
        communicationScore: 6.5,
        totalReviews: 15,
        communityConfirmations: 8,
        lastVerified: DateTime.now().subtract(const Duration(days: 30)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f50', name: 'Ramp', icon: Icons.accessible, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 7, lastConfirmed: DateTime.now().subtract(const Duration(days: 30))),
          AccessibilityFeature(id: 'f51', name: 'Elevator', icon: Icons.elevator, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 5, lastConfirmed: DateTime.now().subtract(const Duration(days: 35))),
          AccessibilityFeature(id: 'f52', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical, status: FeatureStatus.unknown),
          AccessibilityFeature(id: 'f53', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 4, lastConfirmed: DateTime.now().subtract(const Duration(days: 40))),
        ],
        reviews: [
          PlaceReview(
            id: 'r19', placeId: 'place-8', userId: 'u19', userName: 'Gopal N.',
            overallRating: 6, staffInteractionRating: 5, assistanceRating: 6,
            comment: 'The building has a ramp and elevator which is good. However, staff at the counters were not very patient or aware of how to assist people with disabilities. Long waiting times.',
            createdAt: DateTime.now().subtract(const Duration(days: 25)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.speechCommunication]),
            helpfulVotes: 12,
          ),
        ],
      ),

      // 9. College
      Place(
        id: 'place-9',
        name: 'Goa University',
        category: PlaceCategory.college,
        address: 'Taleigao Plateau, Goa 403206',
        phone: '+91 832 245 1345',
        website: 'https://unigoa.ac.in',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Goa+University+Taleigao',
        description: 'Premier university in Goa with a sprawling campus. Ongoing accessibility improvements across departments.',
        latitude: 15.4602,
        longitude: 73.8451,
        friendlyScore: 7.3,
        wheelchairScore: 6.5,
        visualAccessibilityScore: 6.8,
        hearingAccessibilityScore: 7.0,
        communicationScore: 7.5,
        totalReviews: 20,
        communityConfirmations: 12,
        lastVerified: DateTime.now().subtract(const Duration(days: 18)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f54', name: 'Ramp', icon: Icons.accessible, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 10, lastConfirmed: DateTime.now().subtract(const Duration(days: 18))),
          AccessibilityFeature(id: 'f55', name: 'Elevator', icon: Icons.elevator, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 8, lastConfirmed: DateTime.now().subtract(const Duration(days: 20))),
          AccessibilityFeature(id: 'f56', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 6, lastConfirmed: DateTime.now().subtract(const Duration(days: 25))),
          AccessibilityFeature(id: 'f57', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 9, lastConfirmed: DateTime.now().subtract(const Duration(days: 20))),
        ],
        reviews: [
          PlaceReview(
            id: 'r20', placeId: 'place-9', userId: 'u20', userName: 'Ankit D.',
            overallRating: 7, physicalAccessibilityRating: 6, facilitiesRating: 6,
            comment: 'The newer buildings have good accessibility, but the older departments are still challenging. Library has ramp access and the campus is mostly flat which helps.',
            createdAt: DateTime.now().subtract(const Duration(days: 12)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.wheelchairMobility]),
            helpfulVotes: 8,
          ),
        ],
      ),

      // 10. Repair & Support
      Place(
        id: 'place-10',
        name: 'Mobility Solutions Goa',
        category: PlaceCategory.repairSupport,
        address: 'Mapusa, Goa 403507',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Mapusa+Market+Goa',
        phone: '+91 832 226 3456',
        description: 'Wheelchair repair, mobility equipment sales and rental, and accessibility equipment services. Walk-in welcome.',
        latitude: 15.5937,
        longitude: 73.8103,
        friendlyScore: 9.5,
        wheelchairScore: 10.0,
        visualAccessibilityScore: 8.0,
        hearingAccessibilityScore: 8.5,
        communicationScore: 9.2,
        totalReviews: 18,
        communityConfirmations: 14,
        lastVerified: DateTime.now().subtract(const Duration(days: 4)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f58', name: 'Step-free entrance', icon: Icons.door_front_door, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 14, lastConfirmed: DateTime.now().subtract(const Duration(days: 4))),
          AccessibilityFeature(id: 'f59', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 10, lastConfirmed: DateTime.now().subtract(const Duration(days: 8))),
          AccessibilityFeature(id: 'f60', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 14, lastConfirmed: DateTime.now().subtract(const Duration(days: 4))),
          AccessibilityFeature(id: 'f61', name: 'Written communication', icon: Icons.edit_note, category: AccessibilityCategory.communication, status: FeatureStatus.available, confirmationCount: 8, lastConfirmed: DateTime.now().subtract(const Duration(days: 10))),
        ],
        reviews: [
          PlaceReview(
            id: 'r21', placeId: 'place-10', userId: 'u21', userName: 'Suresh W.',
            overallRating: 10, staffInteractionRating: 10, assistanceRating: 10,
            comment: 'Absolute lifesaver! Fixed my wheelchair within an hour. Staff understood exactly what I needed and the shop is fully accessible. They even have loaner wheelchairs.',
            createdAt: DateTime.now().subtract(const Duration(days: 7)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.wheelchairMobility]),
            helpfulVotes: 25,
          ),
        ],
      ),

      // 11. Community Center
      Place(
        id: 'place-11',
        name: 'Panaji Community Centre',
        category: PlaceCategory.communityCenter,
        address: 'Fontainhas, Panaji, Goa 403001',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Fontainhas+Heritage+Quarter+Panaji',
        description: 'Community center hosting events, workshops, and social gatherings. Active accessibility improvement program.',
        latitude: 15.4956,
        longitude: 73.8312,
        friendlyScore: 8.2,
        wheelchairScore: 7.8,
        visualAccessibilityScore: 8.0,
        hearingAccessibilityScore: 8.8,
        communicationScore: 8.5,
        totalReviews: 25,
        communityConfirmations: 18,
        lastVerified: DateTime.now().subtract(const Duration(days: 6)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f62', name: 'Ramp', icon: Icons.accessible, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 15, lastConfirmed: DateTime.now().subtract(const Duration(days: 6))),
          AccessibilityFeature(id: 'f63', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 12, lastConfirmed: DateTime.now().subtract(const Duration(days: 10))),
          AccessibilityFeature(id: 'f64', name: 'Sign language support', icon: Icons.sign_language, category: AccessibilityCategory.hearing, status: FeatureStatus.available, confirmationCount: 8, lastConfirmed: DateTime.now().subtract(const Duration(days: 15))),
          AccessibilityFeature(id: 'f65', name: 'Visual announcements', icon: Icons.tv, category: AccessibilityCategory.hearing, status: FeatureStatus.available, confirmationCount: 10, lastConfirmed: DateTime.now().subtract(const Duration(days: 8))),
          AccessibilityFeature(id: 'f66', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 16, lastConfirmed: DateTime.now().subtract(const Duration(days: 6))),
        ],
        reviews: [
          PlaceReview(
            id: 'r22', placeId: 'place-11', userId: 'u22', userName: 'Anita K.',
            overallRating: 9, staffInteractionRating: 9, communicationRating: 9, assistanceRating: 9,
            comment: 'Wonderful community space. They have sign language interpreters at most events and staff are trained in basic accessibility awareness. Truly inclusive.',
            createdAt: DateTime.now().subtract(const Duration(days: 8)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.deafHardOfHearing]),
            helpfulVotes: 16,
          ),
          PlaceReview(
            id: 'r23', placeId: 'place-11', userId: 'u23', userName: 'David L.',
            overallRating: 8, staffInteractionRating: 8, communicationRating: 8,
            comment: 'Good accessibility overall. The center hosts regular disability awareness events. Staff are patient and willing to accommodate different communication needs.',
            createdAt: DateTime.now().subtract(const Duration(days: 20)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.speechCommunication]),
            helpfulVotes: 10,
          ),
        ],
      ),

      // 12. Clinic
      Place(
        id: 'place-12',
        name: 'Manipal Hospital Goa',
        category: PlaceCategory.clinic,
        address: 'Dona Paula, Goa 403004',
        phone: '+91 832 245 3333',
        website: 'https://manipalhospitals.com/goa',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Manipal+Hospitals+Goa+Dona+Paula',
        description: 'Private multi-specialty hospital with modern facilities and comprehensive accessibility features.',
        latitude: 15.4555,
        longitude: 73.8534,
        friendlyScore: 9.1,
        wheelchairScore: 9.3,
        visualAccessibilityScore: 8.8,
        hearingAccessibilityScore: 8.0,
        communicationScore: 8.7,
        totalReviews: 48,
        communityConfirmations: 32,
        lastVerified: DateTime.now().subtract(const Duration(days: 2)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f67', name: 'Ramp', icon: Icons.accessible, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 28, lastConfirmed: DateTime.now().subtract(const Duration(days: 2))),
          AccessibilityFeature(id: 'f68', name: 'Elevator', icon: Icons.elevator, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 30, lastConfirmed: DateTime.now().subtract(const Duration(days: 3))),
          AccessibilityFeature(id: 'f69', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 25, lastConfirmed: DateTime.now().subtract(const Duration(days: 5))),
          AccessibilityFeature(id: 'f70', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 30, lastConfirmed: DateTime.now().subtract(const Duration(days: 2))),
          AccessibilityFeature(id: 'f71', name: 'Accessible parking', icon: Icons.local_parking, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 20, lastConfirmed: DateTime.now().subtract(const Duration(days: 7))),
          AccessibilityFeature(id: 'f72', name: 'Wide entrance', icon: Icons.door_front_door, category: AccessibilityCategory.physical, status: FeatureStatus.available, confirmationCount: 22, lastConfirmed: DateTime.now().subtract(const Duration(days: 4))),
          AccessibilityFeature(id: 'f73', name: 'Tactile guidance', icon: Icons.touch_app, category: AccessibilityCategory.visual, status: FeatureStatus.available, confirmationCount: 10, lastConfirmed: DateTime.now().subtract(const Duration(days: 15))),
        ],
        reviews: [
          PlaceReview(
            id: 'r24', placeId: 'place-12', userId: 'u24', userName: 'Pooja S.',
            overallRating: 9, staffInteractionRating: 10, assistanceRating: 10, physicalAccessibilityRating: 9,
            comment: 'Excellent hospital with top-notch accessibility. Every floor is wheelchair accessible, staff are trained, and they even have dedicated assistance for patients with disabilities.',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.paAssisted, accessibilityNeeds: [AccessibilityNeed.wheelchairMobility]),
            helpfulVotes: 20,
          ),
          PlaceReview(
            id: 'r25', placeId: 'place-12', userId: 'u25', userName: 'Rohit G.',
            overallRating: 9, staffInteractionRating: 9, communicationRating: 9,
            comment: 'The tactile guidance throughout the hospital is excellent. Reception staff are well-trained and patient. Audio announcements help with navigation.',
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo, accessibilityNeeds: [AccessibilityNeed.blindLowVision]),
            helpfulVotes: 14,
          ),
        ],
      ),
      Place(
        id: 'place-13',
        name: 'Panaji Bus Stand',
        category: PlaceCategory.busStop,
        address: 'Patto Centre, Panaji, Goa 403001',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Panaji+Bus+Stand+Goa',
        description: 'Main bus terminal connecting Panaji to all parts of Goa.',
        latitude: 15.4980,
        longitude: 73.8375,
        friendlyScore: 7.0,
        wheelchairScore: 6.5,
        visualAccessibilityScore: 6.0,
        hearingAccessibilityScore: 7.5,
        communicationScore: 7.0,
        totalReviews: 40,
        communityConfirmations: 25,
        lastVerified: DateTime.now().subtract(const Duration(days: 5)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f74', name: 'Tactile paving', icon: Icons.touch_app, category: AccessibilityCategory.visual, status: FeatureStatus.available),
        ],
        reviews: [],
      ),
      Place(
        id: 'place-14',
        name: 'Apollo Pharmacy',
        category: PlaceCategory.pharmacy,
        address: 'MG Road, Panaji, Goa 403001',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Apollo+Pharmacy+Panaji+Goa',
        description: '24/7 Pharmacy with wheelchair accessible ramp.',
        latitude: 15.4950,
        longitude: 73.8250,
        friendlyScore: 8.5,
        wheelchairScore: 9.0,
        visualAccessibilityScore: 8.0,
        hearingAccessibilityScore: 8.0,
        communicationScore: 8.5,
        totalReviews: 12,
        communityConfirmations: 8,
        lastVerified: DateTime.now().subtract(const Duration(days: 2)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f75', name: 'Ramp', icon: Icons.accessible, category: AccessibilityCategory.physical, status: FeatureStatus.available),
        ],
        reviews: [],
      ),
      Place(
        id: 'place-15',
        name: 'HDFC Bank ATM',
        category: PlaceCategory.atm,
        address: '18th June Road, Panaji, Goa 403001',
        directionsUrl: 'https://www.google.com/maps/search/?api=1&query=HDFC+Bank+ATM+18th+June+Road+Panaji',
        description: 'Voice-enabled ATM with braille keys.',
        latitude: 15.4965,
        longitude: 73.8220,
        friendlyScore: 9.0,
        wheelchairScore: 8.5,
        visualAccessibilityScore: 9.5,
        hearingAccessibilityScore: 9.0,
        communicationScore: 9.0,
        totalReviews: 15,
        communityConfirmations: 10,
        lastVerified: DateTime.now().subtract(const Duration(days: 1)),
        accessibilityFeatures: [
          AccessibilityFeature(id: 'f76', name: 'Braille keypad', icon: Icons.touch_app, category: AccessibilityCategory.visual, status: FeatureStatus.available),
          AccessibilityFeature(id: 'f77', name: 'Audio jack', icon: Icons.headphones, category: AccessibilityCategory.visual, status: FeatureStatus.available),
        ],
        reviews: [],
      ),
    ];
  }
}
