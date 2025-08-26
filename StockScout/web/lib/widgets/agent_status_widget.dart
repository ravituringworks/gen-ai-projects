import 'package:flutter/material.dart';
import '../models/agent_result.dart';

class AgentStatusWidget extends StatelessWidget {
  final List<AgentStatus> agentStatuses;

  const AgentStatusWidget({
    super.key,
    required this.agentStatuses,
  });

  @override
  Widget build(BuildContext context) {
    if (agentStatuses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No agent data available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              'Agents will appear here after the first screening run',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agentStatuses.length,
      itemBuilder: (context, index) {
        final agent = agentStatuses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getStatusColor(agent.status),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        agent.displayAgentType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(agent.status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        agent.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(agent.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.assessment,
                        label: 'Results',
                        value: agent.totalResults.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.schedule,
                        label: 'Last Run',
                        value: agent.lastRunDisplay,
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.memory,
                        label: 'Agent Type',
                        value: _getAgentTypeAbbr(agent.agentType),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Performance indicator
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey[200],
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _getPerformanceRatio(agent),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _getPerformanceColor(agent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Performance: ${(_getPerformanceRatio(agent) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'idle':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'running':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getAgentTypeAbbr(String agentType) {
    switch (agentType) {
      case 'data_agent':
        return 'DATA';
      case 'analysis_agent_1day':
        return '1D';
      case 'analysis_agent_1week':
        return '1W';
      case 'analysis_agent_1month':
        return '1M';
      default:
        return agentType.substring(0, 4).toUpperCase();
    }
  }

  double _getPerformanceRatio(AgentStatus agent) {
    // Calculate performance based on results count and recency
    double basePerformance = (agent.totalResults / 100.0).clamp(0.0, 1.0);
    
    if (agent.lastRun != null) {
      final hoursSinceLastRun = DateTime.now().difference(agent.lastRun!).inHours;
      if (hoursSinceLastRun < 24) {
        basePerformance += 0.2; // Bonus for recent activity
      }
    }
    
    return basePerformance.clamp(0.0, 1.0);
  }

  Color _getPerformanceColor(AgentStatus agent) {
    final ratio = _getPerformanceRatio(agent);
    if (ratio >= 0.8) return Colors.green;
    if (ratio >= 0.6) return Colors.lightGreen;
    if (ratio >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
