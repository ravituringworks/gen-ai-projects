import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/shell.dart';
import 'features/dashboard/analyst_workbench_page.dart';
import 'features/signals/signals_page.dart';
import 'features/portfolio/portfolio_page.dart';
import 'features/backtests/backtests_page.dart';
import 'features/ops/ops_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    ShellRoute(
      builder: (_, __, child) => DashboardShell(child: child),
      routes: [
        GoRoute(path: '/workbench', builder: (_, __) => const AnalystWorkbenchPage()),
        GoRoute(path: '/signals', builder: (_, __) => const SignalsPage()),
        GoRoute(path: '/portfolio', builder: (_, __) => const PortfolioPage()),
        GoRoute(path: '/backtests', builder: (_, __) => const BacktestsPage()),
        GoRoute(path: '/ops', builder: (_, __) => const OpsPage()),
      ],
    ),
  ],
);
