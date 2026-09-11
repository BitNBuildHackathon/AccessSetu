import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/travel_mode.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        key: const ValueKey('profile-list'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primarySurface,
                    foregroundColor: AppColors.primary,
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.displayName, style: AppTypography.headlineSmall),
                        Text(
                          '${profile.travelMode.displayName} - ${profile.accessibilityNeeds.map((n) => n.displayName).join(', ')}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Travel Mode', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<TravelMode>(
            segments: TravelMode.values
                .map(
                  (mode) => ButtonSegment<TravelMode>(
                    value: mode,
                    label: Text(mode.displayName),
                    icon: Icon(mode == TravelMode.paAssisted ? Icons.handshake : Icons.person_pin_circle),
                  ),
                )
                .toList(),
            selected: {profile.travelMode},
            onSelectionChanged: (selection) {
              state.updateDemoProfile(travelMode: selection.first);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Accessibility Needs', style: AppTypography.headlineSmall),
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
                        ? 'Wheelchair-Friendly scores are visible for this profile.'
                        : 'Wheelchair-Friendly scores are hidden until physical or wheelchair needs are selected.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () {
              final needs = List<AccessibilityNeed>.from(profile.accessibilityNeeds);
              if (!needs.contains(AccessibilityNeed.wheelchairUser)) {
                needs.add(AccessibilityNeed.wheelchairUser);
              }
              context.read<AppState>().updateDemoProfile(needs: needs);
            },
            icon: const Icon(Icons.accessible),
            label: const Text('Demo Wheelchair Profile'),
          ),
        ],
      ),
    );
  }
}
