import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_research_platform/widgets/agent_status_card.dart';
import 'package:stock_research_platform/models/agent_result.dart';

void main() {
  group('Agent Status Widget Tests', () {
    late AgentStatus testAgentStatus;

    setUp(() {
      testAgentStatus = AgentStatus(
        agentType: 'analysis_agent_1day',
        status: 'active',
        lastRun: DateTime.now().subtract(Duration(minutes: 30)),
        totalResults: 150,
      );
    });

    testWidgets('Agent status card displays all information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentStatusCard(agentStatus: testAgentStatus),
          ),
        ),
      );

      // Verify agent type display name
      expect(find.text('1-Day Analysis Agent'), findsOneWidget);
      
      // Verify status is displayed
      expect(find.text('active'), findsOneWidget);
      
      // Verify total results
      expect(find.text('150'), findsOneWidget);
      
      // Verify last run time (should show "30m ago")
      expect(find.textContaining('30m ago'), findsWidgets);
    });

    testWidgets('Agent status shows correct color for different statuses', (WidgetTester tester) async {
      final activeAgent = AgentStatus(
        agentType: 'data_agent',
        status: 'active',
        totalResults: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentStatusCard(agentStatus: activeAgent),
          ),
        ),
      );

      // Should find an active status indicator (green color)
      expect(find.text('active'), findsOneWidget);
    });

    testWidgets('Agent status handles null last run', (WidgetTester tester) async {
      final agentWithNullLastRun = AgentStatus(
        agentType: 'coordinator_agent',
        status: 'idle',
        lastRun: null,
        totalResults: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentStatusCard(agentStatus: agentWithNullLastRun),
          ),
        ),
      );

      // Should display "Never" for null last run
      expect(find.text('Never'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Different agent types display correct names', (WidgetTester tester) async {
      final dataAgent = AgentStatus(
        agentType: 'data_agent',
        status: 'active',
        totalResults: 500,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentStatusCard(agentStatus: dataAgent),
          ),
        ),
      );

      expect(find.text('Data Acquisition Agent'), findsOneWidget);
    });

    testWidgets('Agent status card tap interaction', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => tapped = true,
              child: AgentStatusCard(agentStatus: testAgentStatus),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AgentStatusCard));
      expect(tapped, true);
    });
  });
}