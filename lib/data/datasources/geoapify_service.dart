import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/user_location.dart';

/// Geoapify API サービス
/// 無料枠: 月30万リクエスト、商用利用可能
/// https://www.geoapify.com/
class GeoapifyService {
  // 注意: 本番環境ではサーバーサイドに移行してください
  // Geoapify 無料APIキー（月30万リクエスト）
  // https://myprojects.geoapify.com/ で取得
  static const String _apiKey = '48c39ccfc1df4f5fbe2966b9a5e0c56f';

  static const String _baseUrl = 'https://api.geoapify.com/v1/geocode';

  /// オートコンプリート検索
  /// [query] 検索クエリ
  /// [lang] 言語コード（ja, en, zh など）
  /// [limit] 結果の最大数
  Future<List<UserLocation>> autocomplete({
    required String query,
    String lang = 'ja',
    int limit = 5,
  }) async {
    if (query.trim().length < 2) return [];

    // API キーが設定されていない場合は空を返す
    if (_apiKey == 'YOUR_GEOAPIFY_API_KEY') {
      return [];
    }

    try {
      final uri = Uri.parse('$_baseUrl/autocomplete').replace(
        queryParameters: {
          'text': query,
          'lang': lang,
          'limit': limit.toString(),
          'format': 'json',
          'apiKey': _apiKey,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final results = <UserLocation>[];

      for (final result in data['results'] ?? []) {
        final lat = result['lat'] as double?;
        final lon = result['lon'] as double?;

        if (lat == null || lon == null) continue;

        // 表示名を構築（ローカライズされた名前を優先）
        String name = _buildDisplayName(result, lang);

        results.add(
          UserLocation.create(name: name, latitude: lat, longitude: lon),
        );
      }

      return results;
    } catch (e) {
      // エラー時は空リストを返す（フォールバック検索に任せる）
      return [];
    }
  }

  /// 住所から座標を検索（フォワードジオコーディング）
  Future<List<UserLocation>> search({
    required String query,
    String lang = 'ja',
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) return [];

    if (_apiKey == 'YOUR_GEOAPIFY_API_KEY') {
      return [];
    }

    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'text': query,
          'lang': lang,
          'limit': limit.toString(),
          'format': 'json',
          'apiKey': _apiKey,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final results = <UserLocation>[];

      for (final result in data['results'] ?? []) {
        final lat = result['lat'] as double?;
        final lon = result['lon'] as double?;

        if (lat == null || lon == null) continue;

        String name = _buildDisplayName(result, lang);

        results.add(
          UserLocation.create(name: name, latitude: lat, longitude: lon),
        );
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// 座標から住所を検索（リバースジオコーディング）
  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
    String lang = 'ja',
  }) async {
    if (_apiKey == 'YOUR_GEOAPIFY_API_KEY') {
      return null;
    }

    try {
      final uri = Uri.parse('$_baseUrl/reverse').replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'lang': lang,
          'format': 'json',
          'apiKey': _apiKey,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      final results = data['results'] as List?;

      if (results == null || results.isEmpty) {
        return null;
      }

      return _buildDisplayName(results.first, lang);
    } catch (e) {
      return null;
    }
  }

  /// 表示名を構築
  String _buildDisplayName(Map<String, dynamic> result, String lang) {
    // 日本語の場合は日本式の表示
    if (lang == 'ja') {
      final city = result['city'] ?? result['town'] ?? result['village'];
      final state = result['state'];
      final country = result['country'];

      if (city != null) {
        if (country == '日本' || country == 'Japan') {
          // 日本の場合: 市区町村名のみ
          return city as String;
        }
        // 海外の場合: 都市名, 国名
        return '$city, $country';
      }

      if (state != null) {
        return '$state, $country';
      }

      return result['formatted'] ?? result['name'] ?? '不明な場所';
    }

    // その他の言語: formatted または city, country
    final formatted = result['formatted'] as String?;
    if (formatted != null) {
      // 長すぎる場合は短縮
      if (formatted.length > 40) {
        final city = result['city'] ?? result['town'];
        final country = result['country'];
        if (city != null && country != null) {
          return '$city, $country';
        }
      }
      return formatted;
    }

    return result['name'] ?? 'Unknown location';
  }

  /// APIキーが設定されているかチェック
  bool get isConfigured => _apiKey != 'YOUR_GEOAPIFY_API_KEY';
}
