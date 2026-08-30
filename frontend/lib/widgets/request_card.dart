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

    // Mac-style container (Fixed width, auto height)
    return Container(
      width:
          150, // 🔥 was 50 (too small to fit text) — tune this value to taste
      margin: const EdgeInsets.symmetric(
        vertical: 8,
      ), // Optional vertical margin
      decoration: BoxDecoration(
        color: const Color(0xFF011522), // Dark background
        borderRadius: BorderRadius.circular(8), // Rounded corners
      ),
      child: Column(
        // Key: makes height adjust to content
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. The 3 dots tool section
          Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                _buildCircle(const Color(0xFFFF605C)), // Red
                const SizedBox(width: 8),
                _buildCircle(const Color(0xFFFFBD44)), // Yellow
                const SizedBox(width: 8),
                _buildCircle(const Color(0xFF00CA4E)), // Green
              ],
            ),
          ),

          // 2. Main content section
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Applied Badge
                if (request.hasApplied)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Applied',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                if (isOwnRequest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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

                // Room details (Adjusted colors for dark background)
                Text(
                  'Current:',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                Text(
                  request.roomDisplay,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Arrow icon (Changed to light color for visibility)
                const Icon(Icons.arrow_downward, color: Colors.white70),
                const SizedBox(height: 8),

                Text(
                  'Wants:',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                Text(
                  request.desiredDisplay,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),

                // Tighter gap above the action button
                const SizedBox(height: 10),

                // Action button
                if (!isOwnRequest)
                  _buildInterestButton(ref, context)
                else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/applicants',
                        arguments: request.id,
                      );
                    },
                    child: const Text(
                      'View Applicants',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(
                        double.infinity,
                        32,
                      ), // 🔥 consistent with Express Interest
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for the 3 dots
  Widget _buildCircle(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildInterestButton(WidgetRef ref, BuildContext context) {
    final interestAsync = ref.watch(interestProvider(request.id));

    return interestAsync.when(
      data: (hasApplied) {
        return ElevatedButton(
          onPressed: hasApplied ? null : () => _expressInterest(ref, context),
          child: Text(
            hasApplied ? '"" Applied' : 'Express Interest',
            style: const TextStyle(fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasApplied ? Colors.green : Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 32),
            padding: const EdgeInsets.symmetric(vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      },
      loading: () => SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 32),
            padding: const EdgeInsets.symmetric(vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (err, stack) => ElevatedButton(
        onPressed: () => _expressInterest(ref, context),
        child: const Text('Express Interest', style: TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 32),
          padding: const EdgeInsets.symmetric(vertical: 6),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  void _expressInterest(WidgetRef ref, BuildContext context) async {
    final user = ref.read(authProvider);
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    try {
      await ref.read(
        expressInterestProvider({
          'requestId': request.id,
          'applicantId': user.collegeId,
        }).future,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('"" Interest expressed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(interestProvider(request.id));
        ref.invalidate(requestProvider);
      }
    } catch (e) {
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
