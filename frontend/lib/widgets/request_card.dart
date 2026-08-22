import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/request_provider.dart';
import '../models/request_model.dart';
import '../providers/interest_provider.dart';
import '../providers/auth_provider.dart';

class RequestCard extends ConsumerWidget {
  final RequestModel request;

  const RequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isOwnRequest = user != null && user.collegeId == request.userId;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Applied Badge
            if (request.hasApplied)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Applied', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            if (isOwnRequest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Your Request',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),

            // Room details
            Text('Current:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text(
              request.roomDisplay,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            
            const Icon(Icons.arrow_downward, color: Colors.blue),
            const SizedBox(height: 8),
            
            Text('Wants:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text(
              request.desiredDisplay,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            
            const Spacer(),
            
            // Action button
            if (!isOwnRequest)
              _buildInterestButton(ref, context)
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/applicants', arguments: request.id);
                },
                child: const Text('View Applicants'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestButton(WidgetRef ref, BuildContext context) {
    final interestAsync = ref.watch(interestProvider(request.id));

    return interestAsync.when(
      data: (hasApplied) {
        return ElevatedButton(
          onPressed: hasApplied
              ? null
              : () => _expressInterest(ref, context),
          child: Text(hasApplied ? '✅ Applied' : 'Express Interest'),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasApplied ? Colors.green : Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
          ),
        );
      },
      loading: () => ElevatedButton(
        onPressed: null,
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, stack) => ElevatedButton(
        onPressed: () => _expressInterest(ref, context),
        child: const Text('Express Interest'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }

  void _expressInterest(WidgetRef ref, BuildContext context) async {
    final user = ref.read(authProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    try {
      await ref.read(expressInterestProvider({
        'requestId': request.id,
        'applicantId': user.collegeId,
      }).future);

      // ✅ FIXED: Use context.mounted instead of mounted
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Interest expressed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(interestProvider(request.id));
        ref.invalidate(requestProvider);
      }
    } catch (e) {
      // ✅ FIXED: Use context.mounted instead of mounted
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to express interest: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}