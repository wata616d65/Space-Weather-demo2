import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/user_location.dart';
import '../datasources/local_storage.dart';

/// 地点管理リポジトリ
class LocationRepository {
  final LocalStorage _localStorage;

  LocationRepository({required LocalStorage localStorage})
      : _localStorage = localStorage;

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
        locationName = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? '現在地';
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
  Future<List<UserLocation>> searchByName(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final locations = await geo.locationFromAddress(query);
      if (locations.isEmpty) return [];

      // 各結果を逆ジオコーディングして正式名称を取得
      final results = <UserLocation>[];
      for (final loc in locations.take(5)) {
        String name = query;
        try {
          final placemarks = await geo.placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            name = place.locality ?? place.subAdministrativeArea ?? query;
          }
        } catch (_) {}

        results.add(UserLocation.create(
          name: name,
          latitude: loc.latitude,
          longitude: loc.longitude,
        ));
      }

      return results;
    } catch (e) {
      throw LocationException('場所が見つかりませんでした: $query');
    }
  }
}

/// 位置情報例外
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}
