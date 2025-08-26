import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';

class PortfolioPage extends ConsumerStatefulWidget{ const PortfolioPage({super.key}); @override ConsumerState<PortfolioPage> createState()=>_PortfolioPageState(); }
class _PortfolioPageState extends ConsumerState<PortfolioPage>{
  final _symbols = ['AAPL','MSFT','GOOG','AMZN','NVDA'];
  final Map<String, TextEditingController> _w = {};
  String _result = '';

  @override void initState(){ super.initState(); for (final s in _symbols){ _w[s] = TextEditingController(text: '0.02'); } }

  @override Widget build(BuildContext context){
    final api = ref.watch(apiProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Portfolio Console', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 8, children: _symbols.map((s)=> SizedBox(width: 160, child: TextField(controller: _w[s], decoration: InputDecoration(labelText: '$s init weight')))).toList()),
        const SizedBox(height: 12),
        Row(children:[
          FilledButton(onPressed: () async {
            final targets = { for(final s in _symbols) s: double.tryParse(_w[s]!.text) ?? 0.0 };
            final body = { 'asof': DateTime.now().toIso8601String(), 'book': 'core', 'target_weights': targets };
            final pre = await api.pretradeCheck({ 'book': 'core', 'targets': targets });
            if(!(pre['ok'] as bool)) { setState(()=> _result = 'Pretrade violations: ${pre['violations']}'); return; }
            final res = await api.publishPortfolio(body);
            setState(()=> _result = 'Optimized weights: ${res['target_weights'] ?? res}');
          }, child: const Text('Optimize & Publish')),
        ]),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_result.isEmpty ? 'No result yet' : _result)))
      ]),
    );
  }
}
