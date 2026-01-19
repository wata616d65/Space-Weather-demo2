import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/risk_result.dart';

/// リスク表示パネルウィジェット
/// Light/Coreモードに応じて表示を切り替える
class RiskPanel extends StatelessWidget {
  final RiskResult risk;
  final bool isCoreMode;

  const RiskPanel({super.key, required this.risk, required this.isCoreMode});

  @override
  Widget build(BuildContext context) {
    final color = getRiskColor(risk.level);

    return GestureDetector(
      onTap: () => _showDetailSheet(context, color),
      child: Container(
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
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIcon(color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // タイプラベル（完全表示）
                              Text(
                                risk.type.label,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // ステータスとLv
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      risk.statusText,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCompactLevelIndicator(color),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // アドバイス
                    Expanded(
                      child: Text(
                        risk.advice,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Coreモードの場合は詳細情報を表示
                    if (isCoreMode) ...[
                      const Divider(color: AppTheme.textMuted, height: 12),
                      Text(
                        risk.detailedInfo,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // タップヒント
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 10,
                          color: AppTheme.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '詳細',
                          style: TextStyle(
                            color: AppTheme.textMuted.withValues(alpha: 0.5),
                            fontSize: 9,
                          ),
                        ),
                      ],
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

  void _showDetailSheet(BuildContext context, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDetailSheet(color),
    );
  }

  Widget _buildDetailSheet(Color color) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー
                Row(
                  children: [
                    _buildIcon(color),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            risk.type.label,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            risk.statusText,
                            style: TextStyle(
                              color: color,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildLevelIndicator(color),
                  ],
                ),
                const SizedBox(height: 24),

                // 説明
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: color, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            '現在の状況',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        risk.advice,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 詳細データ
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: color, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            '詳細データ',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        risk.detailedInfo,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // リスクタイプの説明
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help_outline, color: color, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${risk.type.label}とは',
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getRiskTypeDescription(risk.type),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRiskTypeDescription(RiskType type) {
    switch (type) {
      case RiskType.drone:
        return 'ドローン・コンパス予報は、地磁気嵐による電子コンパスへの影響を予測します。Kp指数と緯度から計算され、高緯度ほど影響が大きくなります。レベル4以上では飛行を控えることを推奨します。';
      case RiskType.gps:
        return 'GPS・位置情報予報は、電離層の乱れによるGPS精度への影響を予測します。赤道付近と高緯度で影響が大きく、中緯度（日本）は比較的安定しています。レベル4以上では代替手段の用意を推奨します。';
      case RiskType.radio:
        return '通信・電波予報は、太陽フレアによる短波通信への影響を予測します。これはデリンジャー現象と呼ばれ、地球の昼間側全域に影響します。航空・船舶通信に注意が必要です。';
      case RiskType.radiation:
        return '航空・被ばく予報は、高エネルギー粒子による航空機乗客の被ばくリスクを予測します。特に極域航路で影響が大きく、妊婦や頻繁に飛行する方は注意が必要です。';
    }
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
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildLevelIndicator(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
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

  Widget _buildCompactLevelIndicator(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lv.',
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${risk.level}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
