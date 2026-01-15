import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/risk_result.dart';

/// リスク表示パネルウィジェット
/// Light/Coreモードに応じて表示を切り替える
class RiskPanel extends StatelessWidget {
  final RiskResult risk;
  final bool isCoreMode;

  const RiskPanel({
    super.key,
    required this.risk,
    required this.isCoreMode,
  });

  @override
  Widget build(BuildContext context) {
    final color = getRiskColor(risk.level);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardColor,
            AppTheme.cardColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 背景のグラデーションアクセント
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // コンテンツ
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー（アイコン + タイトル）
                  Row(
                    children: [
                      _buildIcon(color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              risk.type.label,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              risk.statusText,
                              style: TextStyle(
                                color: color,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildLevelIndicator(color),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // アドバイス
                  Text(
                    risk.advice,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Coreモードの場合は詳細情報を表示
                  if (isCoreMode) ...[
                    const Spacer(),
                    const Divider(color: AppTheme.textMuted, height: 16),
                    Text(
                      risk.detailedInfo,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    IconData iconData;
    switch (risk.type) {
      case RiskType.drone:
        iconData = Icons.flight;
        break;
      case RiskType.gps:
        iconData = Icons.gps_fixed;
        break;
      case RiskType.radio:
        iconData = Icons.cell_tower;
        break;
      case RiskType.radiation:
        iconData = Icons.health_and_safety;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildLevelIndicator(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lv.',
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${risk.level}',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
