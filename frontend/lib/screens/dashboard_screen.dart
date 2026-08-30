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
  bool _isRefreshing = false;

  // 🔥 Tweak this single value to adjust card height across the whole grid.
  // Higher number = shorter cards (height = cell width ÷ this ratio).
  static const double _cardAspectRatioMobile = 0.6;
  static const double _cardAspectRatioDesktop = 0.6;

  @override
  void initState() {
    super.initState();
    // "" Realtime subscription is disabled to prevent infinite loops
    // _setupRealtimeSubscription();
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isRefreshing = true;
    });
    ref.invalidate(requestProvider);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isRefreshing = false;
    });
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

    // 🔥 UPDATED: Use a record instead of a Map
    final requestsAsync = ref.watch(
      requestProvider((
        hostel: _selectedHostel,
        ac: _selectedAc,
        seater: _selectedSeater,
      )),
    );

    final aspectRatio = ResponsiveHelper.isMobile(context)
        ? _cardAspectRatioMobile
        : _cardAspectRatioDesktop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Swap Requests'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshDashboard,
            tooltip: 'Refresh',
          ),
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
          IconButton(
            icon: const Icon(Icons.settings_ethernet),
            onPressed: () => Navigator.pushNamed(context, '/test'),
            tooltip: 'Test Connection',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
                Navigator.pushReplacementNamed(context, '/login');
              } else if (value == 'test') {
                Navigator.pushNamed(context, '/test');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                enabled: false,
                child: Text('Settings'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'test',
                child: Text('🔗 Test Connection'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: Colors.blue,
        child: Column(
          children: [
            FilterBar(
              onFilterChanged: (hostel, ac, seater) {
                setState(() {
                  _selectedHostel = hostel;
                  _selectedAc = ac;
                  _selectedSeater = seater;
                });
              },
            ),
            Expanded(
              child: requestsAsync.when(
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
                          Text(
                            'Or tap refresh to check again',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/create-request'),
                            icon: const Icon(Icons.add),
                            label: const Text('Post a Request'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _refreshDashboard,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Refresh'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
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
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        return RequestCard(request: requests[index]);
                      },
                    ),
                  );
                },
                loading: () {
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveHelper.getCrossAxisCount(
                        context,
                      ),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspectRatio,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => const LoadingShimmer(),
                  );
                },
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
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            err.toString(),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshDashboard,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/chatbot'),
            child: SizedBox(
              width: 110,
              height: 110,
              child: Lottie.asset(
                'assets/icons/chatbot.json',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 0),
          FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/create-request'),
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
