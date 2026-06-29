// lib/widgets/asset_image_or_icon.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Виджет, который пытается загрузить изображение из ассетов,
/// а если файла нет — показывает иконку
class AssetImageOrIcon extends StatelessWidget {
  final String assetPath;
  final IconData fallbackIcon;
  final Color? iconColor;
  final double? iconSize;
  final double? imageWidth;
  final double? imageHeight;
  final BoxFit fit;

  const AssetImageOrIcon({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    this.iconColor,
    this.iconSize,
    this.imageWidth,
    this.imageHeight,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _assetExists(assetPath),
      builder: (context, snapshot) {
        final exists = snapshot.data ?? false;
        
        if (exists) {
          return Image.asset(
            assetPath,
            width: imageWidth,
            height: imageHeight,
            fit: fit,
            errorBuilder: (_, _, _) => _buildFallbackIcon(),
          );
        } else {
          return _buildFallbackIcon();
        }
      },
    );
  }

  Widget _buildFallbackIcon() {
    return Icon(
      fallbackIcon,
      color: iconColor,
      size: iconSize ?? 24,
    );
  }

  /// Проверка существования файла в ассетах
  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}