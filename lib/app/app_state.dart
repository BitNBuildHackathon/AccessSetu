import 'package:access_map/core/services/navigation_service.dart';
import 'package:access_map/core/services/voice_search_service.dart';
import 'package:access_map/features/map/data/mock_place_repository.dart';
import 'package:access_map/shared/models/accessibility_feature.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_review.dart';
import 'package:access_map/shared/models/travel_mode.dart';
import 'package:access_map/shared/models/user_profile.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  AppState({
    PlaceRepository? placeRepository,
    VoiceSearchService? voiceSearchService,
    NavigationService? navigationService,
  })  : _placeRepository = placeRepository ?? MockPlaceRepository(),
        _voiceSearchService = voiceSearchService ?? SpeechToTextService(),
        _navigationService = navigationService ?? NavigationService();

  final PlaceRepository _placeRepository;
  final VoiceSearchService _voiceSearchService;
  final NavigationService _navigationService;

  UserProfile _profile = UserProfile.mockUser().copyWith(
    onboardingComplete: false,
    accessibilityNeeds: const [],
  );
  List<Place> _places = [];
  List<Place> _visiblePlaces = [];
  Place? _selectedPlace;
  String _searchQuery = '';
  bool _isLoadingPlaces = true;
  bool _isSearching = false;
  bool _hasSelectedTravelMode = false;
  String? _errorMessage;
  int _tabIndex = 0;

  UserProfile get profile => _profile;
  List<Place> get places => _places;
  List<Place> get visiblePlaces => _visiblePlaces;
  Place? get selectedPlace => _selectedPlace;
  String get searchQuery => _searchQuery;
  bool get isLoadingPlaces => _isLoadingPlaces;
  bool get isSearching => _isSearching;
  bool get isListening => _voiceSearchService.isListening;
  bool get hasSelectedTravelMode => _hasSelectedTravelMode;
  String? get errorMessage => _errorMessage;
  int get tabIndex => _tabIndex;

  Future<void> loadPlaces() async {
    _isLoadingPlaces = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _places = await _placeRepository.getNearbyPlaces(15.4909, 73.8278);
      _visiblePlaces = _places;
      _selectedPlace = _places.isNotEmpty ? _places.first : null;
    } catch (_) {
      _errorMessage = "Couldn't load nearby places. Please try again.";
    } finally {
      _isLoadingPlaces = false;
      notifyListeners();
    }
  }

  void selectTravelMode(TravelMode mode) {
    _hasSelectedTravelMode = true;
    _profile = _profile.copyWith(travelMode: mode);
    notifyListeners();
  }

  void toggleNeed(AccessibilityNeed need) {
    final needs = List<AccessibilityNeed>.from(_profile.accessibilityNeeds);
    if (needs.contains(need)) {
      needs.remove(need);
    } else {
      needs.add(need);
    }
    _profile = _profile.copyWith(accessibilityNeeds: needs);
    notifyListeners();
  }

  void completeOnboarding() {
    _profile = _profile.copyWith(onboardingComplete: true);
    notifyListeners();
  }

  void updateDemoProfile({
    TravelMode? travelMode,
    List<AccessibilityNeed>? needs,
  }) {
    _profile = _profile.copyWith(
      travelMode: travelMode,
      accessibilityNeeds: needs,
      onboardingComplete: true,
    );
    notifyListeners();
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _visiblePlaces = _places;
      _isSearching = false;
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    _visiblePlaces = await _placeRepository.searchPlaces(query);
    _isSearching = false;
    notifyListeners();
  }

  void selectPlace(Place place) {
    _selectedPlace = place;
    notifyListeners();
  }

  void changeTab(int index) {
    _tabIndex = index;
    notifyListeners();
  }

  Future<String?> startVoiceSearch() async {
    String? userMessage;
    await _voiceSearchService.startListening(
      onResult: (text) => search(text),
      onDone: notifyListeners,
      onError: (error) {
        userMessage = error;
        notifyListeners();
      },
    );
    notifyListeners();
    return userMessage;
  }

  Future<bool> openDirections(Place place) {
    return _navigationService.openExternalDirections(place);
  }

  Future<void> addReview({
    required Place place,
    required double overall,
    required double staff,
    required double communication,
    required double assistance,
    required double physical,
    required double facilities,
    required String comment,
  }) async {
    final review = PlaceReview(
      id: 'review-${DateTime.now().microsecondsSinceEpoch}',
      placeId: place.id,
      userId: _profile.id,
      userName: _profile.displayName,
      overallRating: overall,
      staffInteractionRating: staff,
      communicationRating: communication,
      assistanceRating: assistance,
      physicalAccessibilityRating: physical,
      facilitiesRating: facilities,
      comment: comment,
      createdAt: DateTime.now(),
      reviewerContext: AccessibilityContext(
        travelMode: _profile.travelMode,
        accessibilityNeeds: _profile.accessibilityNeeds,
      ),
    );
    await _placeRepository.addReview(place.id, review);
    final refreshed = await _placeRepository.getNearbyPlaces(15.4909, 73.8278);
    _places = refreshed;
    _visiblePlaces = _searchQuery.trim().isEmpty
        ? refreshed
        : await _placeRepository.searchPlaces(_searchQuery);
    _selectedPlace = refreshed.firstWhere((p) => p.id == place.id);
    final contribution = CommunityContribution(
      id: 'contribution-${DateTime.now().microsecondsSinceEpoch}',
      type: ContributionType.review,
      description: 'Reviewed ${place.name}',
      pointsEarned: ContributionType.review.pointsEarned,
      timestamp: DateTime.now(),
      placeId: place.id,
      placeName: place.name,
    );
    _profile = _profile.copyWith(
      communityPoints:
          _profile.communityPoints + ContributionType.review.pointsEarned,
      reviewCount: _profile.reviewCount + 1,
      recentActivity: [contribution, ..._profile.recentActivity],
    );
    notifyListeners();
  }

  void markReviewHelpful(Place place, PlaceReview review) {
    final updatedReviews = place.reviews
        .map((item) => item.id == review.id
            ? item.copyWith(helpfulVotes: item.helpfulVotes + 1)
            : item)
        .toList();
    _replacePlace(place.copyWith(reviews: updatedReviews));
    final contribution = CommunityContribution(
      id: 'helpful-${DateTime.now().microsecondsSinceEpoch}',
      type: ContributionType.helpfulVote,
      description: 'Marked a review helpful at ${place.name}',
      pointsEarned: ContributionType.helpfulVote.pointsEarned,
      timestamp: DateTime.now(),
      placeId: place.id,
      placeName: place.name,
    );
    _profile = _profile.copyWith(
      communityPoints:
          _profile.communityPoints + ContributionType.helpfulVote.pointsEarned,
      recentActivity: [contribution, ..._profile.recentActivity],
    );
    notifyListeners();
  }

  void reportReview(Place place, PlaceReview review) {
    final updatedReviews = place.reviews
        .map((item) =>
            item.id == review.id ? item.copyWith(reported: true) : item)
        .toList();
    _replacePlace(place.copyWith(reviews: updatedReviews));
    notifyListeners();
  }

  /// Confirms an accessibility feature at a place and rewards community points.
  void confirmFeature(Place place, AccessibilityFeature feature) {
    final updatedFeatures = place.accessibilityFeatures
        .map((item) => item.id == feature.id
            ? item.copyWith(
                status: FeatureStatus.available,
                confirmationCount: item.confirmationCount + 1,
                lastConfirmed: DateTime.now(),
              )
            : item)
        .toList();
    _replacePlace(place.copyWith(accessibilityFeatures: updatedFeatures));
    final contribution = CommunityContribution(
      id: 'confirm-${DateTime.now().microsecondsSinceEpoch}',
      type: ContributionType.confirmation,
      description: 'Confirmed ${feature.name} at ${place.name}',
      pointsEarned: ContributionType.confirmation.pointsEarned,
      timestamp: DateTime.now(),
      placeId: place.id,
      placeName: place.name,
    );
    _profile = _profile.copyWith(
      communityPoints:
          _profile.communityPoints + ContributionType.confirmation.pointsEarned,
      accessibilityUpdates: _profile.accessibilityUpdates + 1,
      recentActivity: [contribution, ..._profile.recentActivity],
    );
    notifyListeners();
  }

  void _replacePlace(Place updatedPlace) {
    _places = _places
        .map((place) => place.id == updatedPlace.id ? updatedPlace : place)
        .toList();
    _visiblePlaces = _visiblePlaces
        .map((place) => place.id == updatedPlace.id ? updatedPlace : place)
        .toList();
    if (_selectedPlace?.id == updatedPlace.id) {
      _selectedPlace = updatedPlace;
    }
  }
}
