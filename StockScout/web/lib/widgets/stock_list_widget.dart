import 'package:flutter/material.dart';
import '../models/stock.dart';

class StockListWidget extends StatelessWidget {
  final List<TopStock> stocks;
  final bool showRanking;

  const StockListWidget({
    super.key,
    required this.stocks,
    this.showRanking = false,
  });

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No stocks to display',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: stocks.length,
      itemBuilder: (context, index) {
        final stock = stocks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: showRanking
                ? CircleAvatar(
                    backgroundColor: _getRankingColor(index),
                    foregroundColor: Colors.white,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: _getExchangeColor(stock.exchange),
                    foregroundColor: Colors.white,
                    child: Text(
                      stock.symbol.length > 2 
                          ? stock.symbol.substring(0, 2)
                          : stock.symbol,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    stock.symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getScoreColor(stock.score).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stock.formattedScore,
                    style: TextStyle(
                      color: _getScoreColor(stock.score),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.name,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(stock.exchange, Colors.blue),
                    const SizedBox(width: 8),
                    _buildInfoChip(stock.formattedPrice, Colors.green),
                    const SizedBox(width: 8),
                    _buildInfoChip(stock.formattedMarketCap, Colors.orange),
                  ],
                ),
                if (stock.reasoning.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    stock.reasoning,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            onTap: () {
              _showStockDetails(context, stock);
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getRankingColor(int index) {
    if (index < 3) return Colors.amber.shade700;
    if (index < 10) return Colors.blue;
    if (index < 25) return Colors.green;
    return Colors.grey;
  }

  Color _getExchangeColor(String exchange) {
    switch (exchange.toUpperCase()) {
      case 'NASDAQ':
        return Colors.blue;
      case 'NYSE':
        return Colors.red;
      case 'OTC':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    if (score >= 0.4) return Colors.amber;
    return Colors.red;
  }

  void _showStockDetails(BuildContext context, TopStock stock) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getExchangeColor(stock.exchange),
                foregroundColor: Colors.white,
                child: Text(
                  stock.symbol.length > 2 
                      ? stock.symbol.substring(0, 2)
                      : stock.symbol,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.symbol,
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      stock.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Exchange', stock.exchange),
                _buildDetailRow('Current Price', stock.formattedPrice),
                _buildDetailRow('Market Cap', stock.formattedMarketCap),
                _buildDetailRow('AI Score', stock.formattedScore),
                const SizedBox(height: 16),
                const Text(
                  'AI Analysis:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stock.reasoning.isNotEmpty 
                        ? stock.reasoning 
                        : 'No specific analysis available.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// Extension to add gold color
extension GoldColor on Colors {
  static MaterialColor get gold => const MaterialColor(
        0xFFFFD700,
        <int, Color>{
          50: Color(0xFFFFFDF7),
          100: Color(0xFFFEF7E0),
          200: Color(0xFFFEF0C7),
          300: Color(0xFFFDE68A),
          400: Color(0xFFFCD34D),
          500: Color(0xFFFBBF24),
          600: Color(0xFFF59E0B),
          700: Color(0xFFD97706),
          800: Color(0xFFB45309),
          900: Color(0xFF92400E),
        },
      );
}
