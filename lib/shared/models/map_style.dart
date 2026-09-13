import 'package:flutter/material.dart';

enum MapStyle {
  standard,
  satellite,
  terrain3d,
  highContrastDark;

  String get displayName {
    switch (this) {
      case MapStyle.standard:
        return 'Standard Street';
      case MapStyle.satellite:
        return 'Satellite Aerial';
      case MapStyle.terrain3d:
        return '3D Topo & Incline Slopes';
      case MapStyle.highContrastDark:
        return 'Dark High-Contrast';
    }
  }

  String get description {
    switch (this) {
      case MapStyle.standard:
        return 'Clear accessible roads, footpaths, and verified landmarks';
      case MapStyle.satellite:
        return 'Photorealistic aerial imagery showing actual sidewalks & curb cuts';
      case MapStyle.terrain3d:
        return 'Topographical contours & terrain gradients for wheelchair slopes';
      case MapStyle.highContrastDark:
        return 'High-visibility dark theme optimized for low-vision accessibility';
    }
  }

  IconData get icon {
    switch (this) {
      case MapStyle.standard:
        return Icons.map;
      case MapStyle.satellite:
        return Icons.satellite_alt;
      case MapStyle.terrain3d:
        return Icons.terrain;
      case MapStyle.highContrastDark:
        return Icons.dark_mode;
    }
  }

  String get urlTemplate {
    switch (this) {
      case MapStyle.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapStyle.terrain3d:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapStyle.highContrastDark:
        return 'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png';
    }
  }
}
