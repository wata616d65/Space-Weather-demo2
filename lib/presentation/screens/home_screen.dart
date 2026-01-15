import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../providers/providers.dart';
import '../widgets/mode_toggle.dart';
import '../widgets/risk_panel.dart';
import 'location_search_screen.dart';

/// メイン画面
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCoreMode = ref.watch(displayModeProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);
    final allRisks = ref.watch(allRisksProvider);
    final spaceWeather = ref.watch(spaceWeatherDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(spaceWeatherDataProvider);
          },
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.surfaceColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ヘッダー
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトル行
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Space Weather',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              spaceWeather.when(
                                data: (data) => Text(
                                  '更新: ${DateFormatter.formatRelative(data.fetchedAt)}',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                loading: () => const Text(
                                  '読み込み中...',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                error: (_, __) => const Text(
                                  'オフライン（キャッシュ表示）',
                                  style: TextStyle(
                                    color: AppTheme.cautionColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ModeToggle(
                            isCoreMode: isCoreMode,
                            onChanged: (isCore) {
                              ref
                                  .read(displayModeProvider.notifier)
                                  .setMode(isCore);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 地点セレクター
                      _buildLocationSelector(context, ref, selectedLocation),
                      const SizedBox(height: 16),

                      // 全体サマリー
                      allRisks.when(
                        data: (risks) => _buildSummaryCard(risks.overallSummary),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),

              // リスクパネル一覧
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: allRisks.when(
                  data: (risks) => SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildListDelegate([
                      RiskPanel(risk: risks.drone, isCoreMode: isCoreMode),
                      RiskPanel(risk: risks.gps, isCoreMode: isCoreMode),
                      RiskPanel(risk: risks.radio, isCoreMode: isCoreMode),
                      RiskPanel(risk: risks.radiation, isCoreMode: isCoreMode),
                    ]),
                  ),
                  loading: () => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(60),
                        child: Column(
                          children: const [
                            CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                              strokeWidth: 2,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'データを取得中...',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: _buildErrorCard(e.toString()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector(
    BuildContext context,
    WidgetRef ref,
    dynamic selectedLocation,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LocationSearchScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedLocation?.name ?? '地点を選択',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (selectedLocation != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      selectedLocation.coordinateString,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.secondaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.dangerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dangerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.cloud_off,
            color: AppTheme.dangerColor,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'データを取得できませんでした',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'インターネット接続を確認してください',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
