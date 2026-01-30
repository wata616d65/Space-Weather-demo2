import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/space_weather_forecast.dart';

/// 4日間予報セクション
class FourDayForecastSection extends StatelessWidget {
  final FourDayForecast forecast;
  final bool isDarkMode;

  const FourDayForecastSection({
    super.key,
    required this.forecast,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDarkMode
        ? AppTheme.textPrimary
        : AppTheme.lightTextPrimary;
    final textMuted = isDarkMode ? AppTheme.textMuted : AppTheme.lightTextMuted;
    final surfaceColor = isDarkMode
        ? AppTheme.surfaceColor
        : AppTheme.lightSurfaceColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションヘッダー
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: AppTheme.accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '4日間予報',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cautionColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '予測含む',
                  style: TextStyle(
                    color: AppTheme.cautionColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 横スクロール可能な日別カード
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: forecast.forecasts.length,
            itemBuilder: (context, index) {
              final dayForecast = forecast.forecasts[index];
              return GestureDetector(
                onTap: () => _showForecastDetail(context, dayForecast),
                child: _buildDayCard(
                  dayForecast,
                  textPrimary,
                  textMuted,
                  surfaceColor,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showForecastDetail(
    BuildContext context,
    SpaceWeatherForecast forecast,
  ) {
    final bgColor = isDarkMode
        ? AppTheme.surfaceColor
        : AppTheme.lightSurfaceColor;
    final textPrimary = isDarkMode
        ? AppTheme.textPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = isDarkMode
        ? AppTheme.textSecondary
        : AppTheme.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getLevelColor(
                      forecast.overallLevel,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv.${forecast.overallLevel}',
                    style: TextStyle(
                      color: _getLevelColor(forecast.overallLevel),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('M月d日').format(forecast.date)}（${_getDayName(forecast.date)}）',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (forecast.confidence == ForecastConfidence.low)
                        Text(
                          '※ CME傾向予測',
                          style: TextStyle(
                            color: AppTheme.cautionColor,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // サマリー
            Text(
              forecast.summary,
              style: TextStyle(color: textPrimary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),

            // 詳細データ
            _buildDetailRow(
              '地磁気',
              forecast.geomagneticLevel,
              textPrimary,
              textSecondary,
            ),
            _buildDetailRow(
              '太陽放射',
              forecast.solarRadiationLevel,
              textPrimary,
              textSecondary,
            ),
            _buildDetailRow(
              '電波障害',
              forecast.radioBlackoutLevel,
              textPrimary,
              textSecondary,
            ),

            const SizedBox(height: 16),

            // 閉じるボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    int level,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getLevelColor(level).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$level',
                style: TextStyle(
                  color: _getLevelColor(level),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: level / 5.0,
              backgroundColor: _getLevelColor(level).withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(_getLevelColor(level)),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(
    SpaceWeatherForecast dayForecast,
    Color textPrimary,
    Color textMuted,
    Color surfaceColor,
  ) {
    final isToday = _isToday(dayForecast.date);
    final dayName = _getDayName(dayForecast.date);
    final dateStr = DateFormat('M/d').format(dayForecast.date);
    final levelColor = _getLevelColor(dayForecast.overallLevel);

    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday
            ? AppTheme.primaryColor.withValues(alpha: 0.15)
            : surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 日付
          Column(
            children: [
              Text(
                dayName,
                style: TextStyle(
                  color: isToday ? AppTheme.primaryColor : textMuted,
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(dateStr, style: TextStyle(color: textPrimary, fontSize: 11)),
            ],
          ),

          // リスクレベル表示
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'Lv.${dayForecast.overallLevel}',
                style: TextStyle(
                  color: levelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 信頼度表示
          if (dayForecast.confidence == ForecastConfidence.low)
            Text(
              'CME傾向',
              style: TextStyle(color: AppTheme.cautionColor, fontSize: 9),
            )
          else if (dayForecast.confidence == ForecastConfidence.medium)
            Text('NOAA予報', style: TextStyle(color: textMuted, fontSize: 9))
          else
            Text(
              dayForecast.geomagneticDescription,
              style: TextStyle(color: textMuted, fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    final diff = targetDay.difference(today).inDays;

    switch (diff) {
      case 0:
        return '今日';
      case 1:
        return '明日';
      case 2:
        return '明後日';
      default:
        final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
        return weekdays[date.weekday - 1];
    }
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
      case 2:
        return AppTheme.safeColor;
      case 3:
        return AppTheme.cautionColor;
      case 4:
      case 5:
        return AppTheme.dangerColor;
      default:
        return AppTheme.textMuted;
    }
  }
}
