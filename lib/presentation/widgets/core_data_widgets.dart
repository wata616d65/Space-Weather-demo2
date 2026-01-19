import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 出典表示バッジ
/// データソースの信頼性を示すためにCore層向け画面で使用
class DataSourceBadge extends StatelessWidget {
  final String source;
  final String? url;
  final DateTime? lastUpdated;

  const DataSourceBadge({
    super.key,
    required this.source,
    this.url,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.textMuted.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: 12,
            color: AppTheme.accentColor.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            '出典: $source',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (lastUpdated != null) ...[
            const SizedBox(width: 6),
            Text(
              '更新: ${_formatTime(lastUpdated!)}',
              style: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.7),
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return '今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }
}

/// ミニ数値バー（時系列表示の代わり）
class MiniValueBar extends StatelessWidget {
  final double value;
  final double maxValue;
  final Color color;
  final String? label;

  const MiniValueBar({
    super.key,
    required this.value,
    required this.maxValue,
    required this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label!,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.6), color],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Core詳細データカード
class CoreDataCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String currentValue;
  final String? unit;
  final String status;
  final Color statusColor;
  final String source;
  final DateTime? lastUpdated;
  final List<CoreDataRow>? details;
  final Widget? chart;

  const CoreDataCard({
    super.key,
    required this.title,
    required this.icon,
    required this.currentValue,
    this.unit,
    required this.status,
    required this.statusColor,
    required this.source,
    this.lastUpdated,
    this.details,
    this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: statusColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 現在値
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentValue,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    unit!,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // チャートまたは詳細
          if (chart != null) ...[const SizedBox(height: 12), chart!],

          if (details != null && details!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppTheme.textMuted, height: 1),
            const SizedBox(height: 12),
            ...details!.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      d.label,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      d.value,
                      style: TextStyle(
                        color: d.valueColor ?? AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 出典
          const SizedBox(height: 12),
          DataSourceBadge(source: source, lastUpdated: lastUpdated),
        ],
      ),
    );
  }
}

/// 詳細行データ
class CoreDataRow {
  final String label;
  final String value;
  final Color? valueColor;

  CoreDataRow({required this.label, required this.value, this.valueColor});
}
