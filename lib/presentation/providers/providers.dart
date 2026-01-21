import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local_storage.dart';
import '../../data/datasources/noaa_api_client.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/noaa_repository.dart';
import '../../domain/entities/noaa_data.dart';
import '../../domain/entities/risk_result.dart';
import '../../domain/entities/space_weather_forecast.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/services/risk_calculator.dart';

// ========== 基盤プロバイダー ==========

/// SharedPreferencesプロバイダー（要override）
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferencesは初期化時にoverrideしてください');
});

/// ローカルストレージプロバイダー
final localStorageProvider = Provider<LocalStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorage(prefs);
});

/// APIクライアントプロバイダー
final noaaApiClientProvider = Provider<NoaaApiClient>((ref) {
  final client = NoaaApiClient();
  ref.onDispose(() => client.dispose());
  return client;
});

// ========== リポジトリプロバイダー ==========

/// NOAAリポジトリプロバイダー
final noaaRepositoryProvider = Provider<NoaaRepository>((ref) {
  final apiClient = ref.watch(noaaApiClientProvider);
  final localStorage = ref.watch(localStorageProvider);
  final repo = NoaaRepository(apiClient: apiClient, localStorage: localStorage);
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// 地点リポジトリプロバイダー
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return LocationRepository(localStorage: localStorage);
});

// ========== サービスプロバイダー ==========

/// リスク計算サービスプロバイダー
final riskCalculatorProvider = Provider<RiskCalculator>((ref) {
  return const RiskCalculator();
});

// ========== 状態プロバイダー ==========

/// 宇宙天気データプロバイダー
final spaceWeatherDataProvider = FutureProvider.autoDispose<SpaceWeatherData>((
  ref,
) async {
  final repository = ref.watch(noaaRepositoryProvider);
  return await repository.getSpaceWeatherData();
});

/// 宇宙天気データを強制リフレッシュ
final refreshSpaceWeatherProvider = FutureProvider.family
    .autoDispose<SpaceWeatherData, bool>((ref, forceRefresh) async {
      final repository = ref.watch(noaaRepositoryProvider);
      return await repository.getSpaceWeatherData(forceRefresh: forceRefresh);
    });

/// 登録済み地点リストプロバイダー
final locationsProvider =
    StateNotifierProvider<LocationsNotifier, List<UserLocation>>((ref) {
      final repository = ref.watch(locationRepositoryProvider);
      return LocationsNotifier(repository);
    });

class LocationsNotifier extends StateNotifier<List<UserLocation>> {
  final LocationRepository _repository;

  LocationsNotifier(this._repository) : super(_repository.getLocations());

  Future<bool> addLocation(UserLocation location) async {
    final result = await _repository.addLocation(location);
    if (result) {
      state = _repository.getLocations();
    }
    return result;
  }

  Future<bool> removeLocation(String id) async {
    final result = await _repository.removeLocation(id);
    if (result) {
      state = _repository.getLocations();
    }
    return result;
  }

  void refresh() {
    state = _repository.getLocations();
  }
}

/// 選択中の地点プロバイダー
final selectedLocationProvider =
    StateNotifierProvider<SelectedLocationNotifier, UserLocation?>((ref) {
      final repository = ref.watch(locationRepositoryProvider);
      return SelectedLocationNotifier(repository);
    });

class SelectedLocationNotifier extends StateNotifier<UserLocation?> {
  final LocationRepository _repository;

  SelectedLocationNotifier(this._repository)
    : super(_repository.getSelectedLocation());

  Future<void> selectLocation(String locationId) async {
    await _repository.selectLocation(locationId);
    state = _repository.getSelectedLocation();
  }

  void refresh() {
    state = _repository.getSelectedLocation();
  }
}

/// 表示モード（Light/Core）プロバイダー
final displayModeProvider = StateNotifierProvider<DisplayModeNotifier, bool>((
  ref,
) {
  final localStorage = ref.watch(localStorageProvider);
  return DisplayModeNotifier(localStorage);
});

class DisplayModeNotifier extends StateNotifier<bool> {
  final LocalStorage _localStorage;

  DisplayModeNotifier(this._localStorage) : super(_localStorage.isCoreMode());

  Future<void> toggle() async {
    await _localStorage.setCoreMode(!state);
    state = !state;
  }

  Future<void> setMode(bool isCore) async {
    await _localStorage.setCoreMode(isCore);
    state = isCore;
  }
}

/// 全リスク計算結果プロバイダー
final allRisksProvider = Provider.autoDispose<AsyncValue<AllRiskResults>>((
  ref,
) {
  final weatherAsync = ref.watch(spaceWeatherDataProvider);
  final location = ref.watch(selectedLocationProvider);
  final calculator = ref.watch(riskCalculatorProvider);

  return weatherAsync.when(
    data: (weatherData) {
      if (location == null) {
        return const AsyncValue.loading();
      }
      final results = calculator.calculateAllRisks(
        weatherData: weatherData,
        location: location,
      );
      return AsyncValue.data(results);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// 特定地点のリスク計算結果プロバイダー
final allRisksFamilyProvider = FutureProvider.family
    .autoDispose<AllRiskResults, UserLocation>((ref, location) async {
      final weatherData = await ref.watch(spaceWeatherDataProvider.future);
      final calculator = ref.watch(riskCalculatorProvider);

      return calculator.calculateAllRisks(
        weatherData: weatherData,
        location: location,
      );
    });

/// テーマモードプロバイダー（true: ダーク, false: ライト）
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return ThemeNotifier(localStorage);
});

class ThemeNotifier extends StateNotifier<bool> {
  final LocalStorage _localStorage;

  ThemeNotifier(this._localStorage) : super(_localStorage.isDarkMode());

  Future<void> toggle() async {
    await _localStorage.setDarkMode(!state);
    state = !state;
  }

  Future<void> setDarkMode(bool isDark) async {
    await _localStorage.setDarkMode(isDark);
    state = isDark;
  }
}

/// 通知設定プロバイダー
final notificationSettingsProvider =
    StateNotifierProvider<
      NotificationSettingsNotifier,
      NotificationSettingsState
    >((ref) {
      final localStorage = ref.watch(localStorageProvider);
      return NotificationSettingsNotifier(localStorage);
    });

class NotificationSettingsState {
  final bool enabled;
  final int threshold;
  final List<String> locationIds;

  const NotificationSettingsState({
    this.enabled = false,
    this.threshold = 3,
    this.locationIds = const [],
  });

  NotificationSettingsState copyWith({
    bool? enabled,
    int? threshold,
    List<String>? locationIds,
  }) {
    return NotificationSettingsState(
      enabled: enabled ?? this.enabled,
      threshold: threshold ?? this.threshold,
      locationIds: locationIds ?? this.locationIds,
    );
  }
}

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  final LocalStorage _localStorage;

  NotificationSettingsNotifier(this._localStorage)
    : super(
        NotificationSettingsState(
          enabled: _localStorage.isNotificationEnabled(),
          threshold: _localStorage.getNotificationThreshold(),
          locationIds: _localStorage.getNotificationLocationIds(),
        ),
      );

  Future<void> setEnabled(bool enabled) async {
    await _localStorage.setNotificationEnabled(enabled);
    state = state.copyWith(enabled: enabled);
  }

  Future<void> setThreshold(int threshold) async {
    await _localStorage.setNotificationThreshold(threshold);
    state = state.copyWith(threshold: threshold);
  }

  Future<void> setLocationIds(List<String> ids) async {
    await _localStorage.setNotificationLocationIds(ids);
    state = state.copyWith(locationIds: ids);
  }

  Future<void> toggleLocation(String locationId) async {
    final newIds = List<String>.from(state.locationIds);
    if (newIds.contains(locationId)) {
      newIds.remove(locationId);
    } else {
      newIds.add(locationId);
    }
    await setLocationIds(newIds);
  }
}

/// 1週間宇宙天気予報プロバイダー
/// NOAAの実データを基に生成
final weeklyForecastProvider = FutureProvider.autoDispose<WeeklyForecast>((
  ref,
) async {
  // 現在の宇宙天気データを取得
  final weatherData = await ref.watch(spaceWeatherDataProvider.future);

  final now = DateTime.now();
  final forecasts = <SpaceWeatherForecast>[];

  // NOAA scalesから現在の状態を取得
  final scales = weatherData.scales;
  final kpIndex = weatherData.kpIndex;

  for (int i = 0; i < 7; i++) {
    final date = now.add(Duration(days: i));
    final isPrediction = i >= 3; // 3日目以降は予測

    // 基本レベルはNOAAスケールから（0-5 -> 1-5に変換）
    int geoLevel = (scales.gScale + 1).clamp(1, 5);
    int solarLevel = (scales.sScale + 1).clamp(1, 5);
    int radioLevel = (scales.rScale + 1).clamp(1, 5);

    // 予測日の場合は不確実性を考慮して中央値に近づける
    if (isPrediction) {
      geoLevel = ((geoLevel + 2) / 2).round().clamp(1, 5);
      solarLevel = ((solarLevel + 2) / 2).round().clamp(1, 5);
      radioLevel = ((radioLevel + 2) / 2).round().clamp(1, 5);
    }

    // 説明文を生成
    String description;
    if (geoLevel <= 2) {
      description = '安定';
    } else if (geoLevel == 3) {
      description = '注意';
    } else {
      description = '警戒';
    }

    // サマリーを生成
    String summary;
    if (i == 0) {
      summary =
          'Kp指数: ${kpIndex.kpValue.toStringAsFixed(1)}。${_getKpDescription(kpIndex.kpValue)}';
    } else if (!isPrediction) {
      summary = '地磁気活動は${description}レベルが予想されます。';
    } else {
      summary = '予測精度は低下しますが、${description}レベルの傾向です。';
    }

    forecasts.add(
      SpaceWeatherForecast(
        date: date,
        geomagneticLevel: geoLevel,
        solarRadiationLevel: solarLevel,
        radioBlackoutLevel: radioLevel,
        geomagneticDescription: description,
        summary: summary,
        isPrediction: isPrediction,
      ),
    );
  }

  return WeeklyForecast(forecasts: forecasts, fetchedAt: now);
});

String _getKpDescription(double kp) {
  if (kp < 2) return '地磁気活動は静穏です。';
  if (kp < 4) return '軽微な地磁気活動が観測されています。';
  if (kp < 6) return '中程度の地磁気活動が観測されています。';
  if (kp < 8) return '活発な地磁気嵐が発生しています。';
  return '非常に強い地磁気嵐が発生しています。';
}
