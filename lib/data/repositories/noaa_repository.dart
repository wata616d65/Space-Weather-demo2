import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/noaa_data.dart';
import '../datasources/local_storage.dart';
import '../datasources/noaa_api_client.dart';

/// 宇宙天気データリポジトリ
/// APIからのデータ取得とキャッシュ管理を担当
class NoaaRepository {
  final NoaaApiClient _apiClient;
  final LocalStorage _localStorage;

  // メモリキャッシュ
  SpaceWeatherData? _cachedData;
  DateTime? _lastFetchTime;

  NoaaRepository({
    required NoaaApiClient apiClient,
    required LocalStorage localStorage,
  })  : _apiClient = apiClient,
        _localStorage = localStorage;

  /// 宇宙天気データを取得
  /// キャッシュが有効な場合はキャッシュから返す
  Future<SpaceWeatherData> getSpaceWeatherData({bool forceRefresh = false}) async {
    // メモリキャッシュをチェック
    if (!forceRefresh && _cachedData != null && _lastFetchTime != null) {
      final elapsed = DateTime.now().difference(_lastFetchTime!);
      if (elapsed < ApiConstants.cacheExpiry) {
        return _cachedData!;
      }
    }

    try {
      // APIからデータを取得
      final data = await _apiClient.fetchSpaceWeatherData();
      _cachedData = data;
      _lastFetchTime = DateTime.now();

      // ローカルストレージにもキャッシュ
      await _cacheToStorage(data);

      return data;
    } catch (e) {
      // オフライン時はローカルキャッシュから復元を試みる
      final cachedData = await _loadFromCache();
      if (cachedData != null) {
        _cachedData = cachedData;
        return cachedData;
      }

      // キャッシュもなければデフォルトデータを返す
      return SpaceWeatherData.empty();
    }
  }

  /// 最終更新時刻を取得
  DateTime? get lastUpdated => _lastFetchTime ?? _localStorage.getCachedAt();

  /// キャッシュが有効かどうか
  bool get hasFreshData {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < ApiConstants.cacheExpiry;
  }

  /// ローカルストレージにキャッシュ
  Future<void> _cacheToStorage(SpaceWeatherData data) async {
    final json = {
      'scales': data.scales.toJson(),
      'kpIndex': data.kpIndex.toJson(),
      'fetchedAt': data.fetchedAt.toIso8601String(),
    };
    await _localStorage.cacheWeatherData(jsonEncode(json));
  }

  /// ローカルストレージからキャッシュを読み込み
  Future<SpaceWeatherData?> _loadFromCache() async {
    final jsonString = _localStorage.getCachedWeatherData();
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SpaceWeatherData(
        scales: NoaaScales.fromJson(json['scales'] as Map<String, dynamic>),
        kpIndex: KpIndex.fromJson(json['kpIndex'] as Map<String, dynamic>),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );
    } catch (e) {
      return null;
    }
  }

  /// キャッシュをクリア
  void clearCache() {
    _cachedData = null;
    _lastFetchTime = null;
  }

  void dispose() {
    _apiClient.dispose();
  }
}
