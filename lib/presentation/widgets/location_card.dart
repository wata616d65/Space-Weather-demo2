import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user_location.dart';

/// 地点カードウィジェット
class LocationCard extends StatelessWidget {
  final UserLocation location;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const LocationCard({
    super.key,
    required this.location,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.2),
                    AppTheme.secondaryColor.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected ? null : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : AppTheme.textMuted.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // アイコン
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.2)
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                location.isCurrentLocation
                    ? Icons.my_location
                    : Icons.location_on_outlined,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // 地点情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          location.name,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (location.isCurrentLocation) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'GPS',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.coordinateString,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getLatitudeZoneLabel(location.latitudeZone),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // 削除ボタン
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close, size: 18),
                color: AppTheme.textMuted,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),

            // 選択インジケーター
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getLatitudeZoneLabel(LatitudeZone zone) {
    switch (zone) {
      case LatitudeZone.low:
        return '低緯度帯（電離層影響大）';
      case LatitudeZone.mid:
        return '中緯度帯（標準）';
      case LatitudeZone.high:
        return '高緯度帯（磁気嵐影響大）';
    }
  }
}
