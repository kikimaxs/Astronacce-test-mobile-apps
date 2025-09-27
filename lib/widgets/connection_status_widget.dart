import 'package:flutter/material.dart';
import '../config/api_config.dart';

class ConnectionStatusWidget extends StatefulWidget {
  const ConnectionStatusWidget({Key? key}) : super(key: key);

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  String _currentEndpoint = 'Checking...';
  bool _isLoading = true;
  Map<String, dynamic>? _testResults;

  @override
  void initState() {
    super.initState();
    _checkEndpoint();
  }

  Future<void> _checkEndpoint() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Test semua endpoint
      final testResults = await ApiConfig.testAllEndpoints();
      final endpoint = await ApiConfig.baseUrl;
      
      setState(() {
        _testResults = testResults;
        _currentEndpoint = endpoint.contains('vercel.app') 
            ? 'Vercel (Production)' 
            : 'Localhost (Development)';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentEndpoint = 'Connection Error';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshEndpoint() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final endpoint = await ApiConfig.refreshEndpoint();
      final testResults = await ApiConfig.testAllEndpoints();
      
      setState(() {
        _testResults = testResults;
        _currentEndpoint = endpoint.contains('vercel.app') 
            ? 'Vercel (Production)' 
            : 'Localhost (Development)';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Endpoint refreshed: $_currentEndpoint'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _currentEndpoint = 'Connection Error';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh endpoint: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDebugInfo() {
    if (_testResults == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Endpoint: $_currentEndpoint'),
              const SizedBox(height: 16),
              const Text('Endpoint Test Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._testResults!.entries.map((entry) {
                final name = entry.key;
                final data = entry.value as Map<String, dynamic>;
                final url = data['url'] as String;
                final available = data['available'] as bool;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        available ? Icons.check_circle : Icons.error,
                        color: available ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(url, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _currentEndpoint.contains('Vercel') 
            ? Colors.green.withOpacity(0.1)
            : _currentEndpoint.contains('Localhost')
                ? Colors.orange.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _currentEndpoint.contains('Vercel') 
              ? Colors.green
              : _currentEndpoint.contains('Localhost')
                  ? Colors.orange
                  : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _currentEndpoint.contains('Vercel') 
                  ? Icons.cloud_done
                  : _currentEndpoint.contains('Localhost')
                      ? Icons.computer
                      : Icons.error,
              size: 16,
              color: _currentEndpoint.contains('Vercel') 
                  ? Colors.green
                  : _currentEndpoint.contains('Localhost')
                      ? Colors.orange
                      : Colors.red,
            ),
          const SizedBox(width: 6),
          Text(
            _currentEndpoint,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _currentEndpoint.contains('Vercel') 
                  ? Colors.green.shade700
                  : _currentEndpoint.contains('Localhost')
                      ? Colors.orange.shade700
                      : Colors.red.shade700,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _refreshEndpoint,
            child: Icon(
              Icons.refresh,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _showDebugInfo,
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}