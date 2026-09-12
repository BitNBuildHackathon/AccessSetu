import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/travel_mode.dart';
import 'package:access_map/features/profile/presentation/edit_profile_screen.dart';
import 'package:access_map/features/profile/presentation/disability_pass_screen.dart';
import 'package:access_map/features/profile/presentation/offline_maps_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile & Emergency Info',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const EditProfileScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        key: const ValueKey('profile-list'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // User Card with Name & Quick Edit
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primarySurface,
                        foregroundColor: AppColors.primary,
                        child: Icon(Icons.person, size: 36),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: AppTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${profile.travelMode.displayName} • ${profile.accessibilityNeeds.isEmpty ? "No specific need selected" : profile.accessibilityNeeds.map((n) => n.displayName).join(", ")}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Name, Medical Details & ICE Contacts'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Digital Disability Pass & UDID Certificate (1-Tap for Conductors / Security)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.borderRadiusLg,
              side: const BorderSide(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.badge, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'ACCESSIBILITY ID PASS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'DOC ON FILE',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reg / UDID: ${profile.medicalInfo?.udidNumber.isNotEmpty == true ? profile.medicalInfo!.udidNumber : 'GA0710119950034512'}',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.medicalInfo?.disabilityCategory.isNotEmpty == true ? profile.medicalInfo!.disabilityCategory : 'Visual Impairment (Low Vision)'} • ${profile.medicalInfo?.disabilityPercentage.isNotEmpty == true ? profile.medicalInfo!.disabilityPercentage : '75% Permanent'}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Semantics(
                        button: true,
                        label: 'Show Digital Disability Pass and Medical Certificate to official or conductor',
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DisabilityPassScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.badge, size: 20),
                          label: const Text('SHOW ASSISTANCE PASS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Emergency Medical Profile Overview
          Text('Emergency Medical ID (ICE)', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.borderRadiusMd,
              side: const BorderSide(color: AppColors.divider),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medical_services, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Primary Condition: ',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          (profile.medicalInfo?.condition.isNotEmpty ?? false)
                              ? profile.medicalInfo!.condition
                              : 'Not specified yet',
                          style: AppTypography.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Allergies: ',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          (profile.medicalInfo?.allergies.isNotEmpty ?? false)
                              ? profile.medicalInfo!.allergies
                              : 'None recorded',
                          style: AppTypography.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.contacts, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Emergency Contacts: ',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${profile.emergencyContacts.length} contact(s) saved',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Travel Mode
          Text('Travel Mode', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<TravelMode>(
            segments: TravelMode.values
                .map(
                  (mode) => ButtonSegment<TravelMode>(
                    value: mode,
                    label: Text(mode.displayName),
                    icon: Icon(mode == TravelMode.paAssisted
                        ? Icons.handshake
                        : Icons.person_pin_circle),
                  ),
                )
                .toList(),
            selected: {profile.travelMode},
            onSelectionChanged: (selection) {
              context.read<AppState>().updateProfile(travelMode: selection.first);
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Accessibility Needs
          Text('Accessibility Needs', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          ...AccessibilityNeed.values.map(
            (need) => CheckboxListTile(
              value: profile.accessibilityNeeds.contains(need),
              secondary: Icon(need.icon, color: AppColors.primary),
              title: Text(need.displayName),
              subtitle: Text(need.description),
              onChanged: (_) => context.read<AppState>().toggleNeed(need),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Spoken Language (TTS)
          Text('Voice Language (TTS)', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: state.ttsLanguage,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Select Spoken Language',
            ),
            items: const [
              DropdownMenuItem(value: 'en-US', child: Text('English (US/UK)')),
              DropdownMenuItem(value: 'hi-IN', child: Text('Hindi (hi-IN)')),
            ],
            onChanged: (value) {
              if (value != null) {
                context.read<AppState>().setTTSLanguage(value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Offline Regional Maps
          Text('Offline Maps & Storage', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.borderRadiusMd,
              side: const BorderSide(color: AppColors.divider),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primarySurface,
                child: Icon(Icons.download_for_offline, color: AppColors.primary),
              ),
              title: const Text('Offline Regional Maps', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${state.offlineMapService.totalDownloadedMb} MB saved • Tap to download regional packs',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OfflineMapsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Wheelchair score policy notice
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: profile.shouldShowWheelchairScore
                  ? AppColors.successLight
                  : AppColors.surfaceVariant,
              borderRadius: AppRadii.borderRadiusMd,
            ),
            child: Row(
              children: [
                Icon(
                  profile.shouldShowWheelchairScore
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: profile.shouldShowWheelchairScore
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    profile.shouldShowWheelchairScore
                        ? 'Wheelchair-Friendly scores are prioritized for your profile.'
                        : 'Wheelchair-Friendly scores will be highlighted when physical or wheelchair needs are selected.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
