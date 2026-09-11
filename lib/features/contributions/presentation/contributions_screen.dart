import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ContributionsScreen extends StatelessWidget {
  const ContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Your Contributions')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadii.borderRadiusLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.communityPoints.toString(),
                  style: AppTypography.scoreDisplay.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                Text(
                  'Community Points',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _MetricTile(label: 'Reviews', value: profile.reviewCount)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _MetricTile(label: 'Updates', value: profile.accessibilityUpdates)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _MetricTile(label: 'Photos', value: profile.photoCount)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Recent Activity', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          ...profile.recentActivity.map(
            (activity) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.successLight,
                  foregroundColor: AppColors.success,
                  child: Text('+${activity.pointsEarned}'),
                ),
                title: Text(activity.description),
                subtitle: Text(DateFormat.yMMMd().add_jm().format(activity.timestamp)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(value.toString(), style: AppTypography.headlineMedium),
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
