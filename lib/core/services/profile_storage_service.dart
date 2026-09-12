import 'dart:convert';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/travel_mode.dart';
import 'package:access_map/shared/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileStorageService {
  static const String _profileKey = 'user_profile_v2';

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    
    final map = {
      'id': profile.id,
      'displayName': profile.displayName,
      'travelMode': profile.travelMode.name,
      'accessibilityNeeds': profile.accessibilityNeeds.map((n) => n.name).toList(),
      'communityPoints': profile.communityPoints,
      'reviewCount': profile.reviewCount,
      'accessibilityUpdates': profile.accessibilityUpdates,
      'photoCount': profile.photoCount,
      'onboardingComplete': profile.onboardingComplete,
      'medicalInfo': profile.medicalInfo != null ? {
        'condition': profile.medicalInfo!.condition,
        'allergies': profile.medicalInfo!.allergies,
        'instructions': profile.medicalInfo!.instructions,
        'udidNumber': profile.medicalInfo!.udidNumber,
        'disabilityCategory': profile.medicalInfo!.disabilityCategory,
        'disabilityPercentage': profile.medicalInfo!.disabilityPercentage,
        'issuingAuthority': profile.medicalInfo!.issuingAuthority,
        'issueDate': profile.medicalInfo!.issueDate,
        'bloodGroup': profile.medicalInfo!.bloodGroup,
        'hasUploadedDocument': profile.medicalInfo!.hasUploadedDocument,
        'documentName': profile.medicalInfo!.documentName,
      } : null,
      'emergencyContacts': profile.emergencyContacts.map((c) => {
        'name': c.name,
        'phone': c.phone,
        'relation': c.relation,
      }).toList(),
      // Simplifying recentActivity for the hackathon MVP persistence
      'recentActivity': profile.recentActivity.map((a) => {
        'id': a.id,
        'type': a.type.name,
        'description': a.description,
        'pointsEarned': a.pointsEarned,
        'timestamp': a.timestamp.toIso8601String(),
        'placeId': a.placeId,
        'placeName': a.placeName,
      }).toList(),
    };

    await prefs.setString(_profileKey, jsonEncode(map));
  }

  Future<UserProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_profileKey);
    
    if (data == null) return null;

    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      
      return UserProfile(
        id: map['id'] as String,
        displayName: map['displayName'] as String,
        travelMode: TravelMode.values.firstWhere(
          (m) => m.name == map['travelMode'],
          orElse: () => TravelMode.solo,
        ),
        accessibilityNeeds: (map['accessibilityNeeds'] as List<dynamic>)
            .map((n) => AccessibilityNeed.values.firstWhere(
                  (need) => need.name == n,
                  orElse: () => AccessibilityNeed.blindLowVision,
                ))
            .toList(),
        communityPoints: map['communityPoints'] as int? ?? 0,
        reviewCount: map['reviewCount'] as int? ?? 0,
        accessibilityUpdates: map['accessibilityUpdates'] as int? ?? 0,
        photoCount: map['photoCount'] as int? ?? 0,
        onboardingComplete: map['onboardingComplete'] as bool? ?? false,
        medicalInfo: map['medicalInfo'] != null ? MedicalInfo(
          condition: map['medicalInfo']['condition'] as String? ?? '',
          allergies: map['medicalInfo']['allergies'] as String? ?? '',
          instructions: map['medicalInfo']['instructions'] as String? ?? '',
          udidNumber: map['medicalInfo']['udidNumber'] as String? ?? '',
          disabilityCategory: map['medicalInfo']['disabilityCategory'] as String? ?? '',
          disabilityPercentage: map['medicalInfo']['disabilityPercentage'] as String? ?? '',
          issuingAuthority: map['medicalInfo']['issuingAuthority'] as String? ?? '',
          issueDate: map['medicalInfo']['issueDate'] as String? ?? '',
          bloodGroup: map['medicalInfo']['bloodGroup'] as String? ?? '',
          hasUploadedDocument: map['medicalInfo']['hasUploadedDocument'] as bool? ?? false,
          documentName: map['medicalInfo']['documentName'] as String? ?? '',
        ) : null,
        emergencyContacts: (map['emergencyContacts'] as List<dynamic>?)?.map((c) {
          final cMap = c as Map<String, dynamic>;
          return EmergencyContact(
            name: cMap['name'] as String,
            phone: cMap['phone'] as String,
            relation: cMap['relation'] as String,
          );
        }).toList() ?? [],
        recentActivity: (map['recentActivity'] as List<dynamic>?)?.map((a) {
              final aMap = a as Map<String, dynamic>;
              return CommunityContribution(
                id: aMap['id'] as String,
                type: ContributionType.values.firstWhere(
                  (t) => t.name == aMap['type'],
                  orElse: () => ContributionType.review,
                ),
                description: aMap['description'] as String,
                pointsEarned: aMap['pointsEarned'] as int,
                timestamp: DateTime.parse(aMap['timestamp'] as String),
                placeId: aMap['placeId'] as String?,
                placeName: aMap['placeName'] as String?,
              );
            }).toList() ?? [],
      );
    } catch (e) {
      // If parsing fails due to schema changes, return null to start fresh
      return null;
    }
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}
