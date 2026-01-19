import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/datasources/noaa_space_weather_service.dart';
import '../providers/providers.dart';
import '../widgets/mode_toggle.dart';
import '../widgets/risk_panel.dart';
import 'location_search_screen.dart';
import 'core_detail_screen.dart';

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
                        data: (risks) =>
                            _buildSummaryCard(risks.overallSummary),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),

              // リスクパネル一覧
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, isCoreMode ? 16 : 100),
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
                  error: (e, _) =>
                      SliverToBoxAdapter(child: _buildErrorCard(e.toString())),
                ),
              ),

              // Core詳細セクション（Coreモードのみ表示）
              if (isCoreMode)
                SliverToBoxAdapter(
                  child: _buildCoreDetailSection(context, ref),
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
          MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
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
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
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

  Widget _buildCoreDetailSection(BuildContext context, WidgetRef ref) {
    final kp = ref.watch(kpIndexProvider);
    final solarWind = ref.watch(solarWindProvider);
    final xray = ref.watch(xrayFluxProvider);
    final proton = ref.watch(protonFluxProvider);
    final aurora = ref.watch(auroraForecastProvider);
    final scales = ref.watch(noaaScalesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクションヘッダー
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.insights,
                  color: AppTheme.accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Core データ詳細',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'NOAA Space Weather Prediction Center',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.invalidate(kpIndexProvider);
                  ref.invalidate(solarWindProvider);
                  ref.invalidate(xrayFluxProvider);
                  ref.invalidate(protonFluxProvider);
                  ref.invalidate(auroraForecastProvider);
                  ref.invalidate(noaaScalesProvider);
                },
                icon: const Icon(
                  Icons.refresh,
                  color: AppTheme.accentColor,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // NOAAスケール
          scales.when(
            data: (data) =>
                data != null ? _buildNoaaScalesRow(data) : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 12),

          // 2カラムレイアウトで各データを表示
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左カラム
              Expanded(
                child: Column(
                  children: [
                    // 太陽フレア
                    xray.when(
                      data: (data) => data.isNotEmpty
                          ? _buildMiniDataCard(
                              context,
                              '太陽フレア',
                              Icons.wb_sunny,
                              data.last.flareClass,
                              '級',
                              data.last.level,
                              _getFlareColor(data.last.flareClass),
                              description:
                                  '太陽の大気中で発生する爆発現象です。X線フラックスで測定され、A（最小）～X（最大）までの5段階に分類されます。X級フレアは地球に大きな影響を与え、短波通信の障害やGPS誤差の原因となります。',
                            )
                          : const SizedBox(),
                      loading: () => _buildLoadingMiniCard(),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 8),
                    // 太陽風
                    solarWind.when(
                      data: (data) => data.isNotEmpty
                          ? _buildMiniDataCard(
                              context,
                              '太陽風速',
                              Icons.air,
                              data.last.speed.toStringAsFixed(0),
                              'km/s',
                              data.last.speedLevel,
                              _getSolarWindColor(data.last.speed),
                              description:
                                  '太陽から放出されるプラズマ（荷電粒子）の流れです。通常300-500km/sですが、太陽活動が活発な時は800km/s以上になることも。高速の太陽風は地磁気嵐を引き起こし、オーロラが見える原因となります。',
                            )
                          : const SizedBox(),
                      loading: () => _buildLoadingMiniCard(),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 8),
                    // オーロラ
                    aurora.when(
                      data: (data) => data != null
                          ? _buildMiniDataCard(
                              context,
                              'オーロラ',
                              Icons.auto_awesome,
                              '${data.visibleLatitude.toStringAsFixed(0)}°',
                              'N/S',
                              data.intensity,
                              data.maxKp >= 5
                                  ? AppTheme.accentColor
                                  : AppTheme.textMuted,
                              description:
                                  '太陽風が地球の磁場と大気と相互作用して発光する現象です。表示は可視境界の緯度。Kp指数が高いと低緯度でも見られる可能性があります。北海道（緯度43°）では強い地磁気嵐時に観測されることがあります。',
                            )
                          : const SizedBox(),
                      loading: () => _buildLoadingMiniCard(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 右カラム
              Expanded(
                child: Column(
                  children: [
                    // Kp指数
                    kp.when(
                      data: (data) => data.isNotEmpty
                          ? _buildMiniDataCard(
                              context,
                              '地磁気指数',
                              Icons.compass_calibration,
                              data.last.kpValue.toStringAsFixed(1),
                              'Kp',
                              data.last.level,
                              _getKpColor(data.last.kpValue),
                              description:
                                  'Kp指数は地球全体の地磁気活動の指標で、0（静穏）～9（極めて大きな嵐）まで。0-3は通常、5以上は地磁気嵐と分類されます。ドローンのコンパス精度やGPSに影響します。',
                            )
                          : const SizedBox(),
                      loading: () => _buildLoadingMiniCard(),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 8),
                    // プロトン
                    proton.when(
                      data: (data) => data.isNotEmpty
                          ? _buildMiniDataCard(
                              context,
                              'プロトン',
                              Icons.flash_on,
                              'S${data.last.sScale}',
                              '',
                              data.last.level,
                              _getProtonColor(data.last.sScale),
                              description:
                                  '太陽フレアやCMEに伴って放出される高エネルギー粒子です。Sスケールで表0～5に分類。S2以上では極域航路の航空機乗客の被ばくが増加し、S4以上では人工衛星にも影響します。',
                            )
                          : const SizedBox(),
                      loading: () => _buildLoadingMiniCard(),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 8),
                    // TEC推定
                    kp.when(
                      data: (data) {
                        if (data.isEmpty) return const SizedBox();
                        final tecVar = (data.last.kpValue * 5).round();
                        return _buildMiniDataCard(
                          context,
                          'TEC推定',
                          Icons.satellite_alt,
                          '±$tecVar',
                          'TECU',
                          tecVar > 20
                              ? 'GPS誤差大'
                              : tecVar > 10
                              ? 'GPS誤差中'
                              : '通常',
                          tecVar > 20
                              ? AppTheme.dangerColor
                              : tecVar > 10
                              ? AppTheme.warningColor
                              : AppTheme.safeColor,
                          description:
                              '電離圏全電子数（TEC）はGPS信号の精度に影響する指標です。地磁気嵐時には変動が大きくなり、GPSの位置誤差が数メートル～数十メートルになることも。※この値はKp指数からの推定値です。',
                        );
                      },
                      loading: () => _buildLoadingMiniCard(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 出典
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, color: AppTheme.accentColor, size: 12),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '出典: NOAA Space Weather Prediction Center (商用利用可)',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoaaScalesRow(NoaaScalesData data) {
    return Row(
      children: [
        Expanded(
          child: _buildScaleChip('R', data.rScale, AppTheme.cautionColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildScaleChip('S', data.sScale, AppTheme.warningColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildScaleChip('G', data.gScale, AppTheme.dangerColor),
        ),
      ],
    );
  }

  Widget _buildScaleChip(String label, int scale, Color color) {
    final isActive = scale > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: (isActive ? color : AppTheme.textMuted).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isActive ? color : AppTheme.textMuted).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '$label$scale',
          style: TextStyle(
            color: isActive ? color : AppTheme.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniDataCard(
    BuildContext context,
    String title,
    IconData icon,
    String value,
    String unit,
    String status,
    Color color, {
    String? description,
  }) {
    return GestureDetector(
      onTap: () => _showCoreDetailSheet(
        context,
        title,
        icon,
        value,
        unit,
        status,
        color,
        description,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showCoreDetailSheet(
    BuildContext context,
    String title,
    IconData icon,
    String value,
    String unit,
    String status,
    Color color,
    String? description,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  value,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                if (unit.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      unit,
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 説明
                  if (description != null)
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
                              Icon(Icons.help_outline, color: color, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '$titleとは',
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
                            description,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 出典
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        color: AppTheme.accentColor,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '出典: NOAA Space Weather Prediction Center',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
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
    );
  }

  Widget _buildLoadingMiniCard() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

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

  Color _getKpColor(double kp) {
    if (kp >= 7) return AppTheme.dangerColor;
    if (kp >= 5) return AppTheme.warningColor;
    if (kp >= 4) return AppTheme.cautionColor;
    return AppTheme.safeColor;
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
          Icon(Icons.cloud_off, color: AppTheme.dangerColor, size: 48),
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
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
