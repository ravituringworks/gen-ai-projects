class BacktestReportModel {
  final String run_id;
  final double sharpe;
  final double max_dd;
  final double turnover;
  final Map<String, dynamic> summary;

  BacktestReportModel({required this.run_id, required this.sharpe, required this.max_dd, required this.turnover, required this.summary});

  factory BacktestReportModel.fromJson(Map<String, dynamic> json) => BacktestReportModel(
    run_id: json['run_id'] as String,
    sharpe: (json['sharpe'] as num).toDouble(),
    max_dd: (json['max_dd'] as num).toDouble(),
    turnover: (json['turnover'] as num).toDouble(),
    summary: (json['summary'] as Map<String, dynamic>),
  );
}
