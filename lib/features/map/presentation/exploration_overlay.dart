import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/services/exploration_service.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/core/services/osrm_routing_service.dart';
import 'package:access_map/features/places/presentation/place_details_screen.dart';
import 'package:access_map/shared/models/hazard_report.dart';

class ExplorationOverlay extends StatelessWidget {
  const ExplorationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final exploration = state.explorationService;

        if (!exploration.isActive) return const SizedBox.shrink();

        final isNavigating = exploration.activeDestination != null;

        return Positioned.fill(
          child: SafeArea(
            child: isNavigating
                ? _buildGoogleMapsNavigationHUD(context, exploration, state)
                : _buildCategoryExplorer(context, exploration, state),
          ),
        );
      },
    );
  }

  // ==========================================
  // 1. CATEGORY AUDIO EXPLORER VIEW
  // ==========================================
  Widget _buildCategoryExplorer(
    BuildContext context,
    ExplorationService exploration,
    AppState state,
  ) {
    final categories = [
      _ExplorerCategory(
        label: 'Hospitals & Medical',
        icon: Icons.local_hospital,
        color: const Color(0xFFDC2626),
        filter: (p) =>
            p.category == PlaceCategory.hospital ||
            p.category == PlaceCategory.clinic ||
            p.category == PlaceCategory.pharmacy,
      ),
      _ExplorerCategory(
        label: 'Bus & Transit',
        icon: Icons.directions_bus,
        color: const Color(0xFF2563EB),
        filter: (p) => p.category == PlaceCategory.busStop,
      ),
      _ExplorerCategory(
        label: 'Schools & Colleges',
        icon: Icons.school,
        color: const Color(0xFF0D9488),
        filter: (p) => p.category == PlaceCategory.college,
      ),
      _ExplorerCategory(
        label: 'Clubs & Leisure',
        icon: Icons.nightlife,
        color: const Color(0xFF9333EA),
        filter: (p) =>
            p.category == PlaceCategory.touristAttraction ||
            p.category == PlaceCategory.hotel,
      ),
      _ExplorerCategory(
        label: 'Dining & Cafes',
        icon: Icons.restaurant,
        color: const Color(0xFFEA580C),
        filter: (p) =>
            p.category == PlaceCategory.restaurant ||
            p.category == PlaceCategory.cafe,
      ),
      _ExplorerCategory(
        label: 'Banks & ATMs',
        icon: Icons.local_atm,
        color: const Color(0xFF16A34A),
        filter: (p) => p.category == PlaceCategory.atm,
      ),
    ];

    return Stack(
      children: [
        // Top Floating Compass & Close Capsule
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadii.borderRadiusFull,
                    boxShadow: AppShadows.md,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.explore, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          exploration.currentHeading != null
                              ? 'Facing ${exploration.currentHeading!.round()}°'
                              : 'Accessible Navigator',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Material(
                color: AppColors.surface,
                elevation: 3,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.error, size: 22),
                  onPressed: () => exploration.stopExploration(),
                  tooltip: 'Exit Navigator',
                ),
              ),
            ],
          ),
        ),

        // Bottom Floating Exploration Panel
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 240),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.borderRadiusLg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Action Row: Where Am I & Hazard
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final loc = await exploration.whereAmI();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF0F172A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.amberAccent, width: 1.5),
                                ),
                                content: Row(
                                  children: [
                                    const Icon(Icons.my_location, color: Colors.amberAccent, size: 20),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        loc,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.borderRadiusMd,
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.my_location, size: 16),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Where Am I?',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showReportHazardSheet(context, exploration),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.borderRadiusMd,
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Report Hazard',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Category Slider Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Explore Nearby Places',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Tap to view',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Horizontal Category Cards
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final matchingCount = state.places.where(cat.filter).length;

                      return InkWell(
                        onTap: () => _showCategoryPlacesSheet(
                          context,
                          cat,
                          state,
                          exploration,
                        ),
                        borderRadius: AppRadii.borderRadiusMd,
                        child: Container(
                          width: 104,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant.withValues(alpha: 0.35),
                            borderRadius: AppRadii.borderRadiusMd,
                            border: Border.all(
                              color: cat.color.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: cat.color.withValues(alpha: 0.15),
                                foregroundColor: cat.color,
                                child: Icon(cat.icon, size: 15),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                cat.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '$matchingCount nearby',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. GOOGLE MAPS-STYLE TURN-BY-TURN HUD
  // ==========================================
  Widget _buildGoogleMapsNavigationHUD(
    BuildContext context,
    ExplorationService exploration,
    AppState state,
  ) {
    final dest = exploration.activeDestination!;
    final totalDistance = (exploration.distanceToDestination ?? 0).round();
    final walkTime = exploration.estimatedWalkingMinutes;
    final nearbyHazard = exploration.nearbyHazard;
    final currentStep = exploration.currentStep;
    final stepDist = (exploration.currentStepRemainingMeters).round();
    final bearing = exploration.bearingToNextWaypoint;
    final heading = exploration.currentHeading;
    final speedMs = exploration.currentSpeedMs;
    final speedKmh = speedMs != null ? (speedMs * 3.6) : null;

    // Relative angle: how many degrees to turn to face the next waypoint
    double? relativeAngle;
    String turnAdvice = 'On track';
    if (bearing != null && heading != null) {
      relativeAngle = ((bearing - heading) % 360 + 360) % 360;
      final diff = relativeAngle > 180 ? relativeAngle - 360 : relativeAngle;
      if (diff.abs() <= 12) {
        turnAdvice = 'Facing route';
      } else if (diff > 0) {
        turnAdvice = 'Turn ${diff.round()}° right';
      } else {
        turnAdvice = 'Turn ${(-diff).round()}° left';
      }
    }

    final distDisplay = totalDistance >= 1000
        ? '${(totalDistance / 1000).toStringAsFixed(1)} km'
        : '$totalDistance m';

    // Walk time label
    final walkTimeLabel = walkTime == 0
        ? 'Arrived!'
        : walkTime < 60
            ? '$walkTime min'
            : '${walkTime ~/ 60}h ${walkTime % 60}m';



    return Stack(
      children: [
        // 1. TOP FLOATING GOOGLE MAPS TURN BANNER & HAZARD BANNER
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Gyro Compass Row ────────────────────────────
              Row(
                children: [
                  // Live compass arrow disk
                  _GyroCompass(relativeAngle: relativeAngle, heading: heading),
                  const SizedBox(width: AppSpacing.sm),
                  // Step countdown capsule
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: AppRadii.borderRadiusFull,
                        boxShadow: AppShadows.sm,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.near_me, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              currentStep != null
                                  ? '$turnAdvice • in ${stepDist}m'
                                  : '$turnAdvice • $distDisplay',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (speedKmh != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: AppRadii.borderRadiusFull,
                              ),
                              child: Text(
                                '${speedKmh.toStringAsFixed(1)} km/h',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // ── Turn Banner ─────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: AppRadii.borderRadiusLg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(

                      radius: 22,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F766E),
                      child: Icon(currentStep?.icon ?? Icons.navigation, size: 26),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  currentStep != null
                                      ? (stepDist <= 10 ? 'Approaching Turn' : 'In $stepDist m')
                                      : 'Accessible Navigation',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (exploration.navigationSteps.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${exploration.currentStepIndex + 1}/${exploration.navigationSteps.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  exploration.clearDestination();
                                  context.read<AppState>().clearSelectedPlace();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            exploration.navigationInstruction,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (exploration.nextTurnHint.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              exploration.nextTurnHint,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (nearbyHazard != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _buildHazardProximityBanner(context, exploration, nearbyHazard),
              ],
            ],
          ),
        ),

        // 2. BOTTOM FLOATING NAVIGATION CARD
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.borderRadiusLg,
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dest.name,
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: AppRadii.borderRadiusSm,
                        ),
                        child: Text(
                          dest.wheelchairScore >= 8.5 ? 'Step-Free' : 'Accessible',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavMetric(
                            label: 'Distance',
                            value: distDisplay,
                            icon: Icons.straighten,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: _NavMetric(
                            label: '${exploration.currentRoutingProfile.displayName} Time',
                            value: walkTimeLabel,
                            icon: exploration.currentRoutingProfile.icon,
                            isLive: speedKmh != null,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: _NavMetric(
                            label: speedKmh != null ? 'Your Speed' : 'Avg Speed',
                            value: speedKmh != null
                                ? '${speedKmh.toStringAsFixed(1)} km/h'
                                : exploration.currentRoutingProfile == OsrmProfile.car
                                    ? '~30 km/h'
                                    : exploration.currentRoutingProfile == OsrmProfile.bike
                                        ? '~15 km/h'
                                        : '~4.5 km/h',
                            icon: Icons.speed,
                            isLive: speedKmh != null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Transport Mode Toggle (Walk, Bike, Car) ──
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      children: OsrmProfile.values.map((profile) {
                        final isSelected = exploration.currentRoutingProfile == profile;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => exploration.setRoutingProfile(profile),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0F766E) : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    profile.icon,
                                    size: 15,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.displayName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Action Row: Step Ahead, Report Hazard, and End
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => exploration.stepAheadSimulated(30.0),
                          icon: Icon(exploration.currentRoutingProfile.icon, size: 14),
                          label: const Flexible(
                            child: Text(
                              'Step +30m',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadii.borderRadiusMd,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showReportHazardSheet(context, exploration),
                          icon: const Icon(Icons.warning_amber_rounded, size: 14),
                          label: const Flexible(
                            child: Text(
                              'Hazard',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadii.borderRadiusMd,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            exploration.clearDestination();
                            context.read<AppState>().clearSelectedPlace();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadii.borderRadiusMd,
                            ),
                          ),
                          child: const Text(
                            'End',
                            maxLines: 1,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Live Hazard Proximity Alert Banner (Amber/Red Card with 1-tap verification)
  Widget _buildHazardProximityBanner(
    BuildContext context,
    ExplorationService exploration,
    HazardReport hazard,
  ) {
    final distance = (exploration.distanceToLocation(hazard.latitude, hazard.longitude)).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Soft amber
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: hazard.category.color.withValues(alpha: 0.2),
                foregroundColor: hazard.category.color,
                child: Icon(hazard.category.icon, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAUTION: ${hazard.category.label} (${distance}m ahead)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: hazard.category.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${hazard.description} • ${hazard.ageLabel}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF78350F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: hazard.category.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _showHazardVoteSheet(context, exploration, hazard),
                child: const Text('Vote', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Mini vote summary bar
          Row(
            children: [
              Text(
                '${hazard.blockedVotes} blocked',
                style: const TextStyle(fontSize: 10, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: hazard.fixedVoteFraction,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                    ),
                  ),
                ),
              ),
              Text(
                '${hazard.fixedVotes} fixed',
                style: const TextStyle(fontSize: 10, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 1-Tap In-Route Hazard Reporting Modal Bottom Sheet
  void _showReportHazardSheet(BuildContext context, ExplorationService exploration) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.add_location_alt, color: Color(0xFFD97706), size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report Hazard at My Location',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Text(
                            'Live GPS: ${exploration.currentEffectiveLat.toStringAsFixed(4)}, ${exploration.currentEffectiveLng.toStringAsFixed(4)} • Earn +15 pts',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Select obstacle category to warn nearby travellers:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...[
                  HazardCategory.rampBlocked,
                  HazardCategory.liftBroken,
                  HazardCategory.unexpectedStairs,
                  HazardCategory.sidewalkBlocked,
                  HazardCategory.unsafeCrossing,
                  HazardCategory.constructionObstruction,
                  HazardCategory.waterlogging,
                ].map(
                  (cat) => Card(
                    elevation: 0,
                    color: cat.color.withValues(alpha: 0.08),
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cat.color.withValues(alpha: 0.3)),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: cat.color.withValues(alpha: 0.2),
                        foregroundColor: cat.color,
                        child: Icon(cat.icon, size: 18),
                      ),
                      title: Text(cat.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 13),
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await exploration.addHazardReport(cat);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF0F172A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.amberAccent, width: 1.5),
                              ),
                              content: Row(
                                children: [
                                  const Icon(Icons.stars, color: Colors.amberAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Reported "${cat.label}" at your location! +15 impact points earned.'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HAZARD COMMUNITY VOTE SHEET
  // ==========================================
  void _showHazardVoteSheet(
    BuildContext context,
    ExplorationService exploration,
    HazardReport hazard,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final blockedWinning = hazard.communityVerdictIsBlocked;
          final total = hazard.totalVotes;
          final fixedPct = total == 0 ? 0 : ((hazard.fixedVotes / total) * 100).round();
          final blockedPct = 100 - fixedPct;

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: hazard.category.color.withValues(alpha: 0.15),
                        foregroundColor: hazard.category.color,
                        child: Icon(hazard.category.icon, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hazard.category.label,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              hazard.description,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Community verdict banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: blockedWinning
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFD1FAE5),
                      borderRadius: AppRadii.borderRadiusMd,
                      border: Border.all(
                        color: blockedWinning
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF059669),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          blockedWinning ? Icons.warning_amber_rounded : Icons.check_circle,
                          color: blockedWinning ? const Color(0xFFD97706) : const Color(0xFF059669),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            blockedWinning
                                ? 'Community says: Still Blocked ($total votes)'
                                : 'Community says: Fixed / Cleared ($total votes)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: blockedWinning
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Vote bar
                  Row(
                    children: [
                      const Text('🚧', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: hazard.fixedVoteFraction,
                                  minHeight: 12,
                                  backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$blockedPct% Still Blocked (${hazard.blockedVotes})',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '$fixedPct% Fixed (${hazard.fixedVotes})',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Text('✅', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Needs ${(3 - total).clamp(0, 3)} more votes to auto-resolve',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Vote buttons
                  if (!hazard.isResolved) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              exploration.voteHazardBlocked(hazard.id);
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.report_gmailerrorred, size: 18),
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Still Blocked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('+5 pts', style: TextStyle(fontSize: 10, color: Colors.orange.shade100)),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: AppRadii.borderRadiusMd),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              exploration.voteHazardFixed(hazard.id);
                              setModalState(() {});
                              if (hazard.isResolved) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF059669),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    content: const Row(
                                      children: [
                                        Icon(Icons.stars, color: Colors.amber),
                                        SizedBox(width: 8),
                                        Expanded(child: Text('Hazard resolved by community! +25 pts bonus earned 🎉', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('It\'s Fixed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('+10 pts', style: TextStyle(fontSize: 10, color: Colors.green.shade100)),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: AppRadii.borderRadiusMd),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Reported ${hazard.ageLabel} • Your vote helps the community',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: AppRadii.borderRadiusMd,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Text(
                            'Hazard resolved — path is clear! ✅',
                            style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 3. CATEGORY PLACES BOTTOM SHEET
  // ==========================================
  void _showCategoryPlacesSheet(
    BuildContext context,
    _ExplorerCategory category,
    AppState state,
    ExplorationService exploration,
  ) {
    final userLat = exploration.currentEffectiveLat;
    final userLng = exploration.currentEffectiveLng;

    // Filter places and sort by distance
    final matchingPlaces = state.places.where(category.filter).toList();
    matchingPlaces.sort(
      (a, b) => a
          .distanceKmFrom(userLat, userLng)
          .compareTo(b.distanceKmFrom(userLat, userLng)),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle & Header
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: AppRadii.borderRadiusFull,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: category.color.withValues(alpha: 0.15),
                      foregroundColor: category.color,
                      child: Icon(category.icon),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.label,
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${matchingPlaces.length} places near you (Sorted by distance)',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Places list
              Expanded(
                child: matchingPlaces.isEmpty
                    ? Center(
                        child: Text(
                          'No venues found nearby in this category.',
                          style: AppTypography.bodyLarge,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: matchingPlaces.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, idx) {
                          final place = matchingPlaces[idx];
                          final distKm = place.distanceKmFrom(userLat, userLng);
                          final distMeters = (distKm * 1000).round();

                          return Card(
                            elevation: 2,
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          place.name,
                                          style: AppTypography.titleLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySurface,
                                          borderRadius: AppRadii.borderRadiusSm,
                                        ),
                                        child: Text(
                                          '$distMeters m away',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    place.address,
                                    style: AppTypography.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Accessibility feature tag
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          place.accessibilityFeatures
                                              .take(2)
                                              .map((f) => f.name)
                                              .join(' • '),
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  // Action Buttons: "Start Navigation" & "Details"
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            exploration.setDestination(place);
                                          },
                                          icon: const Icon(Icons.directions_walk),
                                          label: const Text('Start Navigation'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0F766E),
                                            foregroundColor: Colors.white,
                                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            Navigator.of(context).push(
                                               MaterialPageRoute<void>(
                                                 builder: (_) => PlaceDetailsScreen(placeId: place.id),
                                               ),
                                            );
                                          },
                                          child: const Text('Details'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExplorerCategory {
  final String label;
  final IconData icon;
  final Color color;
  final bool Function(Place) filter;

  _ExplorerCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.filter,
  });
}

class _NavMetric extends StatelessWidget {
  const _NavMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.isLive = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            if (isLive)
              Positioned(
                top: -2,
                right: -4,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Gyroscope compass widget — rotates to point toward next waypoint
/// relative to the device's current heading.
class _GyroCompass extends StatelessWidget {
  const _GyroCompass({
    required this.relativeAngle,
    required this.heading,
  });

  /// Angle (0–360°) between device heading and next waypoint bearing.
  /// Null when compass/GPS data unavailable.
  final double? relativeAngle;
  final double? heading;

  @override
  Widget build(BuildContext context) {
    // Convert to radians for Transform.rotate
    final angle = relativeAngle != null
        ? (relativeAngle! * 3.14159265358979 / 180.0)
        : 0.0;
    final hasData = relativeAngle != null && heading != null;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
        boxShadow: AppShadows.md,
        border: Border.all(
          color: hasData
              ? const Color(0xFF0F766E)
              : Colors.white24,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // N/S/E/W tick marks
          ...List.generate(4, (i) {
            final tickAngle = i * 3.14159265358979 / 2;
            return Transform.rotate(
              angle: tickAngle,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 2,
                  height: 5,
                  margin: const EdgeInsets.only(top: 4),
                  color: Colors.white24,
                ),
              ),
            );
          }),
          // North label
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'N',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Rotating direction arrow
          AnimatedRotation(
            turns: angle / (2 * 3.14159265358979),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Arrow head
                CustomPaint(
                  size: const Size(12, 16),
                  painter: _ArrowPainter(
                    color: hasData
                        ? const Color(0xFF0F766E)
                        : Colors.white54,
                  ),
                ),
                // Arrow tail
                Container(
                  width: 2,
                  height: 6,
                  color: hasData
                      ? const Color(0xFF0F766E).withValues(alpha: 0.7)
                      : Colors.white30,
                ),
              ],
            ),
          ),
          // Center dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: hasData ? const Color(0xFF0F766E) : Colors.white38,
              shape: BoxShape.circle,
            ),
          ),
          // Degree badge
          if (hasData && relativeAngle != null)
            Positioned(
              bottom: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Builder(builder: (_) {
                  final diff = relativeAngle! > 180 ? relativeAngle! - 360 : relativeAngle!;
                  final degText = diff.abs() <= 5
                      ? '0°'
                      : '${diff > 0 ? 'R' : 'L'}${diff.abs().round()}°';
                  return Text(
                    degText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }),
              ),
            ),
          // No-data indicator
          if (!hasData)
            const Positioned(
              bottom: 4,
              child: Text(
                '?',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom arrow-head painter for the compass needle
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height * 0.7)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}
