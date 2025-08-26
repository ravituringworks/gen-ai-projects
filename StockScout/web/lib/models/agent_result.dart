class AgentResult {
  final String id;
  final String agentType;
  final String stockSymbol;
  final String horizon;
  final double score;
  final String reasoning;
  final DateTime createdAt;

  AgentResult({
    required this.id,
    required this.agentType,
    required this.stockSymbol,
    required this.horizon,
    required this.score,
    required this.reasoning,
    required this.createdAt,
  });

  factory AgentResult.fromJson(Map<String, dynamic> json) {
    return AgentResult(
      id: json['id'] ?? '',
      agentType: json['agent_type'] ?? '',
      stockSymbol: json['stock_symbol'] ?? '',
      horizon: json['horizon'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get formattedScore => '${(score * 100).toStringAsFixed(1)}%';
  
  String get displayAgentType {
    switch (agentType) {
      case 'data_agent':
        return 'Data Agent';
      case 'analysis_agent_1day':
        return '1-Day Analysis';
      case 'analysis_agent_1week':
        return '1-Week Analysis';
      case 'analysis_agent_1month':
        return '1-Month Analysis';
      default:
        return agentType.replaceAll('_', ' ').toUpperCase();
    }
  }
  
  String get displayHorizon {
    switch (horizon) {
      case '1day':
        return '1 Day';
      case '1week':
        return '1 Week';
      case '1month':
        return '1 Month';
      default:
        return horizon;
    }
  }
}

class AgentStatus {
  final String agentType;
  final String status;
  final DateTime? lastRun;
  final int totalResults;

  AgentStatus({
    required this.agentType,
    required this.status,
    this.lastRun,
    required this.totalResults,
  });

  factory AgentStatus.fromJson(Map<String, dynamic> json) {
    return AgentStatus(
      agentType: json['agent_type'] ?? '',
      status: json['status'] ?? 'unknown',
      lastRun: json['last_run'] != null 
          ? DateTime.parse(json['last_run']) 
          : null,
      totalResults: json['total_results'] ?? 0,
    );
  }

  String get displayAgentType {
    switch (agentType) {
      case 'data_agent':
        return 'Data Acquisition Agent';
      case 'analysis_agent_1day':
        return '1-Day Analysis Agent';
      case 'analysis_agent_1week':
        return '1-Week Analysis Agent';
      case 'analysis_agent_1month':
        return '1-Month Analysis Agent';
      default:
        return agentType.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'active':
        return '#4CAF50'; // Green
      case 'idle':
        return '#FF9800'; // Orange
      case 'error':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  String get lastRunDisplay {
    if (lastRun == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastRun!);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${lastRun!.month}/${lastRun!.day}/${lastRun!.year}';
  }
}
