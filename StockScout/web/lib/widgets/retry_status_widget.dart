import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class RetryStatusWidget extends StatelessWidget {
  const RetryStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        if (apiService.isRetrying) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              border: Border.all(color: Colors.orange[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Connecting to server... (Attempt ${apiService.retryCount}/3)',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (apiService.error != null) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    apiService.error!,
                    style: TextStyle(
                      color: Colors.red[800],
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Trigger a refresh which will retry automatically
                    Provider.of<ApiService>(context, listen: false).getAllStocks();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // No error, no retry - show nothing (success state)
        return const SizedBox.shrink();
      },
    );
  }
}

/// Loading state widget with retry awareness
class LoadingWithRetryWidget extends StatelessWidget {
  final String message;
  
  const LoadingWithRetryWidget({
    super.key,
    this.message = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        if (apiService.isRetrying) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reconnecting... (Attempt ${apiService.retryCount}/3)',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we establish connection',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        if (apiService.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return child ?? const SizedBox.shrink();
      },
    );
  }
}