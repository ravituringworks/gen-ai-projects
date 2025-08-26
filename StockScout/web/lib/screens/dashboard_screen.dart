import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/stock.dart';
import '../models/agent_result.dart';
import '../widgets/stock_list_widget.dart';
import '../widgets/agent_status_widget.dart';
import '../widgets/retry_status_widget.dart';
import '../widgets/stock_chart_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedHorizon = '1day';
  List<TopStock> _topStocks = [];
  List<AgentStatus> _agentStatuses = [];
  Map<String, List<TopStock>> _screeningResults = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // Load data in background without blocking UI
    _loadTopStocks();
    _loadAgentStatus();
    _loadScreeningResults();

    setState(() {
      _isInitialized = true;
    });
  }

  // Removed popup alerts - using retry status widget instead
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _loadTopStocks() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final stocks = await apiService.getTopStocks(_selectedHorizon);
    setState(() {
      _topStocks = stocks;
    });
  }

  Future<void> _loadAgentStatus() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final statuses = await apiService.getAgentStatus();
    setState(() {
      _agentStatuses = statuses;
    });
  }

  Future<void> _loadScreeningResults() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final results = await apiService.getScreeningResults();
    setState(() {
      _screeningResults = results;
    });
  }

  Future<void> _triggerScreening() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    final success = await apiService.triggerScreening();
    
    if (success) {
      _showSuccess('Screening process started successfully!');
      // Refresh data after a delay to allow processing
      Future.delayed(const Duration(seconds: 2), () {
        _loadInitialData();
      });
    } else {
      _showError('Failed to trigger screening process.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Agent Stock Research Platform'),
        actions: [
          Consumer<ApiService>(
            builder: (context, apiService, child) {
              return IconButton(
                onPressed: apiService.isLoading ? null : _triggerScreening,
                icon: apiService.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Trigger Manual Screening',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Top Stocks', icon: Icon(Icons.trending_up)),
            Tab(text: 'Agents', icon: Icon(Icons.smart_toy)),
            Tab(text: 'Screening', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Retry status widget at the top
          const RetryStatusWidget(),
          
          // Main content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTopStocksTab(),
                _buildAgentsTab(),
                _buildScreeningTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Active Agents',
                  value: _agentStatuses.length.toString(),
                  icon: Icons.smart_toy,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Top Stocks (1D)',
                  value: _topStocks.length.toString(),
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Stock Performance Chart
          StockPerformanceChart(stocks: _topStocks.take(10).toList()),
          
          const SizedBox(height: 24),
          
          // Recent Top Performers
          const Text(
            'Recent Top Performers (1 Day)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Consumer<ApiService>(
              builder: (context, apiService, child) {
                if (apiService.isLoading && _topStocks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StockListWidget(
                  stocks: _topStocks.take(5).toList(),
                  showRanking: true,
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Agent Status Overview
          const Text(
            'Agent Status Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          AgentStatusWidget(agentStatuses: _agentStatuses),
        ],
      ),
    );
  }

  Widget _buildTopStocksTab() {
    return Column(
      children: [
        // Horizon Selector
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Time Horizon:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '1day', label: Text('1 Day')),
                    ButtonSegment(value: '1week', label: Text('1 Week')),
                    ButtonSegment(value: '1month', label: Text('1 Month')),
                  ],
                  selected: {_selectedHorizon},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedHorizon = newSelection.first;
                    });
                    _loadTopStocks();
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Stock Chart and List
        Expanded(
          child: Consumer<ApiService>(
            builder: (context, apiService, child) {
              if (apiService.isLoading && _topStocks.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading top stocks...'),
                    ],
                  ),
                );
              }
              
              if (_topStocks.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No stocks found for this horizon',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Stocks will appear here as data loads',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              
              return StockChartWidget(stocks: _topStocks);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAgentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.smart_toy, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Agent Status & Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Last Updated: ${DateTime.now().toString().split('.')[0]}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: AgentStatusWidget(agentStatuses: _agentStatuses),
        ),
      ],
    );
  }

  Widget _buildScreeningTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screening Controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Screening Controls',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<ApiService>(
                          builder: (context, apiService, child) {
                            return ElevatedButton.icon(
                              onPressed: apiService.isLoading ? null : _triggerScreening,
                              icon: apiService.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.play_arrow),
                              label: Text(apiService.isLoading ? 'Running...' : 'Run Screening'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loadInitialData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Data'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Screening Results by Horizon
          if (_screeningResults.isNotEmpty) ...[
            const Text(
              'Screening Results Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            for (final entry in _screeningResults.entries) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getHorizonIcon(entry.key),
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getHorizonDisplayName(entry.key),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Chip(
                            label: Text('${entry.value.length} stocks'),
                            backgroundColor: Colors.blue.shade50,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: StockListWidget(
                          stocks: entry.value.take(3).toList(),
                          showRanking: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ] else ...[
            const Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No screening results available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Run a screening to see results',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getHorizonIcon(String horizon) {
    switch (horizon) {
      case '1day':
        return Icons.today;
      case '1week':
        return Icons.calendar_view_week;
      case '1month':
        return Icons.calendar_month;
      default:
        return Icons.timeline;
    }
  }

  String _getHorizonDisplayName(String horizon) {
    switch (horizon) {
      case '1day':
        return '1-Day Horizon';
      case '1week':
        return '1-Week Horizon';
      case '1month':
        return '1-Month Horizon';
      default:
        return horizon;
    }
  }
}
