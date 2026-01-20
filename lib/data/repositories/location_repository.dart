import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/user_location.dart';
import '../datasources/local_storage.dart';
import '../datasources/geoapify_service.dart';

/// 日本の主要都市（47都道府県庁所在地 + 主要都市）
const Map<String, Map<String, double>> _japaneseCities = {
  // 北海道・東北
  '札幌': {'lat': 43.0618, 'lon': 141.3545},
  '青森': {'lat': 40.8246, 'lon': 140.7400},
  '盛岡': {'lat': 39.7036, 'lon': 141.1527},
  '仙台': {'lat': 38.2682, 'lon': 140.8694},
  '秋田': {'lat': 39.7186, 'lon': 140.1024},
  '山形': {'lat': 38.2405, 'lon': 140.3633},
  '福島': {'lat': 37.7500, 'lon': 140.4678},
  // 関東
  '東京': {'lat': 35.6762, 'lon': 139.6503},
  '横浜': {'lat': 35.4437, 'lon': 139.6380},
  '千葉': {'lat': 35.6050, 'lon': 140.1233},
  'さいたま': {'lat': 35.8617, 'lon': 139.6455},
  '埼玉': {'lat': 35.8617, 'lon': 139.6455},
  '水戸': {'lat': 36.3418, 'lon': 140.4468},
  '宇都宮': {'lat': 36.5551, 'lon': 139.8829},
  '前橋': {'lat': 36.3911, 'lon': 139.0608},
  // 中部
  '新潟': {'lat': 37.9024, 'lon': 139.0234},
  '富山': {'lat': 36.6953, 'lon': 137.2114},
  '金沢': {'lat': 36.5944, 'lon': 136.6256},
  '福井': {'lat': 36.0652, 'lon': 136.2219},
  '甲府': {'lat': 35.6640, 'lon': 138.5684},
  '長野': {'lat': 36.6513, 'lon': 138.1810},
  '岐阜': {'lat': 35.3912, 'lon': 136.7223},
  '静岡': {'lat': 34.9769, 'lon': 138.3831},
  '名古屋': {'lat': 35.1815, 'lon': 136.9066},
  // 近畿
  '津': {'lat': 34.7303, 'lon': 136.5086},
  '大津': {'lat': 35.0045, 'lon': 135.8686},
  '京都': {'lat': 35.0116, 'lon': 135.7681},
  '大阪': {'lat': 34.6937, 'lon': 135.5023},
  '神戸': {'lat': 34.6901, 'lon': 135.1956},
  '奈良': {'lat': 34.6851, 'lon': 135.8048},
  '和歌山': {'lat': 34.2261, 'lon': 135.1675},
  // 中国
  '鳥取': {'lat': 35.5039, 'lon': 134.2378},
  '松江': {'lat': 35.4723, 'lon': 133.0505},
  '岡山': {'lat': 34.6551, 'lon': 133.9195},
  '広島': {'lat': 34.3853, 'lon': 132.4553},
  '山口': {'lat': 34.1861, 'lon': 131.4705},
  // 四国
  '徳島': {'lat': 34.0658, 'lon': 134.5593},
  '高松': {'lat': 34.3401, 'lon': 134.0434},
  '松山': {'lat': 33.8416, 'lon': 132.7657},
  '高知': {'lat': 33.5597, 'lon': 133.5311},
  // 九州・沖縄
  '福岡': {'lat': 33.5902, 'lon': 130.4017},
  '佐賀': {'lat': 33.2494, 'lon': 130.2988},
  '長崎': {'lat': 32.7503, 'lon': 129.8779},
  '熊本': {'lat': 32.7898, 'lon': 130.7417},
  '大分': {'lat': 33.2382, 'lon': 131.6126},
  '宮崎': {'lat': 31.9111, 'lon': 131.4239},
  '鹿児島': {'lat': 31.5602, 'lon': 130.5581},
  '那覇': {'lat': 26.2124, 'lon': 127.6809},
  '沖縄': {'lat': 26.2124, 'lon': 127.6809},
  // 主要都市
  '北海道': {'lat': 43.0618, 'lon': 141.3545},
  '川崎': {'lat': 35.5309, 'lon': 139.7030},
  '相模原': {'lat': 35.5714, 'lon': 139.3736},
  '堺': {'lat': 34.5733, 'lon': 135.4830},
  '浜松': {'lat': 34.7108, 'lon': 137.7261},
};

/// 地点管理リポジトリ
class LocationRepository {
  final LocalStorage _localStorage;
  final GeoapifyService _geoapifyService;

  /// 言語設定（デフォルトは日本語）
  String _languageCode = 'ja';

  LocationRepository({required LocalStorage localStorage})
    : _localStorage = localStorage,
      _geoapifyService = GeoapifyService();

  /// 言語コードを設定
  void setLanguage(String languageCode) {
    _languageCode = languageCode;
  }

  // ========== 地点CRUD ==========

  /// 保存済み地点一覧を取得
  List<UserLocation> getLocations() {
    return _localStorage.getLocations();
  }

  /// 地点を追加
  Future<bool> addLocation(UserLocation location) async {
    return await _localStorage.addLocation(location);
  }

  /// 地点を削除
  Future<bool> removeLocation(String locationId) async {
    // 選択中の地点を削除した場合は選択を解除
    final selectedId = _localStorage.getSelectedLocationId();
    if (selectedId == locationId) {
      final locations = getLocations();
      if (locations.length > 1) {
        // 別の地点を選択
        final other = locations.firstWhere((loc) => loc.id != locationId);
        await _localStorage.setSelectedLocationId(other.id);
      }
    }
    return await _localStorage.removeLocation(locationId);
  }

  /// 地点の並び順を更新
  Future<bool> reorderLocations(List<UserLocation> locations) async {
    return await _localStorage.reorderLocations(locations);
  }

  // ========== 選択中の地点 ==========

  /// 選択中の地点を取得
  UserLocation? getSelectedLocation() {
    final id = _localStorage.getSelectedLocationId();
    if (id == null) {
      // デフォルトは最初の地点
      final locations = getLocations();
      return locations.isNotEmpty ? locations.first : null;
    }

    final locations = getLocations();
    try {
      return locations.firstWhere((loc) => loc.id == id);
    } catch (_) {
      return locations.isNotEmpty ? locations.first : null;
    }
  }

  /// 地点を選択
  Future<bool> selectLocation(String locationId) async {
    return await _localStorage.setSelectedLocationId(locationId);
  }

  // ========== 位置情報サービス ==========

  /// 現在地を取得
  Future<UserLocation> getCurrentLocation() async {
    // 位置情報権限をチェック
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('位置情報サービスが無効です');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('位置情報の権限が拒否されました');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException('位置情報の権限が永久に拒否されています。設定から許可してください。');
    }

    // 現在位置を取得
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    // 逆ジオコーディングで地名を取得
    String locationName = '現在地';
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        locationName =
            place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            '現在地';
      }
    } catch (_) {
      // 逆ジオコーディングに失敗しても続行
    }

    return UserLocation.create(
      name: locationName,
      latitude: position.latitude,
      longitude: position.longitude,
      isCurrentLocation: true,
    );
  }

  /// 都市名から座標を検索
  /// 多言語対応、検索優先順位:
  /// 1. 日本都市ローカルDB（高速、オフライン）
  /// 2. Geoapify API（多言語対応、グローバル）
  /// 3. 標準geocoding（フォールバック）
  Future<List<UserLocation>> searchByName(String query) async {
    if (query.trim().isEmpty) return [];

    final results = <UserLocation>[];

    // 1. まず日本の都市データから検索（部分一致）
    // 日本語検索の場合のみ
    if (_isJapaneseText(query)) {
      final matchingCities = _searchJapaneseCities(query);
      for (final entry in matchingCities) {
        results.add(
          UserLocation.create(
            name: entry.key,
            latitude: entry.value['lat']!,
            longitude: entry.value['lon']!,
          ),
        );
      }

      // 日本都市で見つかった場合はそれを返す
      if (results.isNotEmpty) {
        return results;
      }
    }

    // 2. Geoapify APIで検索（多言語対応）
    if (_geoapifyService.isConfigured) {
      try {
        final geoapifyResults = await _geoapifyService.autocomplete(
          query: query,
          lang: _languageCode,
          limit: 5,
        );

        if (geoapifyResults.isNotEmpty) {
          return geoapifyResults;
        }
      } catch (_) {
        // Geoapifyが失敗した場合はフォールバックに進む
      }
    }

    // 3. 見つからない場合は標準geocodingで検索
    try {
      // 日本語検索の場合は「Japan」を付加して精度向上
      String searchQuery = query;
      if (_isJapaneseText(query)) {
        searchQuery = '$query, Japan';
      }

      final locations = await geo.locationFromAddress(searchQuery);
      if (locations.isEmpty) return [];

      // 各結果を逆ジオコーディングして正式名称を取得
      for (final loc in locations.take(5)) {
        String name = query;
        try {
          final placemarks = await geo.placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            // 日本語の地名を優先的に取得
            name = _getJapanesePlaceName(place, query);
          }
        } catch (_) {}

        results.add(
          UserLocation.create(
            name: name,
            latitude: loc.latitude,
            longitude: loc.longitude,
          ),
        );
      }

      return results;
    } catch (e) {
      throw LocationException('場所が見つかりませんでした: $query');
    }
  }

  /// 日本の都市データから部分一致検索
  List<MapEntry<String, Map<String, double>>> _searchJapaneseCities(
    String query,
  ) {
    final normalizedQuery = query.trim();
    final results = <MapEntry<String, Map<String, double>>>[];

    for (final entry in _japaneseCities.entries) {
      if (entry.key.contains(normalizedQuery) ||
          normalizedQuery.contains(entry.key)) {
        results.add(entry);
      }
    }

    return results.take(5).toList();
  }

  /// 日本語テキストかどうかを判定
  bool _isJapaneseText(String text) {
    // ひらがな、カタカナ、漢字のいずれかを含むか
    final japaneseRegex = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    return japaneseRegex.hasMatch(text);
  }

  /// 地名を日本語優先で取得
  String _getJapanesePlaceName(geo.Placemark place, String fallback) {
    // 優先順位: locality > subAdministrativeArea > administrativeArea
    final locality = place.locality;
    final subAdmin = place.subAdministrativeArea;
    final admin = place.administrativeArea;

    // 日本の場合は市区町村名を返す
    if (locality != null && locality.isNotEmpty) {
      return locality;
    }
    if (subAdmin != null && subAdmin.isNotEmpty) {
      return subAdmin;
    }
    if (admin != null && admin.isNotEmpty) {
      return admin;
    }

    return fallback;
  }
}

/// 位置情報例外
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}
