import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/services/offline_map_service.dart';
import 'package:access_map/core/theme/app_theme.dart';

class OfflineMapsScreen extends StatelessWidget {
  const OfflineMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final offlineService = context.watch<AppState>().offlineMapService;
    final totalMb = offlineService.totalDownloadedMb;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Regional Maps'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Storage & Status Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadii.borderRadiusLg,
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.offline_pin, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'OFFLINE STORAGE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        totalMb > 0 ? 'OFFLINE READY' : 'NO MAPS SAVED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$totalMb MB Used',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Regional downloads save local streets, step-free paths & verified venues without downloading the entire world.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Wi-Fi Only Settings Tile
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.borderRadiusMd,
              side: const BorderSide(color: AppColors.divider),
            ),
            child: SwitchListTile(
              secondary: const Icon(Icons.wifi, color: AppColors.primary),
              title: const Text('Download on Wi-Fi Only'),
              subtitle: const Text('Prevent cellular data usage when saving maps'),
              value: offlineService.wifiOnly,
              onChanged: (val) => offlineService.setWifiOnly(val),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Regional Packages Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Regional Packs', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              Text('${offlineService.packages.length} regions', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Package Cards List
          ...offlineService.packages.map((pkg) => _PackageCard(package: pkg)),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package});

  final OfflineMapPackage package;

  @override
  Widget build(BuildContext context) {
    final offlineService = context.read<AppState>().offlineMapService;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderRadiusMd,
        side: BorderSide(
          color: package.isDownloaded
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.divider,
          width: package.isDownloaded ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: package.isDownloaded ? AppColors.primarySurface : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    package.isDownloaded ? Icons.check_circle : Icons.map_outlined,
                    color: package.isDownloaded ? AppColors.primary : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.title,
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        package.subtitle,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${package.sizeMb} MB',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Includes ${package.placesCount}+ venues: ${package.coverage}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Progress bar if downloading
            if (package.isDownloading) ...[
              LinearProgressIndicator(
                value: package.downloadProgress,
                backgroundColor: AppColors.surfaceVariant,
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading regional tiles & routes...',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${(package.downloadProgress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ] else if (package.isDownloaded) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Saved Offline',
                      style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => offlineService.deletePackage(package.id),
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                    label: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 12)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => offlineService.downloadPackage(package.id),
                  icon: const Icon(Icons.download, size: 18),
                  label: Text('Download Region (${package.sizeMb} MB)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
