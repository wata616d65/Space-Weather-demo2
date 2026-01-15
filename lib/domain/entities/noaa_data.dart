/// NOAAから取得するスケールデータ
/// G: 地磁気嵐, S: 太陽放射線, R: 電波障害
class NoaaScales {
  final int gScale; // G0-G5 (地磁気嵐レベル)
  final int sScale; // S0-S5 (太陽放射線レベル)
  final int rScale; // R0-R5 (電波障害レベル)
  final DateTime timestamp;

  const NoaaScales({
    required this.gScale,
    required this.sScale,
    required this.rScale,
    required this.timestamp,
  });

  factory NoaaScales.fromJson(Map<String, dynamic> json) {
    // NOAA APIのレスポンス形式に対応
    // 例: {"G": {"Scale": 1}, "S": {"Scale": 0}, "R": {"Scale": 0}}
    return NoaaScales(
      gScale: _extractScale(json['G']),
      sScale: _extractScale(json['S']),
      rScale: _extractScale(json['R']),
      timestamp: DateTime.now(),
    );
  }

  static int _extractScale(dynamic scaleData) {
    if (scaleData == null) return 0;
    if (scaleData is Map) {
      final scale = scaleData['Scale'];
      if (scale == null || scale == 'none') return 0;
      return int.tryParse(scale.toString()) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'G': {'Scale': gScale},
      'S': {'Scale': sScale},
      'R': {'Scale': rScale},
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// スケールがすべて正常か
  bool get isAllClear => gScale == 0 && sScale == 0 && rScale == 0;

  @override
  String toString() =>
      'NoaaScales(G$gScale, S$sScale, R$rScale at $timestamp)';
}

/// Kp指数データ
class KpIndex {
  final double kpValue; // 0.0 - 9.0
  final DateTime timestamp;

  const KpIndex({
    required this.kpValue,
    required this.timestamp,
  });

  factory KpIndex.fromJson(Map<String, dynamic> json) {
    // planetary-k-index.json から抽出
    // 最新のKp値を取得
    double kp = 0.0;
    DateTime time = DateTime.now();

    if (json.containsKey('kp_index')) {
      kp = double.tryParse(json['kp_index'].toString()) ?? 0.0;
    }
    if (json.containsKey('time_tag')) {
      time = DateTime.tryParse(json['time_tag'].toString()) ?? DateTime.now();
    }

    return KpIndex(kpValue: kp, timestamp: time);
  }

  Map<String, dynamic> toJson() {
    return {
      'kp_index': kpValue,
      'time_tag': timestamp.toIso8601String(),
    };
  }

  /// Kp値のレベル分類
  /// Minor: 5, Moderate: 6, Strong: 7, Severe: 8, Extreme: 9
  String get stormLevel {
    if (kpValue < 5) return 'Quiet';
    if (kpValue < 6) return 'Minor Storm (G1)';
    if (kpValue < 7) return 'Moderate Storm (G2)';
    if (kpValue < 8) return 'Strong Storm (G3)';
    if (kpValue < 9) return 'Severe Storm (G4)';
    return 'Extreme Storm (G5)';
  }

  @override
  String toString() => 'KpIndex($kpValue at $timestamp)';
}

/// 組み合わせた宇宙天気データ
class SpaceWeatherData {
  final NoaaScales scales;
  final KpIndex kpIndex;
  final DateTime fetchedAt;

  const SpaceWeatherData({
    required this.scales,
    required this.kpIndex,
    required this.fetchedAt,
  });

  factory SpaceWeatherData.empty() {
    return SpaceWeatherData(
      scales: NoaaScales(
        gScale: 0,
        sScale: 0,
        rScale: 0,
        timestamp: DateTime.now(),
      ),
      kpIndex: KpIndex(kpValue: 0, timestamp: DateTime.now()),
      fetchedAt: DateTime.now(),
    );
  }

  @override
  String toString() => 'SpaceWeatherData(scales: $scales, kp: $kpIndex)';
}
