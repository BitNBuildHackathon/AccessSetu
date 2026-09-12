import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/shared/models/accessibility_need.dart';

/// Modern, welcoming initial screen when launching AccessSetu.
/// Introduces core capabilities and allows quick 1-tap disability focus selection
/// or immediate entry to the interactive map.
class WelcomeOnboardingScreen extends StatefulWidget {
  const WelcomeOnboardingScreen({super.key});

  @override
  State<WelcomeOnboardingScreen> createState() => _WelcomeOnboardingScreenState();
}

class _WelcomeOnboardingScreenState extends State<WelcomeOnboardingScreen> {
  final Set<AccessibilityNeed> _selectedNeeds = {};

  @override
  void initState() {
    super.initState();
    final currentNeeds = context.read<AppState>().profile.accessibilityNeeds;
    _selectedNeeds.addAll(currentNeeds);
  }

  void _toggleNeed(AccessibilityNeed need) {
    setState(() {
      if (_selectedNeeds.contains(need)) {
        _selectedNeeds.remove(need);
      } else {
        _selectedNeeds.add(need);
      }
    });
  }

  void _finishAndEnterMap(BuildContext context) {
    final state = context.read<AppState>();
    
    // Save selected needs
    for (final need in AccessibilityNeed.values) {
      final isCurrentlySet = state.profile.accessibilityNeeds.contains(need);
      final shouldBeSet = _selectedNeeds.contains(need);
      if (isCurrentlySet != shouldBeSet) {
        state.toggleNeed(need);
      }
    }

    state.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Brand Logo & Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.accessibility_new_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'AccessSetu',
                style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Personal Accessibility GPS & Verified Community Discovery for India',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Feature Highlights Grid / Cards
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.borderRadiusLg,
                  border: Border.all(color: AppColors.divider),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: const [
                    _FeatureRow(
                      icon: Icons.map,
                      iconColor: Colors.teal,
                      title: 'Accessible Discovery & Navigation',
                      subtitle: 'Find verified step-free venues, ramps, wide doors, and hospitals in Goa.',
                    ),
                    Divider(height: 20),
                    _FeatureRow(
                      icon: Icons.explore,
                      iconColor: Colors.blue,
                      title: 'Lazarillo Spoken Guidance',
                      subtitle: '360° audio explorer and spoken landmarks ("Where Am I?") for blind navigation.',
                    ),
                    Divider(height: 20),
                    _FeatureRow(
                      icon: Icons.badge,
                      iconColor: Colors.amber,
                      title: 'Digital Assistance ID & Medical Card',
                      subtitle: 'Offline accessibility assistance ID and stored documents to assist conductors and officials.',
                    ),
                    Divider(height: 20),
                    _FeatureRow(
                      icon: Icons.emergency,
                      iconColor: Colors.red,
                      title: 'Smart SOS Safety Beacon',
                      subtitle: 'Voice broadcast, ICE medical QR code, and accidental-tap protection.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Quick Persona / Need Selection (Optional)
              Text(
                'Select your accessibility focus (Optional)',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to customize guidance now, or change anytime in your profile:',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AccessibilityNeed.values.map((need) {
                  final isSelected = _selectedNeeds.contains(need);
                  return FilterChip(
                    avatar: Icon(
                      need.icon,
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    label: Text(need.displayName),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => _toggleNeed(need),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Primary Action: Open Map
              Semantics(
                button: true,
                label: 'Get started and open the accessible map',
                child: ElevatedButton.icon(
                  onPressed: () => _finishAndEnterMap(context),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('GET STARTED & EXPLORE MAP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadii.borderRadiusMd,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Assistant Mode Hint
              Center(
                child: Text(
                  'Traveling with an assistant? Toggle Personal Assistant (PA) mode anytime in Profile & Settings.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
