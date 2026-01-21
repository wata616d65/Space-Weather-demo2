import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user_location.dart';
import '../providers/providers.dart';

/// 設定画面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final locations = ref.watch(locationsProvider);

    // テーマに応じた色を取得
    final bgColor = isDarkMode
        ? AppTheme.backgroundColor
        : AppTheme.lightBackgroundColor;
    final surfaceColor = isDarkMode
        ? AppTheme.surfaceColor
        : AppTheme.lightSurfaceColor;
    final textPrimary = isDarkMode
        ? AppTheme.textPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = isDarkMode
        ? AppTheme.textSecondary
        : AppTheme.lightTextSecondary;
    final textMuted = isDarkMode ? AppTheme.textMuted : AppTheme.lightTextMuted;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '設定',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ========== 通知設定 ==========
          _buildSectionHeader('通知設定', textPrimary),
          const SizedBox(height: 12),

          // 通知ON/OFF
          _buildSettingCard(
            surfaceColor: surfaceColor,
            child: SwitchListTile(
              title: Text('通知を有効にする', style: TextStyle(color: textPrimary)),
              subtitle: Text(
                'リスクレベルの変動時に通知します',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
              value: notificationSettings.enabled,
              onChanged: (value) {
                ref
                    .read(notificationSettingsProvider.notifier)
                    .setEnabled(value);
              },
              activeColor: AppTheme.accentColor,
            ),
          ),

          // 閾値設定
          if (notificationSettings.enabled) ...[
            const SizedBox(height: 12),
            _buildSettingCard(
              surfaceColor: surfaceColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('通知する閾値', style: TextStyle(color: textPrimary)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getThresholdColor(
                              notificationSettings.threshold,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Lv.${notificationSettings.threshold} 以上',
                            style: TextStyle(
                              color: _getThresholdColor(
                                notificationSettings.threshold,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'このレベル以上に変動した際に通知されます',
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: notificationSettings.threshold.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: _getThresholdColor(
                        notificationSettings.threshold,
                      ),
                      onChanged: (value) {
                        ref
                            .read(notificationSettingsProvider.notifier)
                            .setThreshold(value.round());
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lv.1',
                          style: TextStyle(color: textMuted, fontSize: 10),
                        ),
                        Text(
                          'Lv.2',
                          style: TextStyle(color: textMuted, fontSize: 10),
                        ),
                        Text(
                          'Lv.3',
                          style: TextStyle(color: textMuted, fontSize: 10),
                        ),
                        Text(
                          'Lv.4',
                          style: TextStyle(color: textMuted, fontSize: 10),
                        ),
                        Text(
                          'Lv.5',
                          style: TextStyle(color: textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 通知対象地点
            const SizedBox(height: 12),
            _buildSettingCard(
              surfaceColor: surfaceColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('通知対象の地点', style: TextStyle(color: textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      '選択した地点のリスク変動のみ通知します',
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (locations.isEmpty)
                      Text(
                        '登録されている地点がありません',
                        style: TextStyle(color: textMuted),
                      )
                    else
                      ...locations.map(
                        (location) => _buildLocationCheckbox(
                          location: location,
                          isSelected: notificationSettings.locationIds.contains(
                            location.id,
                          ),
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onChanged: () {
                            ref
                                .read(notificationSettingsProvider.notifier)
                                .toggleLocation(location.id);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ========== テーマ設定 ==========
          _buildSectionHeader('テーマ設定', textPrimary),
          const SizedBox(height: 12),

          _buildSettingCard(
            surfaceColor: surfaceColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildThemeOption(
                      label: 'ダーク',
                      icon: Icons.dark_mode,
                      isSelected: isDarkMode,
                      onTap: () =>
                          ref.read(themeProvider.notifier).setDarkMode(true),
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThemeOption(
                      label: 'ライト',
                      icon: Icons.light_mode,
                      isSelected: !isDarkMode,
                      onTap: () =>
                          ref.read(themeProvider.notifier).setDarkMode(false),
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ========== その他 ==========
          _buildSectionHeader('その他', textPrimary),
          const SizedBox(height: 12),

          _buildSettingCard(
            surfaceColor: surfaceColor,
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: textMuted),
              title: Text('キャッシュをクリア', style: TextStyle(color: textPrimary)),
              subtitle: Text(
                '天気データのキャッシュを削除します',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
              onTap: () async {
                final localStorage = ref.read(localStorageProvider);
                await localStorage.clearAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('キャッシュをクリアしました')),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 12),

          _buildSettingCard(
            surfaceColor: surfaceColor,
            child: ListTile(
              leading: Icon(Icons.info_outline, color: textMuted),
              title: Text('バージョン情報', style: TextStyle(color: textPrimary)),
              subtitle: Text(
                'v1.0.0',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSettingCard({
    required Color surfaceColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Color _getThresholdColor(int threshold) {
    switch (threshold) {
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

  Widget _buildLocationCheckbox({
    required UserLocation location,
    required bool isSelected,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onChanged,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                color: isSelected ? AppTheme.accentColor : textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(location.name, style: TextStyle(color: textPrimary)),
                    Text(
                      location.coordinateString,
                      style: TextStyle(color: textSecondary, fontSize: 11),
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

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : textMuted.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primaryColor : textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
