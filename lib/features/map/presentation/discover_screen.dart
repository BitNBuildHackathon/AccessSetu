import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/services/exploration_service.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/places/presentation/place_details_screen.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  PlaceCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _localQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final exploration = context.watch<ExplorationService>();

    // Exclude the place currently being navigated to
    final activeNavId = exploration.activeDestination?.id;

    final allPlaces = state.places
        .where((p) => p.id != activeNavId)
        .toList();

    final filtered = allPlaces.where((p) {
      final matchCat =
          _selectedCategory == null || p.category == _selectedCategory;
      final matchQ = _localQuery.isEmpty ||
          p.name.toLowerCase().contains(_localQuery.toLowerCase()) ||
          p.address.toLowerCase().contains(_localQuery.toLowerCase());
      return matchCat && matchQ;
    }).toList();

    final popular = [...allPlaces]
      ..sort((a, b) =>
          b.communityConfirmations.compareTo(a.communityConfirmations));

    final highlyRated = [...allPlaces]
      ..sort((a, b) => b.friendlyScore.compareTo(a.friendlyScore));

    final recentlyAdded =
        [...allPlaces.where((p) => p.source == PlaceSource.community)]
          ..sort((a, b) => (b.createdAt ?? DateTime(2000))
              .compareTo(a.createdAt ?? DateTime(2000)));

    final isSearching =
        _localQuery.isNotEmpty || _selectedCategory != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            expandedHeight: 130,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.lg, AppSpacing.md, 52),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Discover',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          activeNavId != null
                              ? '${allPlaces.length} places • Navigating excluded'
                              : '${allPlaces.length} accessible places near you',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (q) => setState(() => _localQuery = q),
                ),
              ),
            ),
          ),
        ],
        body: state.isLoadingPlaces
            ? const Center(child: CircularProgressIndicator())
            : isSearching
                ? _SearchResultsView(
                    places: filtered,
                    query: _localQuery,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (cat) =>
                        setState(() => _selectedCategory = cat),
                    onPlaceTap: (p) => _openDetails(context, p),
                  )
                : _ExploreView(
                    allPlaces: allPlaces,
                    popular: popular,
                    highlyRated: highlyRated,
                    recentlyAdded: recentlyAdded,
                    onCategorySelected: (cat) =>
                        setState(() => _selectedCategory = cat),
                    onPlaceTap: (p) => _openDetails(context, p),
                    profileNeeds: state.profile.accessibilityNeeds,
                  ),
      ),
    );
  }

  void _openDetails(BuildContext context, Place place) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) => PlaceDetailsScreen(placeId: place.id)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPLORE VIEW (default browse)
// ─────────────────────────────────────────────────────────────────────────────
class _ExploreView extends StatelessWidget {
  const _ExploreView({
    required this.allPlaces,
    required this.popular,
    required this.highlyRated,
    required this.recentlyAdded,
    required this.onCategorySelected,
    required this.onPlaceTap,
    required this.profileNeeds,
  });

  final List<Place> allPlaces;
  final List<Place> popular;
  final List<Place> highlyRated;
  final List<Place> recentlyAdded;
  final ValueChanged<PlaceCategory?> onCategorySelected;
  final ValueChanged<Place> onPlaceTap;
  final List<AccessibilityNeed> profileNeeds;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
            child: _CategoryChipRow(onSelected: onCategorySelected)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: _ProfileLens(needs: profileNeeds),
          ),
        ),

        // ── Top Rated single featured card ─────────────────────
        if (highlyRated.isNotEmpty) ...[
          _header('⭐ Top Rated Nearby'),
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: _FeaturedCard(
                place: highlyRated.first,
                onTap: () => onPlaceTap(highlyRated.first),
              ),
            ),
          ),
        ],

        // ── Popular horizontal ─────────────────────────────────
        _header('🔥 Popular Near You'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md),
              itemCount: popular.take(8).length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => _HorizCard(
                place: popular[i],
                onTap: () => onPlaceTap(popular[i]),
              ),
            ),
          ),
        ),

        // ── Recently Added ─────────────────────────────────────
        if (recentlyAdded.isNotEmpty) ...[
          _header('🆕 Recently Added by Community'),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                itemCount: recentlyAdded.take(6).length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) => _HorizCard(
                  place: recentlyAdded[i],
                  onTap: () => onPlaceTap(recentlyAdded[i]),
                  badge: 'Community',
                ),
              ),
            ),
          ),
        ],

        // ── Highly Accessible list ─────────────────────────────
        _header('♿ Highly Accessible'),
        SliverPadding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final idx = (i + 1).clamp(0, highlyRated.length - 1);
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ListCard(
                    place: highlyRated[idx],
                    onTap: () => onPlaceTap(highlyRated[idx]),
                  ),
                );
              },
              childCount: (highlyRated.length - 1).clamp(0, 6),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  SliverToBoxAdapter _header(String title) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
          child: Text(
            title,
            style: AppTypography.titleLarge
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH RESULTS VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({
    required this.places,
    required this.query,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onPlaceTap,
  });

  final List<Place> places;
  final String query;
  final PlaceCategory? selectedCategory;
  final ValueChanged<PlaceCategory?> onCategorySelected;
  final ValueChanged<Place> onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _CategoryChipRow(
              onSelected: onCategorySelected, selected: selectedCategory),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Text(
              '${places.length} result${places.length == 1 ? '' : 's'}${query.isNotEmpty ? ' for "$query"' : ''}',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
        if (places.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off,
                      size: 72,
                      color: AppColors.textSecondary
                          .withValues(alpha: 0.35)),
                  const SizedBox(height: AppSpacing.md),
                  Text('No places found',
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Try a different search or category',
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ListCard(
                    place: places[i],
                    onTap: () => onPlaceTap(places[i]),
                  ),
                ),
                childCount: places.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARDS — no external images, icon-based clean design
// ─────────────────────────────────────────────────────────────────────────────

/// Large featured card — gradient background derived from category colour
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.place, required this.onTap});
  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = place.friendlyScore;
    final scoreColor = AppColors.scoreColor(score);
    final catColor = _categoryColor(place.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              catColor,
              catColor.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: AppRadii.borderRadiusLg,
          boxShadow: AppShadows.md,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: AppRadii.borderRadiusMd,
              ),
              child: Icon(place.category.icon,
                  size: 36, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: AppRadii.borderRadiusFull,
                        ),
                        child: Text(
                          place.category.displayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        place.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        place.address,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // Score + confirmations row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadii.borderRadiusFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.accessible,
                                size: 12, color: scoreColor),
                            const SizedBox(width: 3),
                            Text(
                              score > 0
                                  ? '${score.toStringAsFixed(1)}/10'
                                  : 'New',
                              style: TextStyle(
                                color: scoreColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${place.communityConfirmations} verified',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact horizontal-scroll card — category colour accent strip
class _HorizCard extends StatelessWidget {
  const _HorizCard(
      {required this.place, required this.onTap, this.badge});
  final Place place;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final score = place.friendlyScore;
    final scoreColor = AppColors.scoreColor(score);
    final catColor = _categoryColor(place.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.borderRadiusMd,
          boxShadow: AppShadows.sm,
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colour accent strip with icon
            Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    catColor,
                    catColor.withValues(alpha: 0.65),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(place.category.icon,
                        size: 36, color: Colors.white70),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadii.borderRadiusFull,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: scoreColor,
                        borderRadius: AppRadii.borderRadiusFull,
                      ),
                      child: Text(
                        score > 0 ? score.toStringAsFixed(1) : 'New',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name,
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.category.displayName,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_alt,
                          size: 11,
                          color: AppColors.primary
                              .withValues(alpha: 0.7)),
                      const SizedBox(width: 3),
                      Text(
                        '${place.communityConfirmations} verified',
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width list card for search results and "Highly Accessible" section
class _ListCard extends StatelessWidget {
  const _ListCard({required this.place, required this.onTap});
  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = place.friendlyScore;
    final scoreColor = AppColors.scoreColor(score);
    final catColor = _categoryColor(place.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.borderRadiusMd,
          boxShadow: AppShadows.sm,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Square icon block
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    catColor,
                    catColor.withValues(alpha: 0.65),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Icon(place.category.icon,
                  size: 32, color: Colors.white),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: AppTypography.titleMedium
                                .copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scoreColor.withValues(alpha: 0.12),
                            borderRadius: AppRadii.borderRadiusFull,
                            border: Border.all(
                                color:
                                    scoreColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            score > 0
                                ? '${score.toStringAsFixed(1)} ♿'
                                : 'New',
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.address,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: place.availableFeatures
                          .take(2)
                          .map((f) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius:
                                      AppRadii.borderRadiusFull,
                                ),
                                child: Text(
                                  f.name,
                                  style: const TextStyle(
                                    color: Color(0xFF065F46),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SUBWIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField(
      {required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search accessible places...',
        hintStyle: AppTypography.bodyMedium
            .copyWith(color: AppColors.textSecondary),
        prefixIcon:
            const Icon(Icons.search, color: AppColors.primary),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceVariant.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: AppRadii.borderRadiusFull,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 0),
        isDense: true,
      ),
    );
  }
}

class _CategoryChipRow extends StatelessWidget {
  const _CategoryChipRow(
      {required this.onSelected, this.selected});
  final ValueChanged<PlaceCategory?> onSelected;
  final PlaceCategory? selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 4),
        children: [
          _Chip(
            icon: Icons.apps_rounded,
            label: 'All',
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          ...PlaceCategory.values.map((cat) => _Chip(
                icon: cat.icon,
                label: cat.displayName,
                isSelected: selected == cat,
                onTap: () => onSelected(cat),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        avatar: Icon(icon, size: 15),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 2),
      ),
    );
  }
}

class _ProfileLens extends StatelessWidget {
  const _ProfileLens({required this.needs});
  final List<AccessibilityNeed> needs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome,
              color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              needs.isEmpty
                  ? 'Showing all accessible places nearby'
                  : 'Prioritising ${needs.map((n) => n.displayName).join(', ')} venues',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Returns a colour per category used as the card accent/gradient.
Color _categoryColor(PlaceCategory cat) {
  switch (cat) {
    case PlaceCategory.hospital:
    case PlaceCategory.clinic:
      return const Color(0xFFEF4444);
    case PlaceCategory.pharmacy:
      return const Color(0xFF10B981);
    case PlaceCategory.restaurant:
      return const Color(0xFFF97316);
    case PlaceCategory.cafe:
      return const Color(0xFF92400E);
    case PlaceCategory.hotel:
      return const Color(0xFF8B5CF6);
    case PlaceCategory.park:
      return const Color(0xFF16A34A);
    case PlaceCategory.busStop:
      return const Color(0xFF0EA5E9);
    case PlaceCategory.college:
      return const Color(0xFF6366F1);
    case PlaceCategory.touristAttraction:
      return const Color(0xFFD97706);
    case PlaceCategory.mall:
      return const Color(0xFFEC4899);
    case PlaceCategory.governmentOffice:
      return const Color(0xFF475569);
    case PlaceCategory.communityCenter:
      return const Color(0xFF0891B2);
    case PlaceCategory.repairSupport:
      return const Color(0xFF78716C);
    case PlaceCategory.atm:
      return const Color(0xFF15803D);
  }
}
