/// リスク計算結果
class RiskResult {
  final RiskType type;
  final int level; // 1-5 (1: 安全, 5: 危険)
  final double score; // 生スコア
  final String advice; // ひとことアドバイス
  final String detailedInfo; // Core向け詳細情報

  const RiskResult({
    required this.type,
    required this.level,
    required this.score,
    required this.advice,
    required this.detailedInfo,
  });

  /// レベルに応じたステータステキスト
  String get statusText {
    switch (level) {
      case 1:
        return '良好';
      case 2:
        return '安定';
      case 3:
        return '注意';
      case 4:
        return '警戒';
      case 5:
        return '厳重警戒';
      default:
        return '不明';
    }
  }

  @override
  String toString() => 'RiskResult($type: Lv.$level, score: $score)';
}

/// リスクの種類
enum RiskType {
  drone, // ドローン・コンパス
  gps, // GPS・位置情報
  radio, // 通信・電波
  radiation, // 航空・被ばく
}

extension RiskTypeExtension on RiskType {
  /// リスクタイプの日本語名
  String get label {
    switch (this) {
      case RiskType.drone:
        return 'ドローン・コンパス';
      case RiskType.gps:
        return 'GPS・位置情報';
      case RiskType.radio:
        return '通信・電波';
      case RiskType.radiation:
        return '航空・被ばく';
    }
  }

  /// リスクタイプの英語名（短縮）
  String get shortLabel {
    switch (this) {
      case RiskType.drone:
        return 'Drone';
      case RiskType.gps:
        return 'GPS';
      case RiskType.radio:
        return 'Radio';
      case RiskType.radiation:
        return 'Radiation';
    }
  }

  /// アイコン名（Material Icons）
  String get iconName {
    switch (this) {
      case RiskType.drone:
        return 'flight';
      case RiskType.gps:
        return 'gps_fixed';
      case RiskType.radio:
        return 'cell_tower';
      case RiskType.radiation:
        return 'health_and_safety';
    }
  }
}

/// 全リスクの統合結果
class AllRiskResults {
  final RiskResult drone;
  final RiskResult gps;
  final RiskResult radio;
  final RiskResult radiation;
  final DateTime calculatedAt;

  const AllRiskResults({
    required this.drone,
    required this.gps,
    required this.radio,
    required this.radiation,
    required this.calculatedAt,
  });

  /// すべてのリスクをリストで取得
  List<RiskResult> get all => [drone, gps, radio, radiation];

  /// 最も危険なレベル
  int get maxLevel {
    return [drone.level, gps.level, radio.level, radiation.level]
        .reduce((a, b) => a > b ? a : b);
  }

  /// 全体の状況サマリー
  String get overallSummary {
    final max = maxLevel;
    if (max <= 2) return '現在、宇宙天気は安定しています。';
    if (max == 3) return '一部で注意が必要な状況です。';
    if (max == 4) return '警戒が必要な状況です。活動を控えてください。';
    return '厳重警戒！活動を中止してください。';
  }
}
