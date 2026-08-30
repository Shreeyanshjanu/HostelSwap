// lib/screens/test_connection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../services/api_service.dart';

class TestConnectionScreen extends ConsumerStatefulWidget {
  const TestConnectionScreen({super.key});

  @override
  ConsumerState<TestConnectionScreen> createState() =>
      _TestConnectionScreenState();
}

class _TestConnectionScreenState extends ConsumerState<TestConnectionScreen> {
  final ApiService _apiService =
      ApiService(); // "" ONE instance, headers managed here

  String _status = '⏳ Not tested';
  String _response = '';
  bool _isLoading = false;

  // ============ TEST 1: Health Check ============
  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = '⏳ Testing...';
      _response = '';
    });

    try {
      final isHealthy = await _apiService.healthCheck();

      if (isHealthy) {
        setState(() {
          _status = '"" Connected!';
          _response =
              '''
📡 Backend is healthy
🔄 Status: Connected
🔗 URL: ${ApiConfig.baseUrl}
          ''';
        });
      } else {
        setState(() {
          _status = ' Failed';
          _response = 'Backend returned non-200 status.';
        });
      }
    } catch (e) {
      setState(() {
        _status = ' Error';
        _response =
            'Error: $e\n\nMake sure:\n• Backend is running\n• ngrok is running\n• URL is correct in api_config.dart';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============ TEST 2: Chatbot ============
  Future<void> _testChatbot() async {
    setState(() {
      _isLoading = true;
      _status = '⏳ Testing Chatbot...';
      _response = '';
    });

    try {
      final result = await _apiService.sendChatMessage(
        'I have BH-2 Non-AC 3-seater, want BH-1 AC 2-seater',
        '2024CS101',
      );

      setState(() {
        _status = '"" Chatbot Working!';
        _response =
            '''
📝 Intent: ${result['intent']}
📊 Parsed Data:
${_formatJson(result['parsed_data'])}
📩 Message: ${result['message']}
        ''';
      });
    } catch (e) {
      setState(() {
        _status = ' Chatbot Failed';
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============ TEST 3: RAG ============
  Future<void> _testRAG() async {
    setState(() {
      _isLoading = true;
      _status = '⏳ Testing RAG...';
      _response = '';
    });

    try {
      final result = await _apiService.askRAGQuery(
        'What is the deadline for hostel shift?',
      );

      setState(() {
        _status = '"" RAG Working!';
        _response =
            '''
📖 Answer: ${result['answer']}
📎 Source: ${result['source'] ?? 'No source available'}
📊 Confidence: ${(result['confidence'] * 100).toStringAsFixed(1)}%
🔍 Escalate: ${result['should_escalate'] ? 'Yes' : 'No'}
🌐 Language: ${result['language']}
        ''';
      });
    } catch (e) {
      setState(() {
        _status = ' RAG Failed';
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatJson(dynamic data) {
    if (data == null) return 'No data';
    try {
      return JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔗 Test Connection'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _testConnection,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Backend URL Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📡 Backend Configuration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ApiConfig.baseUrl,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Connection Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _status.contains('""')
                            ? Colors.green.shade50
                            : (_status.contains('')
                                  ? Colors.red.shade50
                                  : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _status.contains('""')
                              ? Colors.green.shade200
                              : (_status.contains('')
                                    ? Colors.red.shade200
                                    : Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _status,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _status.contains('""')
                                  ? Colors.green.shade700
                                  : (_status.contains('')
                                        ? Colors.red.shade700
                                        : Colors.grey.shade700),
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_response.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _response,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            height: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testConnection,
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text('Test Health Check'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testChatbot,
                  icon: const Icon(Icons.chat),
                  label: const Text('Test Chatbot (Swap Request)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testRAG,
                  icon: const Icon(Icons.search),
                  label: const Text('Test RAG (Policy Query)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Help Card
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Quick Tips',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Make sure backend is running (Terminal 1)\n'
                      '• Make sure ngrok is running (Terminal 2)\n'
                      '• Update api_config.dart with your ngrok URL\n'
                      '• Check Supabase credentials in app_constants.dart',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
