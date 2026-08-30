import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart'; // "" Added
import '../services/supabase_service.dart';
import '../config/app_constants.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
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
            tooltip: 'Create New Request',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userRequestsProvider);
              ref.invalidate(requestProvider); // "" Added
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No requests posted yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first request',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/create-request'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final activeRequests = requests
              .where((r) => r.status == 'active')
              .toList();
          final otherRequests = requests
              .where((r) => r.status != 'active')
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userRequestsProvider);
              ref.invalidate(requestProvider); // "" Added
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeRequests.isNotEmpty) ...[
                  const Text(
                    'Active Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...activeRequests.map(
                    (request) => _buildRequestCard(request, isActive: true),
                  ),
                  const SizedBox(height: 24),
                ],
                if (otherRequests.isNotEmpty) ...[
                  const Text(
                    'Completed / Withdrawn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...otherRequests.map(
                    (request) => _buildRequestCard(request, isActive: false),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your requests...'),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Error loading requests',
                style: TextStyle(color: Colors.red.shade400, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(userRequestsProvider);
                  ref.invalidate(requestProvider); // "" Added
                },
                child: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(request, {required bool isActive}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATUS BADGE
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(request.createdAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ROOM DETAILS
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

            const SizedBox(height: 16),

            // ACTION BUTTONS
            if (isActive) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/applicants',
                          arguments: request.id,
                        );
                      },
                      icon: const Icon(Icons.people, size: 8),
                      label: const Text('View Applicants'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _withdrawRequest(request.id),
                      icon: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Withdraw'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reactivateRequest(request),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Repost Request'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
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

  // ============================================================
  // WITHDRAW REQUEST
  // ============================================================
  void _withdrawRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Request'),
        content: const Text(
          'Are you sure you want to withdraw this request?\n\n'
          'This action cannot be undone. The request will no longer be visible to other students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _supabaseService.updateRequestStatus(requestId, 'withdrawn');

      // Refresh the list
      ref.invalidate(userRequestsProvider);
      ref.invalidate(requestProvider); // "" Added – updates dashboard

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('"" Request withdrawn successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Failed to withdraw request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  // ============================================================
  // REACTIVATE REQUEST (Repost)
  // ============================================================
  void _reactivateRequest(request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repost Request'),
        content: const Text(
          'This will create a new active request with the same room details.\n\n'
          'Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Repost', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final newRequestData = {
        'user_id': request.userId,
        'current_hostel': request.currentHostel,
        'current_ac': request.currentAc,
        'current_seater': request.currentSeater,
        'desired_hostel': request.desiredHostel,
        'desired_ac': request.desiredAc,
        'desired_seater': request.desiredSeater,
        'status': 'active',
      };

      await _supabaseService.createRequest(newRequestData);

      ref.invalidate(userRequestsProvider);
      ref.invalidate(requestProvider); // "" Added – updates dashboard

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('"" Request reposted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Failed to repost request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
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
