import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/signal.dart';
import '../models/backtest.dart';

class ApiService {
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');
  final String baseUrl;

  Map<String, String> _headers(){
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final h = {'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Future<List<SignalModel>> fetchSignals({String symbol = 'AAPL', String horizon = '1d', int limit = 10}) async {
    final uri = Uri.parse('$baseUrl/v1/signals?symbol=$symbol&horizon=$horizon&limit=$limit');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 401) { throw Exception('Unauthorized — sign in'); }
    if (res.statusCode != 200) throw Exception('Failed to fetch signals');
    final data = json.decode(res.body) as List;
    return data.map((e) => SignalModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> pretradeCheck(Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/v1/compliance/pretrade-check');
    final res = await http.post(uri, body: json.encode(body), headers: _headers());
    if (res.statusCode == 401) { throw Exception('Unauthorized — sign in'); }
    if (res.statusCode != 200) throw Exception('Compliance check failed');
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> publishPortfolio(Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/v1/portfolio/publish');
    final res = await http.post(uri, body: json.encode(body), headers: _headers());
    if (res.statusCode != 200) throw Exception('Publish failed: ${res.body}');
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<BacktestReportModel> runBacktest({required String strategyId, required DateTime start, required DateTime end, double costsBps = 5}) async {
    final uri = Uri.parse('$baseUrl/v1/backtests/run');
    final body = {
      'strategy_id': strategyId,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'costs_bps': costsBps,
    };
    final res = await http.post(uri, headers: _headers(), body: json.encode(body));
    if (res.statusCode != 200) throw Exception('Backtest failed: ${res.body}');
    return BacktestReportModel.fromJson(json.decode(res.body));
  }
}
