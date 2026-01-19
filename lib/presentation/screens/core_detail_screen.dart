import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/noaa_space_weather_service.dart';
import '../widgets/core_data_widgets.dart';

/// Core詳細データプロバイダー
final noaaServiceProvider = Provider((ref) => NoaaSpaceWeatherService());

final kpIndexProvider = FutureProvider<List<KpIndexData>>((ref) async {
  return ref.read(noaaServiceProvider).getKpIndex();
});

final solarWindProvider = FutureProvider<List<SolarWindData>>((ref) async {
  return ref.read(noaaServiceProvider).getSolarWind();
});

final solarWindMagProvider = FutureProvider<List<SolarWindMagData>>((
  ref,
) async {
  return ref.read(noaaServiceProvider).getSolarWindMag();
});

final xrayFluxProvider = FutureProvider<List<XrayFluxData>>((ref) async {
  return ref.read(noaaServiceProvider).getXrayFlux();
});

final protonFluxProvider = FutureProvider<List<ProtonFluxData>>((ref) async {
  return ref.read(noaaServiceProvider).getProtonFlux();
});

final auroraForecastProvider = FutureProvider<AuroraForecast?>((ref) async {
  return ref.read(noaaServiceProvider).getAuroraForecast();
});

final noaaScalesProvider = FutureProvider<NoaaScalesData?>((ref) async {
  return ref.read(noaaServiceProvider).getNoaaScales();
});

/// Core層向け詳細データ画面
class CoreDetailScreen extends ConsumerWidget {
  const CoreDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Core データ詳細',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: () {
              ref.invalidate(kpIndexProvider);
              ref.invalidate(solarWindProvider);
              ref.invalidate(xrayFluxProvider);
              ref.invalidate(protonFluxProvider);
              ref.invalidate(auroraForecastProvider);
              ref.invalidate(noaaScalesProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(kpIndexProvider);
          ref.invalidate(solarWindProvider);
          ref.invalidate(xrayFluxProvider);
          ref.invalidate(protonFluxProvider);
          ref.invalidate(auroraForecastProvider);
          ref.invalidate(noaaScalesProvider);
        },
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.surfaceColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NOAAスケールサマリー
              _buildNoaaScalesSummary(ref),
              const SizedBox(height: 20),

              // 6つの宇宙天気現象
              const Text(
                '宇宙天気詳細データ',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'リアルタイムデータ（NOAA SWPC提供）',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // 太陽フレア（X線フラックス）
              _buildSolarFlareCard(ref),
              const SizedBox(height: 12),

              // 地磁気指数（Kp指数）
              _buildKpIndexCard(ref),
              const SizedBox(height: 12),

              // 太陽風速
              _buildSolarWindCard(ref),
              const SizedBox(height: 12),

              // プロトン現象
              _buildProtonCard(ref),
              const SizedBox(height: 12),

              // 電離圏TEC（推定）
              _buildTecCard(ref),
              const SizedBox(height: 12),

              // オーロラオーバル
              _buildAuroraCard(ref),
              const SizedBox(height: 24),

              // 免責事項
              _buildDisclaimer(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoaaScalesSummary(WidgetRef ref) {
    final scales = ref.watch(noaaScalesProvider);

    return scales.when(
      data: (data) {
        if (data == null) return const SizedBox();

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
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'NOAA スケール（現在の状況）',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildScaleIndicator(
                      'R',
                      data.rScale,
                      AppTheme.cautionColor,
                      '電波障害',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildScaleIndicator(
                      'S',
                      data.sScale,
                      AppTheme.warningColor,
                      '放射線',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildScaleIndicator(
                      'G',
                      data.gScale,
                      AppTheme.dangerColor,
                      '地磁気嵐',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildScaleIndicator(
    String label,
    int scale,
    Color color,
    String desc,
  ) {
    final activeColor = scale > 0 ? color : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '$label$scale',
            style: TextStyle(
              color: activeColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSolarFlareCard(WidgetRef ref) {
    final xray = ref.watch(xrayFluxProvider);

    return xray.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox();

        final latest = data.last;
        final color = _getFlareColor(latest.flareClass);

        return CoreDataCard(
          title: '太陽フレア',
          icon: Icons.wb_sunny,
          currentValue: latest.flareClass,
          unit: '級',
          status: latest.level,
          statusColor: color,
          source: 'NOAA/SWPC GOES-16',
          lastUpdated: latest.timestamp,
          details: [
            CoreDataRow(
              label: 'X線フラックス',
              value: '${latest.flux.toStringAsExponential(2)} W/m²',
            ),
            CoreDataRow(label: '観測時刻', value: _formatTime(latest.timestamp)),
          ],
          chart: MiniValueBar(
            value: _flareClassToValue(latest.flareClass),
            maxValue: 5,
            color: color,
            label: '24時間推移',
          ),
        );
      },
      loading: () => _buildLoadingCard('太陽フレア'),
      error: (_, __) => _buildErrorCard('太陽フレア'),
    );
  }

  Widget _buildKpIndexCard(WidgetRef ref) {
    final kp = ref.watch(kpIndexProvider);

    return kp.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox();

        final latest = data.last;
        final color = _getKpColor(latest.kpValue);

        return CoreDataCard(
          title: '地磁気指数',
          icon: Icons.compass_calibration,
          currentValue: latest.kpValue.toStringAsFixed(1),
          unit: 'Kp',
          status: latest.level,
          statusColor: color,
          source: 'NOAA/SWPC Planetary K-index',
          lastUpdated: latest.timestamp,
          details: [
            CoreDataRow(
              label: 'G-Scale',
              value: 'G${_kpToGScale(latest.kpValue)}',
            ),
            CoreDataRow(label: '更新間隔', value: '3時間'),
          ],
          chart: MiniValueBar(
            value: latest.kpValue,
            maxValue: 9,
            color: color,
            label: 'Kp指数レベル（0-9）',
          ),
        );
      },
      loading: () => _buildLoadingCard('地磁気指数'),
      error: (_, __) => _buildErrorCard('地磁気指数'),
    );
  }

  Widget _buildSolarWindCard(WidgetRef ref) {
    final wind = ref.watch(solarWindProvider);
    final mag = ref.watch(solarWindMagProvider);

    return wind.when(
      data: (windData) {
        if (windData.isEmpty) return const SizedBox();

        final latest = windData.last;
        final color = _getSolarWindColor(latest.speed);

        final bzValue = mag.when(
          data: (m) => m.isNotEmpty ? m.last.bz : 0.0,
          loading: () => 0.0,
          error: (_, __) => 0.0,
        );

        return CoreDataCard(
          title: '太陽風',
          icon: Icons.air,
          currentValue: latest.speed.toStringAsFixed(0),
          unit: 'km/s',
          status: latest.speedLevel,
          statusColor: color,
          source: 'NOAA/SWPC DSCOVR',
          lastUpdated: latest.timestamp,
          details: [
            CoreDataRow(
              label: 'プラズマ密度',
              value: '${latest.density.toStringAsFixed(1)} p/cm³',
            ),
            CoreDataRow(
              label: 'Bz成分',
              value: '${bzValue.toStringAsFixed(1)} nT',
              valueColor: bzValue < 0
                  ? AppTheme.dangerColor
                  : AppTheme.safeColor,
            ),
            CoreDataRow(
              label: '磁場方向',
              value: bzValue < 0 ? '南向き（活発）' : '北向き（静穏）',
            ),
          ],
          chart: MiniValueBar(
            value: latest.speed,
            maxValue: 1000,
            color: color,
            label: '太陽風速（300-800 km/s 通常）',
          ),
        );
      },
      loading: () => _buildLoadingCard('太陽風'),
      error: (_, __) => _buildErrorCard('太陽風'),
    );
  }

  Widget _buildProtonCard(WidgetRef ref) {
    final proton = ref.watch(protonFluxProvider);

    return proton.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox();

        final latest = data.last;
        final color = _getProtonColor(latest.sScale);

        return CoreDataCard(
          title: 'プロトン現象',
          icon: Icons.flash_on,
          currentValue: 'S${latest.sScale}',
          status: latest.level,
          statusColor: color,
          source: 'NOAA/SWPC GOES',
          lastUpdated: latest.timestamp,
          details: [
            CoreDataRow(
              label: 'フラックス',
              value: '${latest.flux.toStringAsExponential(1)} pfu',
            ),
            CoreDataRow(label: 'エネルギー', value: latest.energy),
            CoreDataRow(label: '航空リスク', value: latest.sScale >= 2 ? '高' : '低'),
          ],
        );
      },
      loading: () => _buildLoadingCard('プロトン現象'),
      error: (_, __) => _buildErrorCard('プロトン現象'),
    );
  }

  Widget _buildTecCard(WidgetRef ref) {
    // TECは直接取得できないため、Kp指数から推定
    final kp = ref.watch(kpIndexProvider);

    return kp.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox();

        final kpValue = data.last.kpValue;
        // 経験的な推定: Kp値に基づいてTEC変動を推定
        final tecVariation = (kpValue * 5).round();
        final color = tecVariation > 20
            ? AppTheme.dangerColor
            : tecVariation > 10
            ? AppTheme.warningColor
            : AppTheme.safeColor;

        return CoreDataCard(
          title: '電離圏TEC（推定）',
          icon: Icons.satellite_alt,
          currentValue: '±$tecVariation',
          unit: 'TECU',
          status: tecVariation > 20
              ? 'GPS誤差大'
              : tecVariation > 10
              ? 'GPS誤差中'
              : '通常',
          statusColor: color,
          source: 'Kp指数からの推定値',
          lastUpdated: data.last.timestamp,
          details: [
            CoreDataRow(label: '推定方法', value: 'Kp相関モデル'),
            CoreDataRow(
              label: 'GPS精度影響',
              value: tecVariation > 15 ? 'あり' : 'なし',
            ),
          ],
        );
      },
      loading: () => _buildLoadingCard('電離圏TEC'),
      error: (_, __) => _buildErrorCard('電離圏TEC'),
    );
  }

  Widget _buildAuroraCard(WidgetRef ref) {
    final aurora = ref.watch(auroraForecastProvider);

    return aurora.when(
      data: (data) {
        if (data == null) return const SizedBox();

        final color = data.maxKp >= 5
            ? AppTheme.accentColor
            : AppTheme.textMuted;

        return CoreDataCard(
          title: 'オーロラオーバル',
          icon: Icons.auto_awesome,
          currentValue: '${data.visibleLatitude.toStringAsFixed(0)}°',
          unit: 'N/S',
          status: data.intensity,
          statusColor: color,
          source: 'NOAA/SWPC OVATION Prime',
          lastUpdated: data.fetchedAt,
          details: [
            CoreDataRow(label: '予報Kp', value: data.maxKp.toStringAsFixed(1)),
            CoreDataRow(
              label: '日本可視性',
              value: data.isVisibleAt(35) ? '可能性あり！' : 'なし',
            ),
            CoreDataRow(
              label: '北海道可視性',
              value: data.isVisibleAt(43) ? '可能性あり！' : 'なし',
            ),
          ],
        );
      },
      loading: () => _buildLoadingCard('オーロラオーバル'),
      error: (_, __) => _buildErrorCard('オーロラオーバル'),
    );
  }

  Widget _buildLoadingCard(String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            '$title を読み込み中...',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.dangerColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '$title の取得に失敗',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.textMuted, size: 16),
              SizedBox(width: 8),
              Text(
                'データについて',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• 全データはNOAA Space Weather Prediction Center提供\n'
            '• 商用利用可能・無料（出典表示必須）\n'
            '• 電離圏TECはKp指数からの推定値\n'
            '• 予報精度は状況により変動します',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ========== ヘルパーメソッド ==========

  Color _getFlareColor(String flareClass) {
    switch (flareClass) {
      case 'X':
        return AppTheme.dangerColor;
      case 'M':
        return AppTheme.warningColor;
      case 'C':
        return AppTheme.cautionColor;
      default:
        return AppTheme.safeColor;
    }
  }

  double _flareClassToValue(String flareClass) {
    switch (flareClass) {
      case 'X':
        return 5;
      case 'M':
        return 4;
      case 'C':
        return 3;
      case 'B':
        return 2;
      default:
        return 1;
    }
  }

  Color _getKpColor(double kp) {
    if (kp >= 7) return AppTheme.dangerColor;
    if (kp >= 5) return AppTheme.warningColor;
    if (kp >= 4) return AppTheme.cautionColor;
    return AppTheme.safeColor;
  }

  int _kpToGScale(double kp) {
    if (kp >= 9) return 5;
    if (kp >= 8) return 4;
    if (kp >= 7) return 3;
    if (kp >= 6) return 2;
    if (kp >= 5) return 1;
    return 0;
  }

  Color _getSolarWindColor(double speed) {
    if (speed >= 700) return AppTheme.dangerColor;
    if (speed >= 500) return AppTheme.warningColor;
    if (speed >= 400) return AppTheme.cautionColor;
    return AppTheme.safeColor;
  }

  Color _getProtonColor(int sScale) {
    if (sScale >= 4) return AppTheme.dangerColor;
    if (sScale >= 2) return AppTheme.warningColor;
    if (sScale >= 1) return AppTheme.cautionColor;
    return AppTheme.safeColor;
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} UTC';
  }
}
