/// 予報の信頼度レベル
///
/// 科学的根拠:
/// - CME（コロナ質量放出）の地球到達時間は速度により1-4日
/// - 参考: Vršnak et al. (2013), Solar Physics, 285, 295-315
/// - 参考: Gopalswamy et al. (2001), J. Geophys. Res., 106, 29207-29218
enum ForecastConfidence {
  /// 1-2日目: NOAAリアルタイムデータ + 短期予報
  high,

  /// 3日目: NOAA 3-Day Forecast
  medium,

  /// 4日目: CME最遅到達時間に基づく傾向予測
  low,
}

/// 宇宙天気予報データエンティティ
///
/// CME伝播時間に基づく科学的根拠:
/// - 遅いCME (400-600 km/s): 3-4日で地球到達
/// - 普通のCME (600-1000 km/s): 2-3日で地球到達
/// - 速いCME (>1000 km/s): 1-2日で地球到達
///
/// 参考文献:
/// - Vršnak et al. (2013) "Propagation of Interplanetary Coronal Mass Ejections: The Drag-Based Model"
/// - Gopalswamy et al. (2001) "Predicting the 1-AU arrival times of coronal mass ejections"
class SpaceWeatherForecast {
  final DateTime date;
  final int geomagneticLevel; // 1-5 (NOAAスケール G1-G5に対応)
  final int solarRadiationLevel; // 1-5 (NOAAスケール S1-S5に対応)
  final int radioBlackoutLevel; // 1-5 (NOAAスケール R1-R5に対応)
  final String geomagneticDescription;
  final String summary;
  final ForecastConfidence confidence;

  const SpaceWeatherForecast({
    required this.date,
    required this.geomagneticLevel,
    required this.solarRadiationLevel,
    required this.radioBlackoutLevel,
    required this.geomagneticDescription,
    required this.summary,
    required this.confidence,
  });

  /// 全体的なリスクレベル（最大値）
  int get overallLevel {
    return [
      geomagneticLevel,
      solarRadiationLevel,
      radioBlackoutLevel,
    ].reduce((a, b) => a > b ? a : b);
  }

  /// 信頼度の説明文を取得
  String get confidenceLabel {
    switch (confidence) {
      case ForecastConfidence.high:
        return 'NOAA実データ';
      case ForecastConfidence.medium:
        return 'NOAA予報';
      case ForecastConfidence.low:
        return 'CME傾向';
    }
  }
}

/// 4日間予報データ
///
/// CME伝播予測に基づき、科学的に予測可能な最大期間は4日間
///
/// 科学的根拠:
/// - CMEの最遅到達時間: 約4日（遅いCME 400km/sの場合）
/// - 4日を超える予測は太陽活動の不確実性により精度が著しく低下
///
/// 参考文献:
/// - Vršnak et al. (2013), Solar Physics, 285, 295-315, DOI: 10.1007/s11207-012-0035-4
/// - Gopalswamy et al. (2001), J. Geophys. Res., 106, A12, 29207-29218
class FourDayForecast {
  final List<SpaceWeatherForecast> forecasts;
  final DateTime fetchedAt;

  const FourDayForecast({required this.forecasts, required this.fetchedAt});
}
