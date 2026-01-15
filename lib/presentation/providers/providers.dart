import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local_storage.dart';
import '../../data/datasources/noaa_api_client.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/noaa_repository.dart';
import '../../domain/entities/noaa_data.dart';
import '../../domain/entities/risk_result.dart';
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
final spaceWeatherDataProvider =
    FutureProvider.autoDispose<SpaceWeatherData>((ref) async {
  final repository = ref.watch(noaaRepositoryProvider);
  return await repository.getSpaceWeatherData();
});

/// 宇宙天気データを強制リフレッシュ
final refreshSpaceWeatherProvider =
    FutureProvider.family.autoDispose<SpaceWeatherData, bool>(
        (ref, forceRefresh) async {
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
final displayModeProvider =
    StateNotifierProvider<DisplayModeNotifier, bool>((ref) {
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
final allRisksProvider = Provider.autoDispose<AsyncValue<AllRiskResults>>((ref) {
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
