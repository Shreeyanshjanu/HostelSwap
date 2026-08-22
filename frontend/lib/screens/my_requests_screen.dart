import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';
import '../services/api_service.dart';
import '../config/app_constants.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    final requestsAsync = ref.watch(userRequestsProvider(user.collegeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/create-request'),
          ),
        ],
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No requests posted yet', style: TextStyle(fontSize: 18)),
                  Text('Tap + to create your first request', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final activeRequests = requests.where((r) => r.status == 'active').toList();
          final otherRequests = requests.where((r) => r.status != 'active').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeRequests.isNotEmpty) ...[
                const Text(
                  'Active Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...activeRequests.map((request) => _buildRequestCard(request)),
                const SizedBox(height: 24),
              ],
              if (otherRequests.isNotEmpty) ...[
                const Text(
                  'Completed / Withdrawn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...otherRequests.map((request) => _buildRequestCard(request)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text('Error: $err', style: TextStyle(color: Colors.red.shade400)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: request.status == 'active' ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                request.status.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            
            // Room details
            Text('Current:', style: TextStyle(color: Colors.grey.shade600)),
            Text(
              request.roomDisplay,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            
            const Icon(Icons.arrow_downward, color: Colors.blue),
            const SizedBox(height: 8),
            
            Text('Wants:', style: TextStyle(color: Colors.grey.shade600)),
            Text(
              request.desiredDisplay,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            
            // Created at
            Text(
              'Posted: ${_formatDate(request.createdAt)}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            if (request.status == 'active') ...[
              Row(
                children: [
                  // View Applicants
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/applicants',
                          arguments: request.id,
                        );
                      },
                      icon: const Icon(Icons.people, size: 16),
                      label: const Text('View Applicants'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Withdraw
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _withdrawRequest(request.id),
                      icon: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close, size: 16),
                      label: const Text('Withdraw'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _withdrawRequest(String requestId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Request'),
        content: const Text('Are you sure you want to withdraw this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _apiService.withdrawRequest(requestId);
                ref.invalidate(userRequestsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request withdrawn successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to withdraw: $e'), backgroundColor: Colors.red),
                  );
                }
              }
              setState(() => _isLoading = false);
            },
            child: const Text('Withdraw', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}