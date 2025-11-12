import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'driver_profile.dart';
import 'trip_details.dart';

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  Map<String, dynamic>? _driverData;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userProfile != null) {
      _driverData = authProvider.userProfile;
    }

    setState(() => _isLoading = false);
  }

  int get _completedDeliveries => _driverData?['totalTrips'] ?? 0;
  double get _fuelEfficiency => (_driverData?['fuelEfficiency'] ?? 25.0);
  String get _driverName => _driverData?['name'] ?? 'Driver';

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated || !authProvider.isDriver) {
          return const Scaffold(
            body: Center(
              child: Text('Please log in as a driver to view this page'),
            ),
          );
        }

        final userProfile = authProvider.userProfile;
        if (userProfile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_driverData != userProfile) {
          _driverData = userProfile;
        }

        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;
        final onPrimary = theme.colorScheme.onPrimary;
        final secondary = theme.colorScheme.secondary;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            forceMaterialTransparency: true,
            toolbarHeight: 100,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Image.asset('assets/logo.png', height: 100),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.account_circle, color: primary, size: 28),
                tooltip: 'Menu',
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DriverProfilePage(),
                        ),
                      );
                      break;
                    case 'logout':
                      _logout();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 8),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadDriverData,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(10.0),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 1.0,
                        ),
                        child: Text(
                          'Welcome, ${_driverName}!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Summary cards
                      Row(
                        children: [
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('trips')
                                  .where(
                                    'driverId',
                                    isEqualTo: userProfile['uid'],
                                  )
                                  .snapshots(),
                              builder: (context, snapshot) {
                                int tripCount = 0;
                                if (snapshot.hasData) {
                                  final activeTrips = snapshot.data!.docs.where(
                                    (doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final status =
                                          data['status'] ?? 'pending';
                                      return [
                                        'pending',
                                        'assigned',
                                        'in_progress',
                                      ].contains(status);
                                    },
                                  );
                                  tripCount = activeTrips.length;
                                }
                                return _buildStatCard(
                                  context,
                                  'Today\'s Trips',
                                  '$tripCount',
                                  Icons.calendar_today,
                                  primary,
                                  onPrimary,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Total Trips',
                              '$_completedDeliveries',
                              Icons.check_circle_outline,
                              secondary,
                              Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Fuel Eff.',
                              '${_fuelEfficiency.toStringAsFixed(1)} km/L',
                              Icons.local_gas_station,
                              secondary,
                              Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Performance details coming soon',
                                  ),
                                ),
                              ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 12.0,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 36, color: Colors.amber),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Performance Rating',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${(_driverData?['rating'] ?? 5.0).toStringAsFixed(1)} ⭐ (Excellent)',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (_driverData?['isActive'] ?? false)
                                        ? Colors.green
                                        : Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (_driverData?['isActive'] ?? false)
                                        ? 'Active'
                                        : 'Inactive',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Today\'s Trips',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('trips')
                            .where('driverId', isEqualTo: userProfile['uid'])
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Error loading trips: ${snapshot.error}',
                                ),
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }

                          // Filter and sort trips client-side for active statuses
                          final allTrips = snapshot.data?.docs ?? [];
                          final activeTrips = allTrips.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final status = data['status'] ?? 'pending';
                            return [
                              'pending',
                              'assigned',
                              'in_progress',
                            ].contains(status);
                          }).toList();

                          activeTrips.sort((a, b) {
                            final aData = a.data() as Map<String, dynamic>;
                            final bData = b.data() as Map<String, dynamic>;
                            final aTime = aData['createdAt'] as Timestamp?;
                            final bTime = bData['createdAt'] as Timestamp?;

                            if (aTime == null && bTime == null) return 0;
                            if (aTime == null) return 1;
                            if (bTime == null) return -1;

                            return bTime.compareTo(aTime);
                          });

                          if (activeTrips.isEmpty) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.local_shipping_outlined,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'No assigned trips today',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'New trips will appear here when assigned',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activeTrips.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final tripDoc = activeTrips[idx];
                              final trip =
                                  tripDoc.data() as Map<String, dynamic>;
                              final tripId = tripDoc.id;

                              final createdAt = trip['createdAt'] as Timestamp?;
                              final timeStr = createdAt != null
                                  ? '${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')}'
                                  : 'N/A';

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () =>
                                      _showTripDetails({'id': tripId, ...trip}),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    leading: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: primary.withOpacity(
                                        0.12,
                                      ),
                                      child: Text(
                                        '${idx + 1}',
                                        style: TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${trip['pickup'] ?? 'Unknown'} → ${trip['destination'] ?? 'Unknown'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Status: ${trip['status'] ?? 'pending'}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                  trip['status'],
                                                ).withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${trip['status'] ?? 'pending'} • $timeStr',
                                                style: TextStyle(
                                                  color: _getStatusColor(
                                                    trip['status'],
                                                  ),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (trip['notes'] != null &&
                                                (trip['notes'] as String?)
                                                        ?.isNotEmpty ==
                                                    true)
                                              const Text(
                                                'Has notes',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    final safeStatus = status ?? 'pending';
    switch (safeStatus.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'assigned':
        return Colors.blue;
      case 'pending':
      case 'scheduled':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  void _showTripDetails(Map<String, dynamic> trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TripDetailsPage(),
        settings: RouteSettings(
          arguments: {'id': trip['id']?.toString(), ...trip},
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color bg,
    Color fg,
  ) {
    final theme = Theme.of(context);
    final labelStyle =
        theme.textTheme.bodySmall?.copyWith(color: Colors.black87) ??
        const TextStyle(fontSize: 12, color: Colors.black87);
    final valueStyle =
        theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: fg,
        ) ??
        TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: bg.withOpacity(0.12),
                child: Icon(icon, color: bg, size: 20),
              ),
              const SizedBox(height: 10),
              Text(label, style: labelStyle, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(value, style: valueStyle, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();

                if (mounted) {
                  Navigator.of(context).pop();

                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
