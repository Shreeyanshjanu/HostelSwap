import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        ref.read(requestServiceProvider).subscribeToRequests(
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
    final requestsAsync = ref.watch(requestProvider(
      {
        'hostel': _selectedHostel,
        'ac': _selectedAc,
        'seater': _selectedSeater,
      },
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Swap Requests'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => Navigator.pushNamed(context, '/chatbot'),
            tooltip: 'Chatbot',
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => Navigator.pushNamed(context, '/my-requests'),
            tooltip: 'My Requests',
          ),
          // ✅ FIXED: Added explicit type parameter <String>
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // ✅ FIXED: Added explicit type <String>
              const PopupMenuItem<String>(
                value: 'profile',
                enabled: false, // Makes it non-selectable
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
      body: Column(
        children: [
          // Filter Bar
          FilterBar(
            onFilterChanged: (hostel, ac, seater) {
              setState(() {
                _selectedHostel = hostel;
                _selectedAc = ac;
                _selectedSeater = seater;
              });
            },
          ),
          // Request Grid
          Expanded(
            child: requestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No requests found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/create-request'),
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
                      crossAxisCount: ResponsiveHelper.getCrossAxisCount(context),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: ResponsiveHelper.isMobile(context) ? 0.75 : 0.7,
                    ),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      return RequestCard(request: requests[index]);
                    },
                  ),
                );
              },
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveHelper.getCrossAxisCount(context),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: ResponsiveHelper.isMobile(context) ? 0.75 : 0.7,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => const LoadingShimmer(),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text('Error loading requests', style: TextStyle(color: Colors.red.shade400)),
                    const SizedBox(height: 8),
                    Text(
                      err.toString(),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-request'),
        icon: const Icon(Icons.add),
        label: const Text('Post Request'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}