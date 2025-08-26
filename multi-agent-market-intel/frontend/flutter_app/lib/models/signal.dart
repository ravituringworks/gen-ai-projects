class SignalModel {
  final String asof;
  final String symbol;
  final String signal_id;
  final String model_version;
  final String horizon;
  final double score;
  final double confidence;
  final Map<String, dynamic> explain;

  SignalModel({
    required this.asof,
    required this.symbol,
    required this.signal_id,
    required this.model_version,
    required this.horizon,
    required this.score,
    required this.confidence,
    required this.explain,
  });

  factory SignalModel.fromJson(Map<String, dynamic> json) => SignalModel(
    asof: json['asof'] as String,
    symbol: json['symbol'] as String,
    signal_id: json['signal_id'] as String,
    model_version: json['model_version'] as String,
    horizon: json['horizon'] as String,
    score: (json['score'] as num).toDouble(),
    confidence: (json['confidence'] as num).toDouble(),
    explain: (json['explain'] as Map<String, dynamic>),
  );
}
