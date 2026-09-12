import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/services/exploration_service.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/places/presentation/place_details_screen.dart';
import 'package:access_map/shared/models/hazard_report.dart';
import 'package:access_map/shared/models/accessibility_need.dart';

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
          child: Container(
            color: isNavigating ? Colors.transparent : Colors.black.withValues(alpha: 0.5),
            child: SafeArea(
              child: isNavigating
                  ? _buildGoogleMapsNavigationHUD(context, exploration, state)
                  : _buildLazarilloCategoryExplorer(context, exploration, state),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 1. LAZARILLO-STYLE CATEGORY EXPLORER VIEW
  // ==========================================
  Widget _buildLazarilloCategoryExplorer(
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
        label: 'Bus Stands & Transit',
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
        label: 'Clubs & Entertainment',
        icon: Icons.nightlife,
        color: const Color(0xFF9333EA),
        filter: (p) =>
            p.category == PlaceCategory.touristAttraction ||
            p.category == PlaceCategory.hotel,
      ),
      _ExplorerCategory(
        label: 'Restaurants & Cafes',
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

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header: Facing direction & Close button
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Facing direction',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.borderRadiusMd,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.explore, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            exploration.currentHeading != null
                                ? 'Facing ${exploration.currentHeading!.round()}°'
                                : (state.profile.accessibilityNeeds.contains(AccessibilityNeed.blindLowVision)
                                    ? 'Audible Navigator'
                                    : 'Accessible Navigator'),
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: AppRadii.borderRadiusMd,
                  border: Border.all(color: AppColors.error, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.error, size: 28),
                  onPressed: () => exploration.stopExploration(),
                  tooltip: 'Exit Navigator',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Big "Where Am I?" button (High contrast, 1-tap landmark announcement)
          Semantics(
            button: true,
            label: 'Where am I? Double tap to announce your current area and landmark',
            child: ElevatedButton.icon(
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
                          const Icon(Icons.my_location, color: Colors.amberAccent, size: 22),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              loc,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
              icon: const Icon(Icons.my_location, size: 30),
              label: const Text('Where Am I? (Spoken Landmark)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                textStyle: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.borderRadiusLg,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Report Hazard Button (Earn 15 pts)
          ElevatedButton.icon(
            onPressed: () => _showReportHazardSheet(context, exploration),
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            label: const Text('Report Hazard at My Location (+15 pts)'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.borderRadiusMd),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              'Explore Nearby (Choose a Category)',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  const Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Lazarillo Grid: 6 Big Accessible Category Cards
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.88,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final matchingCount = state.places.where(cat.filter).length;

                return Semantics(
                  button: true,
                  label: '${cat.label}. $matchingCount nearby places. Double tap to view.',
                  child: InkWell(
                    onTap: () => _showCategoryPlacesSheet(
                      context,
                      cat,
                      state,
                      exploration,
                    ),
                    borderRadius: AppRadii.borderRadiusLg,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadii.borderRadiusLg,
                        border: Border.all(color: cat.color, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: cat.color.withValues(alpha: 0.15),
                            foregroundColor: cat.color,
                            child: Icon(cat.icon, size: 28),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            cat.label,
                            textAlign: TextAlign.center,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$matchingCount nearby',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
    final distance = (exploration.distanceToDestination ?? 0).round();
    final walkTime = exploration.estimatedWalkingMinutes;
    final nearbyHazard = exploration.nearbyHazard;
    final isBlind = state.profile.accessibilityNeeds.contains(AccessibilityNeed.blindLowVision);

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E), // Emerald navigation green
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
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF0F766E),
                      child: Icon(Icons.navigation, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            exploration.navigationInstruction,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            exploration.nextTurnHint,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dest.name,
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavMetric(
                      label: 'Distance Remaining',
                      value: '$distance m',
                      icon: Icons.straighten,
                    ),
                    _NavMetric(
                      label: 'Est. Walk Time',
                      value: '$walkTime min',
                      icon: Icons.timer_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // 1-Tap In-Route Hazard Report Trigger
                ElevatedButton.icon(
                  onPressed: () => _showReportHazardSheet(context, exploration),
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                  label: const Text('Report Hazard at My Location (+15 pts)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706), // Amber warning
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    if (isBlind) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => exploration.repeatDirections(),
                          icon: const Icon(Icons.volume_up, size: 18),
                          label: const Text('Repeat Voice', maxLines: 1, overflow: TextOverflow.ellipsis),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => exploration.clearDestination(),
                        icon: const Icon(Icons.close, color: AppColors.error, size: 18),
                        label: const Text('End Navigation', maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text(
                'Is this still blocked?',
                style: TextStyle(fontSize: 11, color: Colors.brown.shade700, fontWeight: FontWeight.w600),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFB45309),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => exploration.verifyHazardStillBlocked(hazard.id),
                    child: const Text('Still Blocked (+5 pts)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669), // emerald
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => exploration.markHazardFixed(hazard.id),
                    child: const Text('Fixed! (+10 pts)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
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
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
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
