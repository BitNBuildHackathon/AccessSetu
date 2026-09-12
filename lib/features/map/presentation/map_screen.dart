import 'dart:math' as math;

import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/places/presentation/place_details_screen.dart';
import 'package:access_map/features/emergency/presentation/sos_emergency_screen.dart';
import 'package:access_map/features/map/presentation/exploration_overlay.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:access_map/shared/widgets/access_search_bar.dart';
import 'package:access_map/shared/widgets/app_components.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/travel_mode.dart';
import 'package:access_map/shared/models/hazard_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:access_map/shared/models/map_style.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  PlaceCategory? _categoryFilter;
  bool _highlyFriendlyOnly = false;
  late final MapController _mapController = MapController();
  bool _isLocating = false;
  MapStyle _currentMapStyle = MapStyle.standard;
  bool _is3DMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialLocation();
    });
  }

  Future<void> _fetchInitialLocation() async {
    final pos = await context.read<AppState>().explorationService.getCurrentLocation(requestPermission: false);
    if (pos != null && mounted) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
    }
  }

  Future<void> _onMyLocationPressed() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Locating GPS position...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    final exploration = context.read<AppState>().explorationService;
    final pos = await exploration.getCurrentLocation(requestPermission: true);

    if (!mounted) return;
    setState(() => _isLocating = false);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Centered on your location (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location services are turned off on device.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Geolocator.openLocationSettings(),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        final permission = await Geolocator.checkPermission();
        if (!mounted) return;
        if (permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission permanently denied.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => Geolocator.openAppSettings(),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          _mapController.move(
            LatLng(exploration.currentEffectiveLat, exploration.currentEffectiveLng),
            15.0,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS signal weak. Centered on best available position.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final places = _filteredPlaces(state.visiblePlaces, state.profile.travelMode);
    final exploration = state.explorationService;
    final isNavigating = exploration.activeDestination != null;

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: state.isLoadingPlaces
                ? const Center(child: CircularProgressIndicator())
                : _AccessibleMap(
                    mapController: _mapController,
                    mapStyle: _currentMapStyle,
                    is3DMode: _is3DMode,
                    places: places,
                    selectedPlace: state.selectedPlace,
                    activeDestination: exploration.activeDestination,
                    routePoints: exploration.routePolylinePoints,
                    hazards: exploration.activeHazards,
                    userLocation: LatLng(
                      exploration.currentEffectiveLat,
                      exploration.currentEffectiveLng,
                    ),
                  ),
          ),
          if (!isNavigating) ...[
            Positioned(
              top: AppSpacing.lg,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Column(
                children: [
                  const AccessSearchBar(),
                  const SizedBox(height: AppSpacing.sm),
                  _ModeIndicator(mode: state.profile.travelMode),
                  if (state.searchQuery.isNotEmpty || state.isSearching)
                    _SearchResults(places: places),
                ],
              ),
            ),
            Positioned(
              top: 92,
              right: AppSpacing.lg,
              child: FloatingActionButton.small(
                heroTag: 'filters',
                tooltip: 'Filters',
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                onPressed: () => _showFilters(context),
                child: const Icon(Icons.tune),
              ),
            ),
            Positioned(
              top: 142,
              right: AppSpacing.lg,
              child: FloatingActionButton.small(
                heroTag: 'map_layers',
                tooltip: 'Map Layers & 3D Options',
                backgroundColor: _is3DMode || _currentMapStyle != MapStyle.standard
                    ? AppColors.primary
                    : AppColors.surface,
                foregroundColor: _is3DMode || _currentMapStyle != MapStyle.standard
                    ? Colors.white
                    : AppColors.primary,
                onPressed: () => _showMapStyleSelector(context),
                child: Icon(_is3DMode ? Icons.view_in_ar : Icons.layers),
              ),
            ),
            if (_is3DMode)
              Positioned(
                top: 146,
                right: AppSpacing.lg + 48,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _is3DMode = false;
                      _mapController.rotate(0.0);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.threed_rotation, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('3D ON', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          Positioned(
            right: AppSpacing.lg,
            bottom: isNavigating ? 190 : (state.selectedPlace == null ? AppSpacing.lg : 190),
            child: FloatingActionButton.small(
              heroTag: 'location',
              tooltip: 'Center on my location',
              onPressed: _onMyLocationPressed,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            bottom: isNavigating ? 190 : (state.selectedPlace == null ? AppSpacing.lg : 190),
            child: FloatingActionButton.extended(
              heroTag: 'sos',
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SosEmergencyScreen()),
              ),
              icon: const Icon(Icons.emergency),
              label: const Text('SOS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (state.profile.accessibilityNeeds.contains(AccessibilityNeed.blindLowVision) &&
              !exploration.isActive &&
              !isNavigating)
            Positioned(
              left: AppSpacing.lg,
              bottom: (state.selectedPlace == null ? AppSpacing.lg : 190) + 64,
              child: FloatingActionButton.extended(
                heroTag: 'discover',
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textOnPrimary,
                onPressed: () => context.read<AppState>().toggleExplorationMode(),
                icon: const Icon(Icons.explore),
                label: const Text('Start Exploration Mode'),
              ),
            ),
          if (state.errorMessage != null)
            EmptyState(
              title: "Couldn't load nearby places",
              message: 'Please check your connection and try again.',
              action: ElevatedButton(
                onPressed: context.read<AppState>().loadPlaces,
                child: const Text('Retry'),
              ),
            ),
          if (state.selectedPlace != null)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: PlacePreviewSheet(
                place: state.selectedPlace!,
                userLatitude: exploration.currentEffectiveLat,
                userLongitude: exploration.currentEffectiveLng,
              ),
            ),
          const Positioned.fill(
            child: ExplorationOverlay(),
          ),
        ],
      ),
    );
  }

  List<Place> _filteredPlaces(List<Place> places, TravelMode mode) {
    return places.where((place) {
      if (!place.suitableForMode(mode)) {
        return false;
      }
      if (_categoryFilter != null && place.category != _categoryFilter) {
        return false;
      }
      if (_highlyFriendlyOnly && place.friendlyScore < 8.5) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filters', style: AppTypography.headlineSmall),
                    const SizedBox(height: AppSpacing.lg),
                    SwitchListTile(
                      value: _highlyFriendlyOnly,
                      onChanged: (value) {
                        setState(() => _highlyFriendlyOnly = value);
                        setModalState(() {});
                      },
                      title: const Text('Highly friendly'),
                      subtitle: const Text('Friendly Score 8.5 and above'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _categoryFilter == null,
                          onSelected: (_) {
                            setState(() => _categoryFilter = null);
                            setModalState(() {});
                          },
                        ),
                        ...PlaceCategory.values.map(
                          (category) => ChoiceChip(
                            avatar: Icon(category.icon, size: 18),
                            label: Text(category.displayName),
                            selected: _categoryFilter == category,
                            onSelected: (_) {
                              setState(() => _categoryFilter = category);
                              setModalState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMapStyleSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Map Layers & 3D',
                              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_is3DMode)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '3D ACTIVE',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select map visual layer or toggle 3D angled perspective:',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 3D Perspective Mode Switch Tile
                      Container(
                        decoration: BoxDecoration(
                          color: _is3DMode ? AppColors.primarySurface : AppColors.surfaceVariant,
                          borderRadius: AppRadii.borderRadiusMd,
                          border: Border.all(
                            color: _is3DMode ? AppColors.primary : AppColors.divider,
                            width: _is3DMode ? 1.5 : 1.0,
                          ),
                        ),
                        child: SwitchListTile(
                          secondary: Icon(
                            Icons.view_in_ar,
                            color: _is3DMode ? AppColors.primary : AppColors.textSecondary,
                            size: 28,
                          ),
                          title: const Text('3D Angled Perspective', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Angled camera rotation for 3D route orientation'),
                          value: _is3DMode,
                          onChanged: (val) {
                            setState(() {
                              _is3DMode = val;
                              _mapController.rotate(_is3DMode ? 35.0 : 0.0);
                            });
                            setModalState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Text('Base Map Layer', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.sm),

                      // Map Styles Selection Cards
                      ...MapStyle.values.map((style) {
                        final isSelected = _currentMapStyle == style;
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          elevation: isSelected ? 2 : 0,
                          color: isSelected ? AppColors.primarySurface : AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.borderRadiusMd,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.divider,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                              foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
                              child: Icon(style.icon, size: 20),
                            ),
                            title: Text(
                              style.displayName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              style.description,
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppColors.primary)
                                : null,
                            onTap: () {
                              setState(() => _currentMapStyle = style);
                              setModalState(() {});
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AccessibleMap extends StatelessWidget {
  const _AccessibleMap({
    required this.places,
    required this.selectedPlace,
    this.activeDestination,
    this.routePoints = const [],
    this.hazards = const [],
    this.userLocation,
    this.mapController,
    this.mapStyle = MapStyle.standard,
    this.is3DMode = false,
  });

  final List<Place> places;
  final Place? selectedPlace;
  final Place? activeDestination;
  final List<LatLng> routePoints;
  final List<HazardReport> hazards;
  final LatLng? userLocation;
  final MapController? mapController;
  final MapStyle mapStyle;
  final bool is3DMode;

  @override
  Widget build(BuildContext context) {
    final centerPoint = activeDestination != null
        ? LatLng(activeDestination!.latitude, activeDestination!.longitude)
        : (userLocation ?? const LatLng(15.4909, 73.8278));

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: centerPoint,
        initialZoom: activeDestination != null ? 14.5 : 12,
        initialRotation: is3DMode ? 35.0 : 0.0,
        onTap: (_, __) => context.read<AppState>().clearSelectedPlace(),
      ),
      children: [
        TileLayer(
          urlTemplate: mapStyle.urlTemplate,
          userAgentPackageName: 'com.example.access_map',
          subdomains: const ['a', 'b', 'c', 'd'],
        ),
        // Draw walking route polyline when navigating
        if (routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 6,
                color: const Color(0xFF0F766E), // Emerald walking path
                borderStrokeWidth: 2,
                borderColor: Colors.white,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // User location marker
            if (userLocation != null)
              Marker(
                point: userLocation!,
                width: 44,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade600,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.navigation, color: Colors.white, size: 20),
                  ),
                ),
              ),

            // Active destination marker
            if (activeDestination != null)
              Marker(
                point: LatLng(activeDestination!.latitude, activeDestination!.longitude),
                width: 160,
                height: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child: Text(
                        activeDestination!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.location_on, color: Color(0xFF0F766E), size: 30),
                  ],
                ),
              ),

            // Live accessibility hazard markers (Crowdsourced Obstacles)
            ...hazards.map((hazard) {
              return Marker(
                point: LatLng(hazard.latitude, hazard.longitude),
                width: 42,
                height: 42,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: hazard.category.color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        content: Row(
                          children: [
                            Icon(hazard.category.icon, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${hazard.category.label}: ${hazard.description} (${hazard.ageLabel})',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (context.read<AppState>().profile.accessibilityNeeds.contains(AccessibilityNeed.blindLowVision)) {
                      context.read<AppState>().ttsService.speak(
                        'Hazard: ${hazard.category.label}. ${hazard.description}.',
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: hazard.category.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: hazard.category.color.withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(hazard.category.icon, color: Colors.white, size: 20),
                  ),
                ),
              );
            }),

            // Regular places
            ...places.map((place) {
              final selected = place.id == selectedPlace?.id;
              final isDest = place.id == activeDestination?.id;
              if (isDest) return const Marker(point: LatLng(0, 0), child: SizedBox.shrink());

              return Marker(
                point: LatLng(place.latitude, place.longitude),
                width: selected ? 58 : 48,
                height: selected ? 58 : 48,
                child: GestureDetector(
                  onTap: () => context.read<AppState>().selectPlace(place),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.secondary : AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 3),
                      boxShadow: AppShadows.md,
                    ),
                    child: Icon(
                      place.category.icon,
                      color: AppColors.textOnPrimary,
                      size: selected ? 28 : 23,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class PlacePreviewSheet extends StatelessWidget {
  const PlacePreviewSheet({
    required this.place,
    this.userLatitude,
    this.userLongitude,
    super.key,
  });

  final Place place;
  final double? userLatitude;
  final double? userLongitude;

  @override
  Widget build(BuildContext context) {
    final relevant = place.availableFeatures.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.borderRadiusMd,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlaceDetailsScreen(placeId: place.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      place.name,
                      style: AppTypography.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.scoreColor(place.friendlyScore).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.scoreColor(place.friendlyScore), width: 1.5),
                    ),
                    child: Text(
                      '${place.friendlyScore.toStringAsFixed(1)} Friendly',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.scoreColor(place.friendlyScore),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => context.read<AppState>().clearSelectedPlace(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${place.category.displayName}'
                '${userLatitude != null && userLongitude != null ? ' • ${_formatDistance(place.distanceKmFrom(userLatitude!, userLongitude!))}' : ''}'
                ' • ${place.communityConfirmations} confirmations',
                style: AppTypography.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: relevant
                    .map(
                      (feature) => Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(feature.icon, size: 16),
                        label: Text(feature.name),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

String _formatDistance(double km) {
  if (km < 1) {
    return '${(km * 1000).round()} m';
  }
  return '${km.toStringAsFixed(1)} km';
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadii.borderRadiusMd,
      elevation: 4,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 250),
        margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: state.isSearching
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: LinearProgressIndicator(),
            )
          : places.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('No accessible places found.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: math.min(places.length, 5),
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return ListTile(
                      leading: Icon(place.category.icon),
                      title: Text(place.name),
                      subtitle: Text('${place.category.displayName} - Friendly ${place.friendlyScore.toStringAsFixed(1)}'),
                      onTap: () {
                        context.read<AppState>().selectPlace(place);
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlaceDetailsScreen(placeId: place.id),
                          ),
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }
}

class _ModeIndicator extends StatelessWidget {
  const _ModeIndicator({required this.mode});

  final TravelMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: AppRadii.borderRadiusMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mode.icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${mode.displayName} mode',
            style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
