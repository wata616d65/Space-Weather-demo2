import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../domain/entities/noaa_data.dart';

/// NOAA API クライアント
/// Supabase Edge Function経由でNOAAデータを取得
class NoaaApiClient {
  final http.Client _httpClient;

  NoaaApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Edge Functionからデータを取得
  Future<SpaceWeatherData> fetchSpaceWeatherData() async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse(ApiConstants.fetchNoaaDataEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${ApiConstants.supabaseAnonKey}',
            },
          )
          .timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      } else {
        throw NoaaApiException(
          'APIエラー: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NoaaApiException) rethrow;
      throw NoaaApiException('通信エラー: $e');
    }
  }

  SpaceWeatherData _parseResponse(String body) {
    try {
      final json = jsonDecode(body);

      // Edge Functionのレスポンス形式に応じてパース
      // 期待形式: { "scales": {...}, "kpIndex": {...} }
      // または直接NOAAデータが返る場合

      NoaaScales scales;
      KpIndex kpIndex;

      // scalesのパース
      if (json.containsKey('scales')) {
        scales = NoaaScales.fromJson(json['scales'] as Map<String, dynamic>);
      } else if (json.containsKey('-1')) {
        // noaa-scales.jsonの形式（-1キーに現在のスケール）
        final scaleData = json['-1'] as Map<String, dynamic>?;
        if (scaleData != null) {
          scales = NoaaScales.fromJson(scaleData);
        } else {
          scales = _defaultScales();
        }
      } else {
        scales = NoaaScales.fromJson(json);
      }

      // kpIndexのパース
      if (json.containsKey('kpIndex')) {
        kpIndex = KpIndex.fromJson(json['kpIndex'] as Map<String, dynamic>);
      } else if (json.containsKey('kp_index')) {
        kpIndex = KpIndex(
          kpValue: double.tryParse(json['kp_index'].toString()) ?? 0.0,
          timestamp: DateTime.now(),
        );
      } else if (json is List && json.isNotEmpty) {
        // planetary-k-index.jsonは配列形式
        final latest = json.last as Map<String, dynamic>;
        kpIndex = KpIndex.fromJson(latest);
      } else {
        kpIndex = _defaultKpIndex();
      }

      return SpaceWeatherData(
        scales: scales,
        kpIndex: kpIndex,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      throw NoaaApiException('データパースエラー: $e');
    }
  }

  NoaaScales _defaultScales() {
    return NoaaScales(
      gScale: 0,
      sScale: 0,
      rScale: 0,
      timestamp: DateTime.now(),
    );
  }

  KpIndex _defaultKpIndex() {
    return KpIndex(kpValue: 0.0, timestamp: DateTime.now());
  }

  void dispose() {
    _httpClient.close();
  }
}

/// NOAA API例外
class NoaaApiException implements Exception {
  final String message;
  final int? statusCode;

  NoaaApiException(this.message, {this.statusCode});

  @override
  String toString() => 'NoaaApiException: $message';
}
