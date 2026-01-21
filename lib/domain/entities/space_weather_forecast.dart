/// 宇宙天気予報データエンティティ
class SpaceWeatherForecast {
  final DateTime date;
  final int geomagneticLevel; // 1-5
  final int solarRadiationLevel; // 1-5
  final int radioBlackoutLevel; // 1-5
  final String geomagneticDescription;
  final String summary;
  final bool isPrediction; // 3日目以降は予測

  const SpaceWeatherForecast({
    required this.date,
    required this.geomagneticLevel,
    required this.solarRadiationLevel,
    required this.radioBlackoutLevel,
    required this.geomagneticDescription,
    required this.summary,
    this.isPrediction = false,
  });

  /// 全体的なリスクレベル（最大値）
  int get overallLevel {
    return [
      geomagneticLevel,
      solarRadiationLevel,
      radioBlackoutLevel,
    ].reduce((a, b) => a > b ? a : b);
  }

  /// JSONからパース（NOAA 3-Day Forecast形式）
  factory SpaceWeatherForecast.fromNoaaJson(
    Map<String, dynamic> json,
    DateTime date,
  ) {
    // NOAA形式のレベル文字列を数値に変換
    int parseLevel(String? levelStr) {
      if (levelStr == null) return 1;
      // "G1", "S2", "R3" などの形式
      final match = RegExp(r'[GSR](\d)').firstMatch(levelStr);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '1') ?? 1;
      }
      // "Minor", "Moderate", "Strong" などの場合
      switch (levelStr.toLowerCase()) {
        case 'none':
          return 1;
        case 'minor':
          return 2;
        case 'moderate':
          return 3;
        case 'strong':
          return 4;
        case 'severe':
        case 'extreme':
          return 5;
        default:
          return 1;
      }
    }

    return SpaceWeatherForecast(
      date: date,
      geomagneticLevel: parseLevel(json['geomagnetic'] as String?),
      solarRadiationLevel: parseLevel(json['solar_radiation'] as String?),
      radioBlackoutLevel: parseLevel(json['radio_blackout'] as String?),
      geomagneticDescription:
          json['geomagnetic_description'] as String? ?? '安定',
      summary: json['summary'] as String? ?? '宇宙天気は安定しています',
    );
  }

  /// ダミーデータ生成（開発用）
  factory SpaceWeatherForecast.dummy(
    DateTime date, {
    bool isPrediction = false,
  }) {
    // 日付に基づいてある程度ランダムだが再現性のある値を生成
    final seed = date.day + date.month;
    final geoLevel = (seed % 3) + 1;
    final solarLevel = ((seed + 1) % 3) + 1;
    final radioLevel = ((seed + 2) % 3) + 1;

    final descriptions = ['安定', '穏やか', 'やや活発', '活発'];
    final summaries = [
      '宇宙天気は安定しています。',
      '軽微な活動が予想されます。',
      '中程度の活動に注意が必要です。',
      '活発な活動が予想されます。',
    ];

    return SpaceWeatherForecast(
      date: date,
      geomagneticLevel: geoLevel,
      solarRadiationLevel: solarLevel,
      radioBlackoutLevel: radioLevel,
      geomagneticDescription: descriptions[geoLevel - 1],
      summary: summaries[geoLevel - 1],
      isPrediction: isPrediction,
    );
  }
}

/// 1週間予報データ
class WeeklyForecast {
  final List<SpaceWeatherForecast> forecasts;
  final DateTime fetchedAt;

  const WeeklyForecast({required this.forecasts, required this.fetchedAt});

  /// ダミーデータ生成
  factory WeeklyForecast.dummy() {
    final now = DateTime.now();
    final forecasts = List.generate(7, (index) {
      final date = now.add(Duration(days: index));
      return SpaceWeatherForecast.dummy(
        date,
        isPrediction: index >= 3, // 3日目以降は予測
      );
    });

    return WeeklyForecast(forecasts: forecasts, fetchedAt: now);
  }
}
