import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';

final backtestProvider = FutureProvider.autoDispose((ref) async {
  final api = ref.watch(apiProvider);
  return api.runBacktest(strategyId: 'topk', start: DateTime.now().subtract(const Duration(days: 120)), end: DateTime.now());
});

class BacktestsPage extends ConsumerWidget { const BacktestsPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(backtestProvider);
    return Padding(padding: const EdgeInsets.all(16), child: async.when(
      data: (rep){
        final curve = (rep.summary['equity_curve'] as List).cast<List>().toList();
        final points = <FlSpot>[]; double i=0; for(final e in curve){ points.add(FlSpot(i++, (e[1] as num).toDouble())); }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sharpe ${rep.sharpe.toStringAsFixed(2)}  •  MaxDD ${(rep.max_dd*100).toStringAsFixed(1)}%  •  Turnover ${rep.turnover.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          Expanded(child: LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: points)]))),
        ]);
      },
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e, _)=> Center(child: Text('Error: $e')),
    ));
  }
}
