import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineMapPackage {
  final String id;
  final String title;
  final String subtitle;
  final String coverage;
  final int sizeMb;
  final int placesCount;
  final bool isDownloaded;
  final double downloadProgress;
  final bool isDownloading;
  final DateTime? lastUpdated;

  const OfflineMapPackage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverage,
    required this.sizeMb,
    required this.placesCount,
    this.isDownloaded = false,
    this.downloadProgress = 0.0,
    this.isDownloading = false,
    this.lastUpdated,
  });

  OfflineMapPackage copyWith({
    bool? isDownloaded,
    double? downloadProgress,
    bool? isDownloading,
    DateTime? lastUpdated,
  }) {
    return OfflineMapPackage(
      id: id,
      title: title,
      subtitle: subtitle,
      coverage: coverage,
      sizeMb: sizeMb,
      placesCount: placesCount,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloading: isDownloading ?? this.isDownloading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class OfflineMapService extends ChangeNotifier {
  static const String _storageKey = 'offline_map_packages_v1';
  static const String _wifiOnlyKey = 'offline_map_wifi_only';

  bool _wifiOnly = true;
  bool get wifiOnly => _wifiOnly;

  List<OfflineMapPackage> _packages = [
    OfflineMapPackage(
      id: 'goa_complete',
      title: 'Goa Regional Pack (Recommended)',
      subtitle: 'Complete step-free routes, POIs, hospitals & transit',
      coverage: 'Panaji, Margao, Vasco, Mapusa, Bambolim GMC & coastline',
      sizeMb: 52,
      placesCount: 450,
      isDownloaded: true,
      lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
    ),
    const OfflineMapPackage(
      id: 'north_goa',
      title: 'North Goa District Pack',
      subtitle: 'Panaji, Mapusa, Porvorim & coastal accessibility',
      coverage: 'District Hospital, Civil Ramps, Kadamba Bus Terminal',
      sizeMb: 28,
      placesCount: 240,
      isDownloaded: false,
    ),
    const OfflineMapPackage(
      id: 'south_goa',
      title: 'South Goa District Pack',
      subtitle: 'Margao, Vasco, Davorlim & South Goa transit nodes',
      coverage: 'District Civil Hospital, Railway Station, KTC Margao',
      sizeMb: 26,
      placesCount: 210,
      isDownloaded: false,
    ),
    const OfflineMapPackage(
      id: 'gps_vicinity',
      title: 'Nearby Vicinity Cache (15 km Radius)',
      subtitle: 'High-density tile buffer around your current GPS location',
      coverage: 'Immediate neighborhood, nearby clinics & accessible stops',
      sizeMb: 14,
      placesCount: 95,
      isDownloaded: false,
    ),
  ];

  List<OfflineMapPackage> get packages => List.unmodifiable(_packages);

  int get totalDownloadedMb {
    return _packages
        .where((p) => p.isDownloaded)
        .fold(0, (sum, p) => sum + p.sizeMb);
  }

  OfflineMapService() {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _wifiOnly = prefs.getBool(_wifiOnlyKey) ?? true;
      final savedIds = prefs.getStringList(_storageKey);
      if (savedIds != null) {
        _packages = _packages.map((p) {
          final downloaded = savedIds.contains(p.id);
          return p.copyWith(isDownloaded: downloaded);
        }).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_wifiOnlyKey, _wifiOnly);
      final downloadedIds = _packages
          .where((p) => p.isDownloaded)
          .map((p) => p.id)
          .toList();
      await prefs.setStringList(_storageKey, downloadedIds);
    } catch (_) {}
  }

  void setWifiOnly(bool value) {
    _wifiOnly = value;
    _saveState();
    notifyListeners();
  }

  Future<void> downloadPackage(String packageId) async {
    final index = _packages.indexWhere((p) => p.id == packageId);
    if (index == -1) return;

    _packages[index] = _packages[index].copyWith(
      isDownloading: true,
      downloadProgress: 0.1,
    );
    notifyListeners();

    // Smooth realistic download simulation in chunks
    final steps = [0.25, 0.50, 0.75, 0.95, 1.0];
    for (final progress in steps) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      _packages[index] = _packages[index].copyWith(
        downloadProgress: progress,
      );
      notifyListeners();
    }

    _packages[index] = _packages[index].copyWith(
      isDownloaded: true,
      isDownloading: false,
      downloadProgress: 1.0,
      lastUpdated: DateTime.now(),
    );
    _saveState();
    notifyListeners();
  }

  Future<void> deletePackage(String packageId) async {
    final index = _packages.indexWhere((p) => p.id == packageId);
    if (index == -1) return;

    _packages[index] = _packages[index].copyWith(
      isDownloaded: false,
      isDownloading: false,
      downloadProgress: 0.0,
      lastUpdated: null,
    );
    _saveState();
    notifyListeners();
  }
}
