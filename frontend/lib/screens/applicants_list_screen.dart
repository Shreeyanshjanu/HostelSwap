import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/interest_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/interest_model.dart';

class ApplicantsListScreen extends ConsumerStatefulWidget {
  const ApplicantsListScreen({super.key});

  @override
  ConsumerState<ApplicantsListScreen> createState() =>
      _ApplicantsListScreenState();
}

class _ApplicantsListScreenState extends ConsumerState<ApplicantsListScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _requestId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get request ID from arguments
    if (_requestId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _requestId = args;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_requestId == null) {
      return const Scaffold(
        body: Center(child: Text('No request ID provided')),
      );
    }

    final applicantsAsync = ref.watch(applicantsProvider(_requestId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: applicantsAsync.when(
        data: (applicants) {
          if (applicants.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No applicants yet', style: TextStyle(fontSize: 18)),
                  Text('Waiting for students to show interest'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              final interest = applicants[index];
              return _buildApplicantCard(interest);
            },
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

  Widget _buildApplicantCard(InterestModel interest) {
    final applicant = interest.applicant;
    if (applicant == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    applicant.name.isNotEmpty
                        ? applicant.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'ID: ${applicant.collegeId}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _showContact(interest),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Show Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _finalizeSwap(interest),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Finalize'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showContact(InterestModel interest) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final contacts = await _apiService.showContact(
        interest.requestId,
        user.collegeId,
        interest.applicantId,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Contact Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📱 Requester: ${contacts['requester_phone'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('📱 Applicant: ${contacts['applicant_phone'] ?? 'N/A'}'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '💡 Connect on WhatsApp to finalize the swap details.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to show contact: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _finalizeSwap(InterestModel interest) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize Swap'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm swap with ${interest.applicant?.name ?? 'this student'}?',
            ),
            const SizedBox(height: 8),
            const Text(
              'They will receive a confirmation request.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
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
                await _apiService.finalizeSwap(
                  interest.requestId,
                  user.collegeId,
                  interest.applicantId,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('"" Swap finalized! Applicant notified.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to finalize: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              setState(() => _isLoading = false);
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}
