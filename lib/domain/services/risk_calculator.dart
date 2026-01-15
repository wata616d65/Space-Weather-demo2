import '../entities/noaa_data.dart';
import '../entities/risk_result.dart';
import '../entities/user_location.dart';

/// 科学的リスク計算サービス
/// 緯度（latitude）に基づいた動的なリスク計算を行う
class RiskCalculator {
  const RiskCalculator();

  /// 全リスクを計算
  AllRiskResults calculateAllRisks({
    required SpaceWeatherData weatherData,
    required UserLocation location,
  }) {
    return AllRiskResults(
      drone: calculateDroneRisk(
        kpIndex: weatherData.kpIndex,
        latitude: location.latitude,
      ),
      gps: calculateGpsRisk(
        kpIndex: weatherData.kpIndex,
        scales: weatherData.scales,
        latitude: location.latitude,
      ),
      radio: calculateRadioRisk(scales: weatherData.scales),
      radiation: calculateRadiationRisk(scales: weatherData.scales),
      calculatedAt: DateTime.now(),
    );
  }

  /// ドローン・コンパス予報 (Magnetic Risk)
  /// 原理: 地磁気嵐は高緯度（極地に近い）ほど激しくなる
  /// 計算式: RiskScore = Kp_Index * (1.0 + (|lat| / 60.0))
  RiskResult calculateDroneRisk({
    required KpIndex kpIndex,
    required double latitude,
  }) {
    final absLat = latitude.abs();
    final score = kpIndex.kpValue * (1.0 + (absLat / 60.0));

    int level;
    String advice;
    if (score < 3.0) {
      level = 1;
      advice = 'ドローン飛行に問題ありません。';
    } else if (score < 4.0) {
      level = 2;
      advice = '安定した状況です。通常飛行可能です。';
    } else if (score < 5.0) {
      level = 3;
      advice = 'コンパス異常の可能性。キャリブレーション推奨。';
    } else if (score < 6.0) {
      level = 4;
      advice = 'コンパスエラーのリスク高。飛行は控えてください。';
    } else {
      level = 5;
      advice = '飛行禁止！地磁気嵐による重大なリスクがあります。';
    }

    return RiskResult(
      type: RiskType.drone,
      level: level,
      score: score,
      advice: advice,
      detailedInfo: 'Kp: ${kpIndex.kpValue.toStringAsFixed(1)}, '
          '緯度補正: ×${(1.0 + (absLat / 60.0)).toStringAsFixed(2)}, '
          'スコア: ${score.toStringAsFixed(2)}',
    );
  }

  /// GPS・位置情報予報 (Ionosphere Risk)
  /// 原理: 電離層の乱れは「赤道異常帯（低緯度）」と「オーロラ帯（高緯度）」で強い
  /// 中緯度（日本など）は比較的安定
  RiskResult calculateGpsRisk({
    required KpIndex kpIndex,
    required NoaaScales scales,
    required double latitude,
  }) {
    final absLat = latitude.abs();
    double score;
    String zoneInfo;

    if (absLat < 30) {
      // 低緯度: 電離層の影響大
      score = (kpIndex.kpValue * 0.5) + (scales.rScale * 1.5);
      zoneInfo = '低緯度帯（電離層影響大）';
    } else if (absLat <= 50) {
      // 中緯度: 標準
      score = (kpIndex.kpValue * 0.8) + scales.rScale;
      zoneInfo = '中緯度帯（標準）';
    } else {
      // 高緯度: 磁気嵐の影響大
      score = (kpIndex.kpValue * 1.2) + (scales.gScale * 0.5);
      zoneInfo = '高緯度帯（磁気嵐影響大）';
    }

    int level;
    String advice;
    if (score < 2.0) {
      level = 1;
      advice = 'GPS精度は良好です。';
    } else if (score < 3.5) {
      level = 2;
      advice = 'GPS精度は安定しています。';
    } else if (score < 5.0) {
      level = 3;
      advice = 'GPS誤差が発生する可能性があります。';
    } else if (score < 7.0) {
      level = 4;
      advice = 'GPSの精度低下に注意してください。';
    } else {
      level = 5;
      advice = 'GPSが使用困難な状況です。代替手段を用意してください。';
    }

    return RiskResult(
      type: RiskType.gps,
      level: level,
      score: score,
      advice: advice,
      detailedInfo: 'Kp: ${kpIndex.kpValue.toStringAsFixed(1)}, '
          'R: ${scales.rScale}, G: ${scales.gScale}, '
          '$zoneInfo, スコア: ${score.toStringAsFixed(2)}',
    );
  }

  /// 通信・電波予報 (Radio Blackout)
  /// 原理: 太陽フレア(X線)によるデリンジャー現象。地球の昼間側全域に一律影響
  /// 計算: 地域補正なし。R_Scaleをそのままレベル化
  RiskResult calculateRadioRisk({required NoaaScales scales}) {
    final rScale = scales.rScale;
    int level;
    String advice;
    String scaleDescription;

    switch (rScale) {
      case 0:
        level = 1;
        advice = '通信状況は良好です。';
        scaleDescription = 'なし';
        break;
      case 1:
        level = 2;
        advice = 'HF通信に軽微な影響の可能性。';
        scaleDescription = 'R1 Minor';
        break;
      case 2:
        level = 3;
        advice = 'HF通信が不安定になる可能性があります。';
        scaleDescription = 'R2 Moderate';
        break;
      case 3:
        level = 3;
        advice = '短波通信に障害が発生する可能性。';
        scaleDescription = 'R3 Strong';
        break;
      case 4:
        level = 4;
        advice = '広範囲で短波通信障害。航空・船舶通信に注意。';
        scaleDescription = 'R4 Severe';
        break;
      case 5:
      default:
        level = 5;
        advice = '深刻な電波障害！緊急通信に支障。';
        scaleDescription = 'R5 Extreme';
        break;
    }

    return RiskResult(
      type: RiskType.radio,
      level: level,
      score: rScale.toDouble(),
      advice: advice,
      detailedInfo: 'R-Scale: $scaleDescription (R$rScale)',
    );
  }

  /// 航空・被ばく予報 (Radiation)
  /// 原理: 極域航路での被ばくリスク
  /// 計算: S_Scaleをそのままレベル化
  RiskResult calculateRadiationRisk({required NoaaScales scales}) {
    final sScale = scales.sScale;
    int level;
    String advice;
    String scaleDescription;

    switch (sScale) {
      case 0:
        level = 1;
        advice = '放射線レベルは通常範囲内です。';
        scaleDescription = 'なし';
        break;
      case 1:
        level = 2;
        advice = '極域航路で軽微な影響の可能性。';
        scaleDescription = 'S1 Minor';
        break;
      case 2:
        level = 3;
        advice = '極域航路で被ばく量増加。妊婦は注意。';
        scaleDescription = 'S2 Moderate';
        break;
      case 3:
        level = 4;
        advice = '極域航路は避けることを推奨します。';
        scaleDescription = 'S3 Strong';
        break;
      case 4:
        level = 4;
        advice = '高高度・極域航路は危険。フライト変更を検討。';
        scaleDescription = 'S4 Severe';
        break;
      case 5:
      default:
        level = 5;
        advice = '航空機の被ばくリスク極大！飛行自粛推奨。';
        scaleDescription = 'S5 Extreme';
        break;
    }

    return RiskResult(
      type: RiskType.radiation,
      level: level,
      score: sScale.toDouble(),
      advice: advice,
      detailedInfo: 'S-Scale: $scaleDescription (S$sScale)',
    );
  }
}
