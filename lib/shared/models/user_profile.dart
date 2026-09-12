import 'accessibility_need.dart';
import 'travel_mode.dart';

class MedicalInfo {
  final String condition;
  final String allergies;
  final String instructions;
  final String udidNumber;
  final String disabilityCategory;
  final String disabilityPercentage;
  final String issuingAuthority;
  final String issueDate;
  final String bloodGroup;
  final bool hasUploadedDocument;
  final String documentName;

  const MedicalInfo({
    this.condition = '',
    this.allergies = '',
    this.instructions = '',
    this.udidNumber = '',
    this.disabilityCategory = '',
    this.disabilityPercentage = '',
    this.issuingAuthority = '',
    this.issueDate = '',
    this.bloodGroup = '',
    this.hasUploadedDocument = false,
    this.documentName = '',
  });

  MedicalInfo copyWith({
    String? condition,
    String? allergies,
    String? instructions,
    String? udidNumber,
    String? disabilityCategory,
    String? disabilityPercentage,
    String? issuingAuthority,
    String? issueDate,
    String? bloodGroup,
    bool? hasUploadedDocument,
    String? documentName,
  }) {
    return MedicalInfo(
      condition: condition ?? this.condition,
      allergies: allergies ?? this.allergies,
      instructions: instructions ?? this.instructions,
      udidNumber: udidNumber ?? this.udidNumber,
      disabilityCategory: disabilityCategory ?? this.disabilityCategory,
      disabilityPercentage: disabilityPercentage ?? this.disabilityPercentage,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      issueDate: issueDate ?? this.issueDate,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      hasUploadedDocument: hasUploadedDocument ?? this.hasUploadedDocument,
      documentName: documentName ?? this.documentName,
    );
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
  });
}

/// Activity type for community contributions.
enum ContributionType {
  review,
  accessibilityUpdate,
  photoUpload,
  confirmation,
  helpfulVote;

  String get displayName {
    switch (this) {
      case ContributionType.review:
        return 'Review';
      case ContributionType.accessibilityUpdate:
        return 'Accessibility Update';
      case ContributionType.photoUpload:
        return 'Photo Upload';
      case ContributionType.confirmation:
        return 'Confirmation';
      case ContributionType.helpfulVote:
        return 'Helpful Vote';
    }
  }

  int get pointsEarned {
    switch (this) {
      case ContributionType.review:
        return 5;
      case ContributionType.accessibilityUpdate:
        return 5;
      case ContributionType.photoUpload:
        return 10;
      case ContributionType.confirmation:
        return 3;
      case ContributionType.helpfulVote:
        return 2;
    }
  }
}

/// A single community contribution activity.
class CommunityContribution {
  final String id;
  final ContributionType type;
  final String description;
  final int pointsEarned;
  final DateTime timestamp;
  final String? placeId;
  final String? placeName;

  const CommunityContribution({
    required this.id,
    required this.type,
    required this.description,
    required this.pointsEarned,
    required this.timestamp,
    this.placeId,
    this.placeName,
  });
}

/// User profile for the current session.
class UserProfile {
  final String id;
  final String displayName;
  final TravelMode travelMode;
  final List<AccessibilityNeed> accessibilityNeeds;
  final int communityPoints;
  final int reviewCount;
  final int accessibilityUpdates;
  final int photoCount;
  final List<CommunityContribution> recentActivity;
  final bool onboardingComplete;
  final MedicalInfo? medicalInfo;
  final List<EmergencyContact> emergencyContacts;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.travelMode,
    required this.accessibilityNeeds,
    this.communityPoints = 0,
    this.reviewCount = 0,
    this.accessibilityUpdates = 0,
    this.photoCount = 0,
    this.recentActivity = const [],
    this.onboardingComplete = false,
    this.medicalInfo,
    this.emergencyContacts = const [],
  });

  /// Check if the user's profile warrants showing wheelchair-specific score.
  bool get shouldShowWheelchairScore => accessibilityNeeds.any(
        (need) => need.isPhysicalAccessibility,
      );

  UserProfile copyWith({
    String? displayName,
    TravelMode? travelMode,
    List<AccessibilityNeed>? accessibilityNeeds,
    int? communityPoints,
    int? reviewCount,
    int? accessibilityUpdates,
    int? photoCount,
    List<CommunityContribution>? recentActivity,
    bool? onboardingComplete,
    MedicalInfo? medicalInfo,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      travelMode: travelMode ?? this.travelMode,
      accessibilityNeeds: accessibilityNeeds ?? this.accessibilityNeeds,
      communityPoints: communityPoints ?? this.communityPoints,
      reviewCount: reviewCount ?? this.reviewCount,
      accessibilityUpdates: accessibilityUpdates ?? this.accessibilityUpdates,
      photoCount: photoCount ?? this.photoCount,
      recentActivity: recentActivity ?? this.recentActivity,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }

  /// Default profile with initial realistic demo data
  static UserProfile empty() => UserProfile(
        id: 'user-1',
        displayName: 'Aarav Sharma',
        travelMode: TravelMode.solo,
        accessibilityNeeds: const [],
        communityPoints: 125,
        reviewCount: 3,
        accessibilityUpdates: 8,
        photoCount: 2,
        medicalInfo: const MedicalInfo(
          condition: 'Low vision / requires audio guidance & high contrast',
          allergies: 'Penicillin',
          instructions: 'Carries white cane. Guide by offering arm.',
          udidNumber: 'GA0710119950034512',
          disabilityCategory: 'Visual Impairment (Low Vision)',
          disabilityPercentage: '75% Permanent',
          issuingAuthority: 'Goa Medical College (GMC) & Hospital, Bambolim',
          issueDate: '12/03/2023',
          bloodGroup: 'B+ Positive',
          hasUploadedDocument: true,
          documentName: 'Govt_UDID_Certificate_Aarav.pdf',
        ),
        emergencyContacts: const [
          EmergencyContact(name: 'Raj Sharma', phone: '+919876543210', relation: 'Brother'),
          EmergencyContact(name: 'Dr. Anita Desai', phone: '+919822112233', relation: 'Physician'),
        ],
        recentActivity: [
          CommunityContribution(
            id: 'c-1',
            type: ContributionType.accessibilityUpdate,
            description: 'Confirmed step-free entrance & ramp at Panaji Bus Stand',
            pointsEarned: 5,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            placeName: 'Panaji Bus Stand',
          ),
          CommunityContribution(
            id: 'c-2',
            type: ContributionType.review,
            description: 'Added detailed sensory & accessibility review for Fishka Restaurant',
            pointsEarned: 10,
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            placeName: 'Fishka Restaurant',
          ),
          CommunityContribution(
            id: 'c-3',
            type: ContributionType.photoUpload,
            description: 'Uploaded tactile paving & accessible entrance photo at Goa Medical College',
            pointsEarned: 10,
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            placeName: 'Goa Medical College',
          ),
          CommunityContribution(
            id: 'c-4',
            type: ContributionType.confirmation,
            description: 'Verified audible elevator signals at Mall de Goa',
            pointsEarned: 3,
            timestamp: DateTime.now().subtract(const Duration(days: 4)),
            placeName: 'Mall de Goa',
          ),
        ],
      );
}
