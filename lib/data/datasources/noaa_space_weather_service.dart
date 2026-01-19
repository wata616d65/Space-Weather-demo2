import 'dart:convert';
import 'package:http/http.dart' as http;

/// NOAA Space Weather Prediction Center API サービス
/// 商用利用可能（出典表示必須）
/// https://services.swpc.noaa.gov/
class NoaaSpaceWeatherService {
  static const String _baseUrl = 'https://services.swpc.noaa.gov';
  static const Duration _timeout = Duration(seconds: 15);

  // ========== Kp指数（地磁気活動指数） ==========

  /// 過去3日間のKp指数を取得
  /// 出典: NOAA Space Weather Prediction Center
  Future<List<KpIndexData>> getKpIndex() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/products/noaa-planetary-k-index.json'))
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      final results = <KpIndexData>[];

      // 最初の行はヘッダなのでスキップ
      for (int i = 1; i < data.length && i <= 24; i++) {
        final row = data[i];
        if (row is List && row.length >= 2) {
          final timestamp = DateTime.tryParse(row[0].toString());
          final kp = double.tryParse(row[1].toString());

          if (timestamp != null && kp != null) {
            results.add(KpIndexData(timestamp: timestamp, kpValue: kp));
          }
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  // ========== 太陽風データ ==========

  /// 太陽風プラズマデータ（速度、密度）を取得
  /// 出典: NOAA/SWPC DSCOVR/ACE衛星
  Future<List<SolarWindData>> getSolarWind() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/products/solar-wind/plasma-7-day.json'))
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      final results = <SolarWindData>[];

      // 直近24時間分のデータを取得（約288件）
      final startIndex = data.length > 288 ? data.length - 288 : 1;

      for (int i = startIndex; i < data.length; i++) {
        final row = data[i];
        if (row is List && row.length >= 3) {
          final timestamp = DateTime.tryParse(row[0].toString());
          final density = double.tryParse(row[1].toString());
          final speed = double.tryParse(row[2].toString());

          if (timestamp != null) {
            results.add(
              SolarWindData(
                timestamp: timestamp,
                density: density ?? 0,
                speed: speed ?? 0,
              ),
            );
          }
        }
      }

      // 1時間ごとにサンプリング
      return _sampleHourly(results);
    } catch (e) {
      return [];
    }
  }

  /// 太陽風磁場データ（Bz成分）を取得
  Future<List<SolarWindMagData>> getSolarWindMag() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/products/solar-wind/mag-7-day.json'))
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      final results = <SolarWindMagData>[];

      final startIndex = data.length > 288 ? data.length - 288 : 1;

      for (int i = startIndex; i < data.length; i++) {
        final row = data[i];
        if (row is List && row.length >= 4) {
          final timestamp = DateTime.tryParse(row[0].toString());
          final bz = double.tryParse(row[3].toString());
          final bt = double.tryParse(row[6].toString());

          if (timestamp != null) {
            results.add(
              SolarWindMagData(timestamp: timestamp, bz: bz ?? 0, bt: bt ?? 0),
            );
          }
        }
      }

      return _sampleHourlyMag(results);
    } catch (e) {
      return [];
    }
  }

  // ========== X線フラックス（太陽フレア） ==========

  /// GOES衛星のX線フラックスデータを取得
  /// 出典: NOAA/SWPC GOES-16/17衛星
  Future<List<XrayFluxData>> getXrayFlux() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/json/goes/primary/xrays-1-day.json'))
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      final results = <XrayFluxData>[];

      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final timestamp = DateTime.tryParse(item['time_tag'] ?? '');
          final flux = double.tryParse(item['flux']?.toString() ?? '');

          if (timestamp != null && flux != null) {
            results.add(
              XrayFluxData(
                timestamp: timestamp,
                flux: flux,
                flareClass: _getFlareClass(flux),
              ),
            );
          }
        }
      }

      // 直近24件（1時間ごと）
      if (results.length > 24) {
        final step = results.length ~/ 24;
        return [for (int i = 0; i < results.length; i += step) results[i]];
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  // ========== プロトンフラックス ==========

  /// 高エネルギープロトンフラックスを取得
  /// 出典: NOAA/SWPC GOES衛星
  Future<List<ProtonFluxData>> getProtonFlux() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/json/goes/primary/integral-protons-1-day.json',
            ),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      final results = <ProtonFluxData>[];

      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final timestamp = DateTime.tryParse(item['time_tag'] ?? '');
          final flux = double.tryParse(item['flux']?.toString() ?? '');
          final energy = item['energy'] ?? '>10 MeV';

          if (timestamp != null && flux != null) {
            results.add(
              ProtonFluxData(
                timestamp: timestamp,
                flux: flux,
                energy: energy.toString(),
              ),
            );
          }
        }
      }

      // >10MeVのみフィルタして直近24件
      final filtered = results.where((d) => d.energy.contains('10')).toList();
      if (filtered.length > 24) {
        final step = filtered.length ~/ 24;
        return [for (int i = 0; i < filtered.length; i += step) filtered[i]];
      }

      return filtered;
    } catch (e) {
      return [];
    }
  }

  // ========== オーロラ予報 ==========

  /// オーロラオーバル予報データを取得
  /// 出典: NOAA/SWPC OVATION Prime Model
  Future<AuroraForecast?> getAuroraForecast() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/products/noaa-planetary-k-index-forecast.json',
            ),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final List<dynamic> data = jsonDecode(response.body);

      // 予報データから可視緯度を推定
      double maxKp = 0;
      for (int i = 1; i < data.length; i++) {
        final row = data[i];
        if (row is List && row.length >= 2) {
          final kp = double.tryParse(row[1].toString()) ?? 0;
          if (kp > maxKp) maxKp = kp;
        }
      }

      // Kp値から可視緯度を推定（経験的な式）
      // Kp=5で約50°、Kp=9で約40°
      final visibleLatitude = 67 - (maxKp * 3);

      return AuroraForecast(
        maxKp: maxKp,
        visibleLatitude: visibleLatitude.clamp(40.0, 70.0),
        intensity: _getAuroraIntensity(maxKp),
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  // ========== NOAAスケール ==========

  /// 現在のNOAAスケール（R, S, G）を取得
  Future<NoaaScalesData?> getNoaaScales() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/products/noaa-scales.json'))
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;

      final current = data['-1'] ?? data['0'];
      if (current == null) return null;

      return NoaaScalesData(
        rScale: _parseScale(current['R']?['Scale']),
        sScale: _parseScale(current['S']?['Scale']),
        gScale: _parseScale(current['G']?['Scale']),
        rText: current['R']?['Text'] ?? '',
        sText: current['S']?['Text'] ?? '',
        gText: current['G']?['Text'] ?? '',
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  // ========== ヘルパーメソッド ==========

  int _parseScale(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  String _getFlareClass(double flux) {
    if (flux >= 1e-4) return 'X';
    if (flux >= 1e-5) return 'M';
    if (flux >= 1e-6) return 'C';
    if (flux >= 1e-7) return 'B';
    return 'A';
  }

  String _getAuroraIntensity(double kp) {
    if (kp >= 7) return '非常に強い';
    if (kp >= 5) return '強い';
    if (kp >= 4) return 'やや強い';
    if (kp >= 3) return '普通';
    return '弱い';
  }

  List<SolarWindData> _sampleHourly(List<SolarWindData> data) {
    if (data.length <= 24) return data;
    final step = data.length ~/ 24;
    return [
      for (int i = 0; i < data.length; i += step) data[i],
    ].take(24).toList();
  }

  List<SolarWindMagData> _sampleHourlyMag(List<SolarWindMagData> data) {
    if (data.length <= 24) return data;
    final step = data.length ~/ 24;
    return [
      for (int i = 0; i < data.length; i += step) data[i],
    ].take(24).toList();
  }
}

// ========== データモデル ==========

/// Kp指数データ
class KpIndexData {
  final DateTime timestamp;
  final double kpValue;

  KpIndexData({required this.timestamp, required this.kpValue});

  String get level {
    if (kpValue >= 8) return 'G4-G5 極端';
    if (kpValue >= 7) return 'G3 強い';
    if (kpValue >= 6) return 'G2 中程度';
    if (kpValue >= 5) return 'G1 軽度';
    if (kpValue >= 4) return '活発';
    return '静穏';
  }
}

/// 太陽風プラズマデータ
class SolarWindData {
  final DateTime timestamp;
  final double density; // p/cm³
  final double speed; // km/s

  SolarWindData({
    required this.timestamp,
    required this.density,
    required this.speed,
  });

  String get speedLevel {
    if (speed >= 700) return '非常に速い';
    if (speed >= 500) return '速い';
    if (speed >= 400) return '普通';
    return '遅い';
  }
}

/// 太陽風磁場データ
class SolarWindMagData {
  final DateTime timestamp;
  final double bz; // nT (南北成分)
  final double bt; // nT (全磁場)

  SolarWindMagData({
    required this.timestamp,
    required this.bz,
    required this.bt,
  });

  bool get isSouthward => bz < 0;
  String get bzStatus => isSouthward ? '南向き（活発）' : '北向き（静穏）';
}

/// X線フラックスデータ
class XrayFluxData {
  final DateTime timestamp;
  final double flux;
  final String flareClass;

  XrayFluxData({
    required this.timestamp,
    required this.flux,
    required this.flareClass,
  });

  String get level {
    switch (flareClass) {
      case 'X':
        return 'X級（極めて強い）';
      case 'M':
        return 'M級（強い）';
      case 'C':
        return 'C級（中程度）';
      case 'B':
        return 'B級（弱い）';
      default:
        return 'A級（非常に弱い）';
    }
  }
}

/// プロトンフラックスデータ
class ProtonFluxData {
  final DateTime timestamp;
  final double flux;
  final String energy;

  ProtonFluxData({
    required this.timestamp,
    required this.flux,
    required this.energy,
  });

  int get sScale {
    if (flux >= 1e5) return 5;
    if (flux >= 1e4) return 4;
    if (flux >= 1e3) return 3;
    if (flux >= 1e2) return 2;
    if (flux >= 10) return 1;
    return 0;
  }

  String get level {
    switch (sScale) {
      case 5:
        return 'S5 Extreme';
      case 4:
        return 'S4 Severe';
      case 3:
        return 'S3 Strong';
      case 2:
        return 'S2 Moderate';
      case 1:
        return 'S1 Minor';
      default:
        return 'なし';
    }
  }
}

/// オーロラ予報
class AuroraForecast {
  final double maxKp;
  final double visibleLatitude;
  final String intensity;
  final DateTime fetchedAt;

  AuroraForecast({
    required this.maxKp,
    required this.visibleLatitude,
    required this.intensity,
    required this.fetchedAt,
  });

  /// 指定緯度でオーロラが見える可能性
  bool isVisibleAt(double latitude) {
    return latitude.abs() >= visibleLatitude;
  }
}

/// NOAAスケールデータ
class NoaaScalesData {
  final int rScale; // Radio Blackout
  final int sScale; // Solar Radiation Storm
  final int gScale; // Geomagnetic Storm
  final String rText;
  final String sText;
  final String gText;
  final DateTime fetchedAt;

  NoaaScalesData({
    required this.rScale,
    required this.sScale,
    required this.gScale,
    required this.rText,
    required this.sText,
    required this.gText,
    required this.fetchedAt,
  });
}
