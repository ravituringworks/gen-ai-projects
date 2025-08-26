import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../models/signal.dart';

final apiProvider = Provider<ApiService>((ref)=>ApiService());
final signalsProvider = FutureProvider.autoDispose<List<SignalModel>>((ref) async {
  final api = ref.watch(apiProvider);
  return api.fetchSignals(symbol: 'AAPL', horizon: '1d', limit: 20);
});

class SignalsPage extends ConsumerWidget {
  const SignalsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref){
    final async = ref.watch(signalsProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Signals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(child: async.when(
          data: (rows)=> Card(
            child: ListView.separated(
              itemBuilder: (_, i){
                final s = rows[i];
                return ListTile(
                  leading: const Icon(Icons.trending_up),
                  title: Text('${s.symbol}  •  ${s.horizon}  •  ${s.model_version}'),
                  subtitle: Text('score ${s.score.toStringAsFixed(3)}  |  conf ${s.confidence.toStringAsFixed(2)}\n${s.explain}'),
                );
              },
              separatorBuilder: (_, __)=> const Divider(height: 1),
              itemCount: rows.length,
            ),
          ),
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e, _)=> Center(child: Text('Error: $e')),
        ))
      ]),
    );
  }
}
