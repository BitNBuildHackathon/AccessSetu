import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/contribute/presentation/add_location_screen.dart';
import 'package:access_map/features/places/presentation/place_details_screen.dart';
import 'package:access_map/features/reviews/presentation/write_review_screen.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Contribute tab — the community hub with live feed, missions, and add location.
class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().profile;
    final points = profile.communityPoints;

    // Tier ladder
    const tiers = [
      (0,    'Bronze Explorer',  100),
      (100,  'Silver Scout',     250),
      (250,  'Gold Guide',       500),
      (500,  'Platinum Champion', 1000),
      (1000, 'Community Hero',   9999),
    ];
    final tierData = tiers.lastWhere((t) => points >= t.$1, orElse: () => tiers.first);
    final tierName   = tierData.$2;
    final nextTierPoints = tierData.$3;
    final tierStart  = tierData.$1;
    final progress = nextTierPoints == 9999
        ? 1.0
        : ((points - tierStart) / (nextTierPoints - tierStart)).clamp(0.0, 1.0);
    final ptsToNext = nextTierPoints == 9999 ? 0 : nextTierPoints - points;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community & Impact'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'My Impact'),
            Tab(text: 'Goa Feed'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: My Impact & Missions
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Hero Points & Tier Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadii.borderRadiusLg,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                points.toString(),
                                style: AppTypography.scoreDisplay.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Community Impact Points',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: AppRadii.borderRadiusFull,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                tierName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ClipRRect(
                      borderRadius: AppRadii.borderRadiusFull,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '$points / $nextTierPoints pts',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            ptsToNext == 0
                                ? 'Max tier reached! 🏆'
                                : '$ptsToNext pts to next tier',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Metric counters
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Locations',
                      value: profile.locationCount,
                      icon: Icons.add_location_alt,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MetricTile(
                      label: 'Reviews',
                      value: profile.reviewCount,
                      icon: Icons.rate_review,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MetricTile(
                      label: 'Updates',
                      value: profile.accessibilityUpdates,
                      icon: Icons.check_circle,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MetricTile(
                      label: 'Photos',
                      value: profile.photoCount,
                      icon: Icons.photo_camera,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Quick Contribution Actions
              _ActionCard(
                key: const ValueKey('add-location-card'),
                icon: Icons.add_location_alt,
                title: 'Add a New Location',
                subtitle: 'Put an accessible place on the community map',
                highlight: true,
                onTap: () => _openAddLocation(context),
              ),
              _ActionCard(
                icon: Icons.fact_check_outlined,
                title: 'Add Accessibility Information',
                subtitle: 'Confirm or update what you know about a place',
                onTap: () => _openAddLocation(context),
              ),
              _ActionCard(
                icon: Icons.rate_review_outlined,
                title: 'Write a Review',
                subtitle: 'Share how a place worked for you',
                onTap: () => _showPickPlaceSheet(
                  context,
                  (place) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WriteReviewScreen(place: place),
                    ),
                  ),
                ),
              ),
              _ActionCard(
                icon: Icons.verified_outlined,
                title: 'Confirm Existing Information',
                subtitle: 'Verify accessibility features you have seen',
                onTap: () => _showPickPlaceSheet(
                  context,
                  (place) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlaceDetailsScreen(placeId: place.id),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Active Missions
              Text('Active Community Missions', style: AppTypography.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              _MissionCard(
                title: 'Panaji Transit Audit',
                description: 'Verify ramp & tactile access at 3 bus stands in Panaji.',
                progress: 2,
                total: 3,
                rewardPoints: 25,
                icon: Icons.directions_bus,
              ),
              const SizedBox(height: AppSpacing.sm),
              _MissionCard(
                title: 'Entrance Photo Scout',
                description: 'Upload 1 clear step-free entrance photo of a hospital or clinic.',
                progress: 0,
                total: 1,
                rewardPoints: 15,
                icon: Icons.add_a_photo,
              ),
              const SizedBox(height: AppSpacing.xl),
              // User's own activity
              Text('Your Recent Activity', style: AppTypography.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              if (profile.recentActivity.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text('No activity yet. Review a place to earn points!'),
                  ),
                )
              else
                ...profile.recentActivity.map(
                  (activity) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.successLight,
                        foregroundColor: AppColors.success,
                        child: Text(
                          '+${activity.pointsEarned}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        activity.description,
                        style: AppTypography.titleMedium,
                      ),
                      subtitle: Text(
                        DateFormat.yMMMd().add_jm().format(activity.timestamp),
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Tab 2: Goa Live Feed
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: const [
              _FeedItem(
                userName: 'Priya Naik',
                avatarInitials: 'PN',
                timeAgo: '12m ago',
                actionText: 'confirmed wheelchair ramp & step-free access',
                placeName: 'Fishka Restaurant, Baga',
                points: '+5 pts',
                badgeText: 'Wheelchair Scout',
                icon: Icons.accessible,
                iconColor: Colors.blue,
              ),
              _FeedItem(
                userName: 'Rohan Vernekar',
                avatarInitials: 'RV',
                timeAgo: '45m ago',
                actionText: 'uploaded entrance width & tactile paving photos',
                placeName: 'Panaji Bus Terminus',
                points: '+10 pts',
                badgeText: 'Visual Access Guide',
                icon: Icons.photo_camera,
                iconColor: Colors.purple,
              ),
              _FeedItem(
                userName: 'Sunita D’Souza',
                avatarInitials: 'SD',
                timeAgo: '2h ago',
                actionText: 'verified quiet sensory hours & low-stimulus area',
                placeName: 'Mall de Goa, Porvorim',
                points: '+5 pts',
                badgeText: 'Sensory Champion',
                icon: Icons.hearing,
                iconColor: Colors.teal,
              ),
              _FeedItem(
                userName: 'Vikram Joshi (PA)',
                avatarInitials: 'VJ',
                timeAgo: '3h ago',
                actionText: 'verified accessible parking & staff assistance',
                placeName: 'Goa Medical College Hospital, Bambolim',
                points: '+8 pts',
                badgeText: 'Caregiver Partner',
                icon: Icons.handshake,
                iconColor: Colors.orange,
              ),
              _FeedItem(
                userName: 'Ananya Prabhu',
                avatarInitials: 'AP',
                timeAgo: '5h ago',
                actionText: 'flagged broken elevator under maintenance',
                placeName: 'Caculo Mall, Panaji',
                points: '+5 pts',
                badgeText: 'Watchdog',
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.red,
              ),
            ],
          ),

          // Tab 3: Leaderboard & Community League
          Builder(
            builder: (context) {
              final champions = [
                const _LeaderboardEntry(name: 'Rahul Mandrekar', points: 340, reviews: 14, isCurrentUser: false),
                const _LeaderboardEntry(name: 'Priya Naik', points: 285, reviews: 11, isCurrentUser: false),
                _LeaderboardEntry(name: '${profile.displayName} (You)', points: points, reviews: profile.reviewCount, isCurrentUser: true),
                const _LeaderboardEntry(name: 'Sneha Kulkarni', points: 110, reviews: 5, isCurrentUser: false),
                const _LeaderboardEntry(name: 'Amit Rane', points: 95, reviews: 4, isCurrentUser: false),
                const _LeaderboardEntry(name: 'Devidas Shirodkar', points: 80, reviews: 3, isCurrentUser: false),
              ]..sort((a, b) => b.points.compareTo(a.points));

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: AppRadii.borderRadiusMd,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 36),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Goa Accessibility League',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Rankings update live as you verify accessibility features.',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...champions.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final item = entry.value;
                    return _LeaderboardTile(
                      rank: rank,
                      name: item.name,
                      points: item.points,
                      reviews: item.reviews,
                      isCurrentUser: item.isCurrentUser,
                    );
                  }),
                  const SizedBox(height: AppSpacing.xl),
                  // Liability & Community Safety Notice
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadii.borderRadiusMd,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.gavel_outlined, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Liability & Accuracy Disclaimer',
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AccessSetu accessibility audits and ratings are community-contributed in good faith. Conditions may change due to weather or venue maintenance. In acute emergencies, always dial 112 or 108 directly.',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _openAddLocation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddLocationScreen()),
    );
  }

  void _showPickPlaceSheet(
    BuildContext context,
    void Function(Place place) onPicked,
  ) {
    final places = context.read<AppState>().places;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('Choose a place', style: AppTypography.headlineSmall),
            ),
            ...places.map(
              (place) => ListTile(
                leading: Icon(place.category.icon, color: AppColors.primary),
                title: Text(place.name),
                subtitle: Text(place.category.displayName),
                onTap: () {
                  Navigator.of(context).pop();
                  onPicked(place);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderRadiusMd,
        side: BorderSide(
          color: highlight ? AppColors.primary : AppColors.divider,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: AppRadii.borderRadiusMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: highlight ? AppColors.primary : AppColors.primarySurface,
                  borderRadius: AppRadii.borderRadiusMd,
                ),
                child: Icon(
                  icon,
                  color: highlight ? AppColors.textOnPrimary : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: AppTypography.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.title,
    required this.description,
    required this.progress,
    required this.total,
    required this.rewardPoints,
    required this.icon,
  });

  final String title;
  final String description;
  final int progress;
  final int total;
  final int rewardPoints;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fraction = (progress / total).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primarySurface,
                  foregroundColor: AppColors.primary,
                  child: Icon(icon, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleMedium),
                      Text(description, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: AppRadii.borderRadiusSm,
                  ),
                  child: Text(
                    '+$rewardPoints pts',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: fraction,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$progress / $total completed',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({
    required this.userName,
    required this.avatarInitials,
    required this.timeAgo,
    required this.actionText,
    required this.placeName,
    required this.points,
    required this.badgeText,
    required this.icon,
    required this.iconColor,
  });

  final String userName;
  final String avatarInitials;
  final String timeAgo;
  final String actionText;
  final String placeName;
  final String points;
  final String badgeText;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$userName, $badgeText, $timeAgo: $actionText at $placeName. Earned $points.',
      child: Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.15),
                  foregroundColor: iconColor,
                  child: Text(
                    avatarInitials,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            userName,
                            style: AppTypography.titleMedium,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppRadii.borderRadiusSm,
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      Text(timeAgo, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: AppRadii.borderRadiusSm,
                  ),
                  child: Text(
                    points,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$actionText at '),
                  TextSpan(
                    text: placeName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.name,
    required this.points,
    required this.reviews,
    required this.isCurrentUser,
  });

  final int rank;
  final String name;
  final int points;
  final int reviews;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? const Color(0xFFD97706) // Gold
        : rank == 2
            ? const Color(0xFF475569) // Silver
            : rank == 3
                ? const Color(0xFFB45309) // Bronze
                : AppColors.textSecondary;

    return Semantics(
      label: 'Rank $rank: $name, $points impact points, $reviews verified contributions.',
      child: Card(
        color: isCurrentUser ? AppColors.primarySurface : AppColors.surface,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderRadiusMd,
          side: isCurrentUser
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
        ),
        child: ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: rank <= 3 ? rankColor.withValues(alpha: 0.15) : AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: rank <= 3 ? rankColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          subtitle: Text('$reviews verified contributions'),
          trailing: Text(
            '$points pts',
            style: TextStyle(
              color: isCurrentUser ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardEntry {
  final String name;
  final int points;
  final int reviews;
  final bool isCurrentUser;

  const _LeaderboardEntry({
    required this.name,
    required this.points,
    required this.reviews,
    required this.isCurrentUser,
  });
}
