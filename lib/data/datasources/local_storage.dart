import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_location.dart';

/// ローカルストレージ管理クラス
class LocalStorage {
  static const String _locationsKey = 'user_locations';
  static const String _selectedLocationIdKey = 'selected_location_id';
  static const String _displayModeKey = 'display_mode';
  static const String _cachedWeatherDataKey = 'cached_weather_data';
  static const String _cachedAtKey = 'cached_at';
  static const String _themeKey = 'theme_is_dark';
  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _notificationThresholdKey = 'notification_threshold';
  static const String _notificationLocationsKey = 'notification_locations';

  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  // ========== 地点管理 ==========

  /// 保存済み地点リストを取得
  List<UserLocation> getLocations() {
    final jsonString = _prefs.getString(_locationsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => UserLocation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 地点を追加
  Future<bool> addLocation(UserLocation location) async {
    final locations = getLocations();

    // 重複チェック（同じ名前・座標は追加しない）
    final exists = locations.any(
      (loc) =>
          loc.name == location.name ||
          (loc.latitude == location.latitude &&
              loc.longitude == location.longitude),
    );
    if (exists) return false;

    locations.add(location);
    return await _saveLocations(locations);
  }

  /// 地点を削除
  Future<bool> removeLocation(String locationId) async {
    final locations = getLocations();
    locations.removeWhere((loc) => loc.id == locationId);
    return await _saveLocations(locations);
  }

  /// 地点リストを保存
  Future<bool> _saveLocations(List<UserLocation> locations) async {
    final jsonList = locations.map((loc) => loc.toJson()).toList();
    return await _prefs.setString(_locationsKey, jsonEncode(jsonList));
  }

  /// 地点の並び順を更新
  Future<bool> reorderLocations(List<UserLocation> locations) async {
    return await _saveLocations(locations);
  }

  // ========== 選択中の地点 ==========

  /// 選択中の地点IDを取得
  String? getSelectedLocationId() {
    return _prefs.getString(_selectedLocationIdKey);
  }

  /// 選択中の地点IDを保存
  Future<bool> setSelectedLocationId(String id) async {
    return await _prefs.setString(_selectedLocationIdKey, id);
  }

  // ========== 表示モード ==========

  /// 表示モードを取得（true: Core, false: Light）
  bool isCoreMode() {
    return _prefs.getBool(_displayModeKey) ?? false;
  }

  /// 表示モードを保存
  Future<bool> setCoreMode(bool isCore) async {
    return await _prefs.setBool(_displayModeKey, isCore);
  }

  // ========== キャッシュ ==========

  /// キャッシュデータを取得
  String? getCachedWeatherData() {
    return _prefs.getString(_cachedWeatherDataKey);
  }

  /// キャッシュ時刻を取得
  DateTime? getCachedAt() {
    final timestamp = _prefs.getInt(_cachedAtKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// キャッシュを保存
  Future<bool> cacheWeatherData(String jsonData) async {
    await _prefs.setInt(_cachedAtKey, DateTime.now().millisecondsSinceEpoch);
    return await _prefs.setString(_cachedWeatherDataKey, jsonData);
  }

  /// キャッシュが有効かどうか
  bool isCacheValid(Duration expiry) {
    final cachedAt = getCachedAt();
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt) < expiry;
  }

  /// 全データをクリア
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  // ========== テーマ設定 ==========

  /// ダークモードかどうかを取得（デフォルト: true）
  bool isDarkMode() {
    return _prefs.getBool(_themeKey) ?? true;
  }

  /// テーマモードを保存
  Future<bool> setDarkMode(bool isDark) async {
    return await _prefs.setBool(_themeKey, isDark);
  }

  // ========== 通知設定 ==========

  /// 通知が有効かどうかを取得
  bool isNotificationEnabled() {
    return _prefs.getBool(_notificationEnabledKey) ?? false;
  }

  /// 通知の有効/無効を保存
  Future<bool> setNotificationEnabled(bool enabled) async {
    return await _prefs.setBool(_notificationEnabledKey, enabled);
  }

  /// 通知閾値を取得（デフォルト: 3）
  int getNotificationThreshold() {
    return _prefs.getInt(_notificationThresholdKey) ?? 3;
  }

  /// 通知閾値を保存
  Future<bool> setNotificationThreshold(int threshold) async {
    return await _prefs.setInt(_notificationThresholdKey, threshold);
  }

  /// 通知対象の地点IDリストを取得
  List<String> getNotificationLocationIds() {
    final jsonString = _prefs.getString(_notificationLocationsKey);
    if (jsonString == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// 通知対象の地点IDリストを保存
  Future<bool> setNotificationLocationIds(List<String> ids) async {
    return await _prefs.setString(_notificationLocationsKey, jsonEncode(ids));
  }
}
