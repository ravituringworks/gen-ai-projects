import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context){
    final path = GoRouterState.of(context).uri.path;
    final idx = _indexFromRoute(path);
    return Scaffold(
      appBar: AppBar(title: const Text('Market Intelligence')),
      body: Row(children: [
        NavigationRail(destinations: const [
          NavigationRailDestination(icon: Icon(Icons.science), label: Text('Workbench')),
          NavigationRailDestination(icon: Icon(Icons.insights), label: Text('Signals')),
          NavigationRailDestination(icon: Icon(Icons.account_balance_wallet), label: Text('Portfolio')),
          NavigationRailDestination(icon: Icon(Icons.timeline), label: Text('Backtests')),
          NavigationRailDestination(icon: Icon(Icons.policy), label: Text('Ops')),
        ], selectedIndex: idx,
          onDestinationSelected: (i){ switch(i){
            case 0: context.go('/workbench'); break;
            case 1: context.go('/signals'); break;
            case 2: context.go('/portfolio'); break;
            case 3: context.go('/backtests'); break;
            case 4: context.go('/ops'); break;
          }}),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ]),
    );
  }
}

int _indexFromRoute(String path){
  if(path.startsWith('/signals')) return 1;
  if(path.startsWith('/portfolio')) return 2;
  if(path.startsWith('/backtests')) return 3;
  if(path.startsWith('/ops')) return 4;
  return 0;
}
