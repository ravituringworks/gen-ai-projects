import 'package:flutter/material.dart';
import '../models/stock.dart';

class StockChartWidget extends StatelessWidget {
  final List<TopStock> stocks;
  
  const StockChartWidget({
    super.key,
    required this.stocks,
  });

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No stock data available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Top Stock Performance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stocks.length,
            itemBuilder: (context, index) {
              final stock = stocks[index];
              return _buildStockChartCard(stock, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStockChartCard(TopStock stock, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getRankColor(rank),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Stock info
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    stock.name,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      stock.exchange,
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Score visualization
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(stock.score * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildScoreBar(stock.score),
                  const SizedBox(height: 8),
                  if (stock.price != null) ...[
                    Text(
                      '\$${stock.price!.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(double score) {
    return Container(
      width: 80,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        widthFactor: score,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: _getScoreColor(score),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return Colors.amber[700]!;
    if (rank <= 10) return Colors.blue[700]!;
    return Colors.grey[600]!;
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green[600]!;
    if (score >= 0.6) return Colors.orange[600]!;
    return Colors.red[600]!;
  }
}

class StockPerformanceChart extends StatelessWidget {
  final List<TopStock> stocks;
  
  const StockPerformanceChart({
    super.key,
    required this.stocks,
  });

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) {
      return const SizedBox.shrink();
    }

    final topStocks = stocks.take(10).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Scores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: topStocks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stock = entry.value;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: stock.score * 150,
                            decoration: BoxDecoration(
                              color: _getBarColor(index),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stock.symbol,
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBarColor(int index) {
    final colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
      Colors.red[600]!,
    ];
    return colors[index % colors.length];
  }
}