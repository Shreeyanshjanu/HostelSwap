import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';
import '../widgets/request_card.dart';
import '../widgets/filter_bar.dart';
import '../widgets/loading_shimmer.dart';
import '../utils/responsive_helper.dart';
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _selectedHostel;
  bool? _selectedAc;
  int? _selectedSeater;

  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);

      if (user != null) {
        ref
            .read(requestServiceProvider)
            .subscribeToRequests(
              onUpdate: (requests) {
                ref.invalidate(requestProvider);
              },
              gender: user.gender,
              userId: user.collegeId,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    final requestsAsync = ref.watch(
      requestProvider({
        'hostel': _selectedHostel,
        'ac': _selectedAc,
        'seater': _selectedSeater,
      }),
    );

    return Scaffold(
      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        title: const Text('Find Swap Requests'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        actions: [
          // My Requests
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.pushNamed(context, '/my-requests');
            },
            tooltip: 'My Requests',
          ),

          // Profile / Logout
          PopupMenuButton<String>(
            // 👤 Lottie user animation
            icon: SizedBox(
              width: 40,
              height: 40,
              child: Lottie.asset(
                'assets/icons/user.json',
                fit: BoxFit.contain,
              ),
            ),

            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();

                Navigator.pushReplacementNamed(context, '/login');
              }
            },

            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                enabled: false,
                child: Text('User'),
              ),

              const PopupMenuDivider(),

              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: Column(
        children: [
          // ========================================================
          // FILTER BAR
          // ========================================================
          FilterBar(
            onFilterChanged: (hostel, ac, seater) {
              setState(() {
                _selectedHostel = hostel;
                _selectedAc = ac;
                _selectedSeater = seater;
              });
            },
          ),

          // ========================================================
          // REQUEST GRID
          // ========================================================
          Expanded(
            child: requestsAsync.when(
              // ====================================================
              // DATA
              // ====================================================
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'No requests found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),

                        const SizedBox(height: 8),

                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/create-request');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Post a Request'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(12.0),

                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveHelper.getCrossAxisCount(
                        context,
                      ),

                      crossAxisSpacing: 16,

                      mainAxisSpacing: 16,

                      childAspectRatio: ResponsiveHelper.isMobile(context)
                          ? 0.75
                          : 0.7,
                    ),

                    itemCount: requests.length,

                    itemBuilder: (context, index) {
                      return RequestCard(request: requests[index]);
                    },
                  ),
                );
              },

              // ====================================================
              // LOADING
              // ====================================================
              loading: () {
                return GridView.builder(
                  padding: const EdgeInsets.all(12),

                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveHelper.getCrossAxisCount(context),

                    crossAxisSpacing: 16,

                    mainAxisSpacing: 16,

                    childAspectRatio: ResponsiveHelper.isMobile(context)
                        ? 0.75
                        : 0.7,
                  ),

                  itemCount: 6,

                  itemBuilder: (context, index) {
                    return const LoadingShimmer();
                  },
                );
              },

              // ====================================================
              // ERROR
              // ====================================================
              error: (err, stack) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade400,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Error loading requests',
                        style: TextStyle(color: Colors.red.shade400),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        err.toString(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ============================================================
      // CHATBOT + POST REQUEST
      // ============================================================
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ========================================================
          // CHATBOT LOTTIE
          // ========================================================
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/chatbot');
            },

            child: SizedBox(
              // 🔥 CHANGE THESE TWO VALUES TO ADJUST CHATBOT SIZE
              width: 110,
              height: 110,

              child: Lottie.asset(
                'assets/icons/chatbot.json',

                fit: BoxFit.contain,
              ),
            ),
          ),

          // ========================================================
          // GAP BETWEEN CHATBOT AND POST REQUEST
          // ========================================================
          const SizedBox(height: 0),

          // ========================================================
          // POST REQUEST BUTTON
          // ========================================================
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/create-request');
            },

            icon: const Icon(Icons.add),

            label: const Text('Post Request'),

            backgroundColor: Colors.blue,

            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
