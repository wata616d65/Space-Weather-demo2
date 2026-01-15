import 'package:uuid/uuid.dart';

/// ユーザーが登録する地点情報
class UserLocation {
  final String id;
  final String name; // 例: "東京", "札幌"
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final bool isCurrentLocation; // 現在地かどうか

  const UserLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.isCurrentLocation = false,
  });

  /// 新しい地点を作成
  factory UserLocation.create({
    required String name,
    required double latitude,
    required double longitude,
    bool isCurrentLocation = false,
  }) {
    return UserLocation(
      id: const Uuid().v4(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      isCurrentLocation: isCurrentLocation,
    );
  }

  /// JSONからの復元
  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCurrentLocation: json['isCurrentLocation'] as bool? ?? false,
    );
  }

  /// JSONへ変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'isCurrentLocation': isCurrentLocation,
    };
  }

  /// 緯度の絶対値を取得（計算用）
  double get absoluteLatitude => latitude.abs();

  /// 緯度帯の分類
  LatitudeZone get latitudeZone {
    final absLat = absoluteLatitude;
    if (absLat < 30) return LatitudeZone.low;
    if (absLat <= 50) return LatitudeZone.mid;
    return LatitudeZone.high;
  }

  /// 座標の表示用文字列
  String get coordinateString {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(2)}°$latDir, '
        '${longitude.abs().toStringAsFixed(2)}°$lonDir';
  }

  UserLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    bool? isCurrentLocation,
  }) {
    return UserLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLocation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserLocation($name: $coordinateString)';
}

/// 緯度帯の分類
enum LatitudeZone {
  low, // 低緯度 (|lat| < 30)
  mid, // 中緯度 (30 <= |lat| <= 50)
  high, // 高緯度 (|lat| > 50)
}
