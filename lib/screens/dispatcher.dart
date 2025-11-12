import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class DispatcherPage extends StatefulWidget {
  const DispatcherPage({super.key});

  @override
  State<DispatcherPage> createState() => _DispatcherPageState();
}

class _DispatcherPageState extends State<DispatcherPage> {
  int _selectedIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();
  String _tripFilter = 'All';
  String _tripSearch = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: (_selectedIndex == 1 || _selectedIndex == 3)
          ? _buildFAB()
          : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Dispatcher Dashboard'),
      backgroundColor: Colors.black,
      foregroundColor: Colors.orange,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => _showNotifications(),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'profile', child: Text('Profile')),
            const PopupMenuItem(value: 'settings', child: Text('Settings')),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildTripsManagement();
      case 2:
        return _buildDriversManagement();
      case 3:
        return _buildVehiclesManagement();
      case 4:
        return _buildReports();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 16),
          _buildStatsCards(),
          const SizedBox(height: 16),
          _buildRecentTrips(),
          const SizedBox(height: 16),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        String userName = 'Dispatcher';
        if (authProvider.userProfile is Map<String, dynamic>) {
          userName =
              (authProvider.userProfile as Map<String, dynamic>)['name'] ??
              'Dispatcher';
        }
        return Card(
          elevation: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active Trips',
            _getActiveTripsCount(),
            Icons.local_shipping,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Available Drivers',
            _getAvailableDriversCount(),
            Icons.people,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed Today',
            _getCompletedTodayCount(),
            Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, Widget count, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.orange, size: 32),
            const SizedBox(height: 8),
            count,
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getActiveTripsCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('status', isEqualTo: 'in_progress')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            '--',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return Text(
          '${snapshot.data!.docs.length}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        );
      },
    );
  }

  Widget _getAvailableDriversCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            '--',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return Text(
          '${snapshot.data!.docs.length}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        );
      },
    );
  }

  Widget _getCompletedTodayCount() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('status', isEqualTo: 'completed')
          .where(
            'updatedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('updatedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            '--',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return Text(
          '${snapshot.data!.docs.length}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        );
      },
    );
  }

  Widget _buildRecentTrips() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Trips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.trips
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading trips: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No trips yet',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          Text(
                            'Create your first trip to get started',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final trip =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    return _buildTripListItem(
                      trip,
                      snapshot.data!.docs[index].id,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripListItem(Map<String, dynamic> trip, String tripId) {
    final status = trip['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final createdAt = trip['createdAt'] as Timestamp?;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(_getStatusIcon(status), color: statusColor, size: 20),
      ),
      title: Text(
        'Trip #${tripId.substring(0, 8).toUpperCase()}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: ${status.toUpperCase()}'),
          if (createdAt != null)
            Text(
              'Created: ${DateFormat('MMM dd, HH:mm').format(createdAt.toDate())}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleTripAction(value, tripId),
        itemBuilder: (context) => [
          //const PopupMenuItem(value: 'view', child: Text('View Details')),
          const PopupMenuItem(value: 'edit', child: Text('Edit Trip')),
          if (status == 'pending')
            const PopupMenuItem(value: 'start', child: Text('Start Trip')),
          if (status == 'in_progress')
            const PopupMenuItem(
              value: 'complete',
              child: Text('Complete Trip'),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildActionButton(
                  'Create Trip',
                  Icons.add_circle_outline,
                  () => _showCreateTripDialog(),
                ),
                _buildActionButton(
                  'Assign Driver',
                  Icons.person_add,
                  () => _showAssignDriverDialog(),
                ),
                _buildActionButton(
                  'Track Vehicles',
                  Icons.location_on,
                  () => _showVehicleTracking(),
                ),
                _buildActionButton(
                  'Generate Report',
                  Icons.analytics,
                  () => setState(() => _selectedIndex = 4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.orange.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripsManagement() {
    return Column(
      children: [
        _buildTripsHeader(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('trips')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No trips found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a new trip to get started',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateTripDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Trip'),
                      ),
                    ],
                  ),
                );
              }

              final allTrips = snapshot.data!.docs;
              final filteredTrips = _filterTrips(allTrips);

              if (filteredTrips.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.filter_list_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No trips match your filter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try adjusting the filter criteria',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTrips.length,
                itemBuilder: (context, index) {
                  final doc = filteredTrips[index];
                  final trip = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _buildTripListItem(trip, doc.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTripsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _tripSearch = value),
                  decoration: const InputDecoration(
                    hintText: 'Search trips...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _tripFilter,
                onChanged: (value) => setState(() => _tripFilter = value!),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('In Progress'),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriversManagement() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No drivers registered yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Drivers will appear here once they register',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final driver = doc.data() as Map<String, dynamic>;
            driver['uid'] = doc.id;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildDriverListItem(driver),
            );
          },
        );
      },
    );
  }

  Widget _buildDriverListItem(Map<String, dynamic> driver) {
    final isActive = driver['isActive'] ?? false;
    final totalTrips = driver['totalTrips'] ?? 0;
    final rating = (driver['rating'] ?? 5.0).toDouble();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        child: Icon(Icons.person, color: isActive ? Colors.green : Colors.grey),
      ),
      title: Text(
        driver['name'] ?? 'Unknown Driver',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(driver['email'] ?? ''),
          Text('Trips: $totalTrips • Rating: ${rating.toStringAsFixed(1)}⭐'),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleDriverAction(value, driver),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'view', child: Text('View Profile')),
          const PopupMenuItem(value: 'assign', child: Text('Assign Trip')),
          PopupMenuItem(
            value: isActive ? 'deactivate' : 'activate',
            child: Text(isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesManagement() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No vehicles registered yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Add vehicles to start managing your fleet',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search vehicles...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: 'All',
                    items:
                        [
                              'All',
                              'Available',
                              'Assigned',
                              'Maintenance',
                              'Inactive',
                            ]
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            // Vehicles stats
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildVehicleStatCard(
                      'Total',
                      '${snapshot.data!.docs.length}',
                      Icons.directions_car,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVehicleStatCard(
                      'Available',
                      '${snapshot.data!.docs.where((doc) => (doc.data() as Map)['status'] == 'available').length}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVehicleStatCard(
                      'In Use',
                      '${snapshot.data!.docs.where((doc) => (doc.data() as Map)['status'] == 'assigned').length}',
                      Icons.local_shipping,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVehicleStatCard(
                      'Maintenance',
                      '${snapshot.data!.docs.where((doc) => (doc.data() as Map)['status'] == 'maintenance').length}',
                      Icons.build,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final vehicleDoc = snapshot.data!.docs[index];
                  final vehicle = vehicleDoc.data() as Map<String, dynamic>;
                  return _buildVehicleCard(vehicle, vehicleDoc.id);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehicleStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle, String vehicleId) {
    final status = vehicle['status'] ?? 'unknown';
    final isAvailable = status == 'available';
    final isAssigned = status == 'assigned';
    final isMaintenance = status == 'maintenance';

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    if (isAvailable) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isAssigned) {
      statusColor = Colors.orange;
      statusIcon = Icons.local_shipping;
    } else if (isMaintenance) {
      statusColor = Colors.red;
      statusIcon = Icons.build;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          vehicle['vehicleName'] ?? vehicle['model'] ?? 'Unknown Vehicle',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plate: ${vehicle['registrationNumber'] ?? vehicle['plateNumber'] ?? 'N/A'}',
            ),
            Text(
              'Type: ${vehicle['vehicleType'] ?? 'N/A'} • Capacity: ${vehicle['capacity'] ?? 0} tons',
            ),
            Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) =>
              _handleVehicleAction(value, vehicle, vehicleId),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit Vehicle')),
            if (isAvailable)
              const PopupMenuItem(
                value: 'assign',
                child: Text('Assign to Trip'),
              ),
            if (isAssigned)
              const PopupMenuItem(value: 'unassign', child: Text('Unassign')),
            PopupMenuItem(
              value: isMaintenance ? 'activate' : 'maintenance',
              child: Text(
                isMaintenance ? 'Mark Available' : 'Mark Maintenance',
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text(
                'Delete Vehicle',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReports() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics & Reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildTripsByStatusChart(),
          const SizedBox(height: 20),
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildTripsByStatusChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trips by Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trips')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final trips = snapshot.data!.docs;
                final statusCounts = <String, int>{};

                for (var doc in trips) {
                  final trip = doc.data() as Map<String, dynamic>;
                  final status = trip['status'] ?? 'pending';
                  statusCounts[status] = (statusCounts[status] ?? 0) + 1;
                }

                if (statusCounts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No data available'),
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: statusCounts.entries.map((entry) {
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: '${entry.key}\n${entry.value}',
                          color: _getStatusColor(entry.key),
                          radius: 60,
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('drivers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final drivers = snapshot.data!.docs;
                final totalDrivers = drivers.length;
                final activeDrivers = drivers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isActive'] ?? false;
                }).length;

                return Column(
                  children: [
                    _buildMetricRow('Total Drivers', '$totalDrivers'),
                    _buildMetricRow('Active Drivers', '$activeDrivers'),
                    _buildMetricRow(
                      'Driver Utilization',
                      totalDrivers > 0
                          ? '${((activeDrivers / totalDrivers) * 100).toStringAsFixed(1)}%'
                          : '0%',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: 'Trips',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Drivers'),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car),
          label: 'Vehicles',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Reports'),
      ],
    );
  }

  FloatingActionButton _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        if (_selectedIndex == 1) {
          _showCreateTripDialog();
        } else if (_selectedIndex == 3) {
          _showAddVehicleDialog(context);
        }
      },
      backgroundColor: Colors.orange,
      child: Icon(
        _selectedIndex == 1 ? Icons.add_road : Icons.add,
        color: Colors.white,
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  List<QueryDocumentSnapshot> _filterTrips(List<QueryDocumentSnapshot> trips) {
    return trips.where((doc) {
      final trip = doc.data() as Map<String, dynamic>;
      final status = trip['status'] ?? '';
      final tripId = doc.id;

      if (_tripFilter != 'All' && status != _tripFilter) {
        return false;
      }

      if (_tripSearch.isNotEmpty) {
        return tripId.toLowerCase().contains(_tripSearch.toLowerCase()) ||
            status.toLowerCase().contains(_tripSearch.toLowerCase());
      }

      return true;
    }).toList();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        _showProfile();
        break;
      case 'settings':
        _showSettings();
        break;
      case 'logout':
        _logout();
        break;
    }
  }

  void _handleTripAction(String action, String tripId) {
    switch (action) {
      case 'view':
        _viewTripDetails(tripId);
        break;
      case 'edit':
        _editTrip(tripId);
        break;
      case 'start':
        _updateTripStatus(tripId, 'in_progress');
        break;
      case 'complete':
        _updateTripStatus(tripId, 'completed');
        break;
    }
  }

  void _handleDriverAction(String action, Map<String, dynamic> driver) {
    switch (action) {
      case 'view':
        _viewDriverProfile(driver);
        break;
      case 'assign':
        _assignTripToDriver(driver);
        break;
      case 'activate':
      case 'deactivate':
        _toggleDriverStatus(driver);
        break;
    }
  }

  void _handleVehicleAction(
    String action,
    Map<String, dynamic> vehicle,
    String vehicleId,
  ) {
    switch (action) {
      case 'view':
        _viewVehicleDetails(vehicle, vehicleId);
        break;
      case 'edit':
        _editVehicle(vehicle, vehicleId);
        break;
      case 'assign':
        _assignVehicleToTrip(vehicle, vehicleId);
        break;
      case 'unassign':
        _unassignVehicle(vehicle, vehicleId);
        break;
      case 'maintenance':
        _scheduleVehicleMaintenance(vehicle, vehicleId);
        break;
      case 'activate':
        _markVehicleAvailable(vehicle, vehicleId);
        break;
      case 'delete':
        _deleteVehicle(vehicle, vehicleId);
        break;
    }
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications, color: Colors.orange),
            SizedBox(width: 8),
            Text('Notifications'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('trips')
                .where(
                  'status',
                  whereIn: ['pending', 'in_progress', 'completed'],
                )
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No recent notifications',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final trips = snapshot.data!.docs;
              return ListView.separated(
                itemCount: trips.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final trip = trips[index].data() as Map<String, dynamic>;
                  final status = trip['status'] ?? 'unknown';
                  final pickup = trip['pickup'] ?? 'Unknown';
                  final destination = trip['destination'] ?? 'Unknown';

                  IconData icon;
                  Color iconColor;
                  String message;

                  switch (status) {
                    case 'pending':
                      icon = Icons.pending_actions;
                      iconColor = Colors.orange;
                      message = 'New trip created: $pickup → $destination';
                      break;
                    case 'in_progress':
                      icon = Icons.local_shipping;
                      iconColor = Colors.blue;
                      message = 'Trip in progress: $pickup → $destination';
                      break;
                    case 'completed':
                      icon = Icons.check_circle;
                      iconColor = Colors.green;
                      message = 'Trip completed: $pickup → $destination';
                      break;
                    default:
                      icon = Icons.info;
                      iconColor = Colors.grey;
                      message = 'Trip update: $pickup → $destination';
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.1),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    title: Text(message, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      _formatNotificationTime(trip['createdAt']),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _viewTripDetails(trips[index].id);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatNotificationTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown time';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showCreateTripDialog() {
    final pickupController = TextEditingController();
    final destinationController = TextEditingController();
    final notesController = TextEditingController();
    final titleController = TextEditingController();
    String? selectedDriverId;
    String? selectedVehicleId;
    List<Map<String, String>> stops = [];

    void addStop() {
      if (stops.length < 4) {
        stops.add({'name': '', 'address': ''});
      }
    }

    void removeStop(int index) {
      if (stops.length > index) {
        stops.removeAt(index);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Trip Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pickupController,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag),
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('drivers')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final drivers = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: selectedDriverId,
                      decoration: const InputDecoration(
                        labelText: 'Assign Driver',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: drivers.map((driver) {
                        final data = driver.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: driver.id,
                          child: Text(data['name'] ?? 'Unknown Driver'),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedDriverId = value),
                    );
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('vehicles')
                      .where('status', isEqualTo: 'available')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final vehicles = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: selectedVehicleId,
                      decoration: const InputDecoration(
                        labelText: 'Assign Vehicle',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_shipping),
                      ),
                      items: vehicles.map((vehicle) {
                        final data = vehicle.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: vehicle.id,
                          child: Text(
                            '${data['vehicleName'] ?? data['model'] ?? 'Unknown'} - ${data['registrationNumber'] ?? data['plateNumber'] ?? 'No Plate'}',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedVehicleId = value),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Stops (Optional)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (stops.length < 4)
                              TextButton.icon(
                                onPressed: () =>
                                    setDialogState(() => addStop()),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Stop'),
                              ),
                          ],
                        ),
                        if (stops.isEmpty)
                          const Text(
                            'No stops added',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          ...stops.asMap().entries.map((entry) {
                            final index = entry.key;
                            return Card(
                              margin: const EdgeInsets.only(top: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Stop ${index + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => setDialogState(
                                            () => removeStop(index),
                                          ),
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 16,
                                          ),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                    TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Stop Name',
                                        isDense: true,
                                      ),
                                      onChanged: (value) {
                                        stops[index]['name'] = value;
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Stop Address',
                                        isDense: true,
                                      ),
                                      onChanged: (value) {
                                        stops[index]['address'] = value;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (pickupController.text.trim().isEmpty ||
                    destinationController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in pickup and destination'),
                    ),
                  );
                  return;
                }

                try {
                  await _createTrip(
                    title: titleController.text.trim(),
                    pickup: pickupController.text.trim(),
                    destination: destinationController.text.trim(),
                    driverId: selectedDriverId,
                    vehicleId: selectedVehicleId,
                    notes: notesController.text.trim(),
                    stops: stops,
                  );

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip created successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating trip: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text(
                'Create Trip',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTrip({
    String? title,
    required String pickup,
    required String destination,
    String? driverId,
    String? vehicleId,
    String? notes,
    List<Map<String, String>>? stops,
  }) async {
    final stopsDetails =
        stops
            ?.where(
              (stop) =>
                  stop['name']?.isNotEmpty == true &&
                  stop['address']?.isNotEmpty == true,
            )
            .map(
              (stop) => {
                'name': stop['name']!,
                'address': stop['address']!,
                'done': false,
                'skipped': false,
              },
            )
            .toList() ??
        [];

    final tripData = {
      'title': title?.isNotEmpty == true ? title : '$pickup to $destination',
      'startLocation': pickup,
      'endLocation': destination,
      'pickup': pickup,
      'destination': destination,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'dispatcherId': Provider.of<AuthProvider>(
        context,
        listen: false,
      ).user?.uid,
      'driverId': driverId,
      'vehicleId': vehicleId,
      'notes': notes?.isNotEmpty == true ? notes : null,
      'stopsDetails': stopsDetails,
      'stops': stopsDetails,
    };

    await FirebaseFirestore.instance.collection('trips').add(tripData);

    if (vehicleId != null) {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({
            'status': 'assigned',
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          });
    }
  }

  void _showAssignDriverDialog() {
    String? selectedTripId;
    String? selectedDriverId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Driver to Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('trips')
                      .where('status', whereIn: ['pending', 'assigned'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final trips = snapshot.data!.docs;
                    if (trips.isEmpty) {
                      return const Text('No available trips to assign');
                    }

                    return DropdownButtonFormField<String>(
                      value: selectedTripId,
                      decoration: const InputDecoration(
                        labelText: 'Select Trip',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.route),
                      ),
                      items: trips.map((trip) {
                        final data = trip.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: trip.id,
                          child: Text(
                            '${data['pickup'] ?? 'Unknown'} → ${data['destination'] ?? 'Unknown'}',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedTripId = value),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Driver Selection
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('drivers')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final drivers = snapshot.data!.docs;
                    if (drivers.isEmpty) {
                      return const Text('No available drivers');
                    }

                    return DropdownButtonFormField<String>(
                      value: selectedDriverId,
                      decoration: const InputDecoration(
                        labelText: 'Select Driver',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: drivers.map((driver) {
                        final data = driver.data() as Map<String, dynamic>;
                        final rating = (data['rating'] ?? 5.0).toDouble();
                        return DropdownMenuItem(
                          value: driver.id,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(data['name'] ?? 'Unknown Driver'),
                              Text(
                                '⭐ ${rating.toStringAsFixed(1)} • ${data['totalTrips'] ?? 0} trips',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedDriverId = value),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedTripId != null && selectedDriverId != null
                  ? () async {
                      try {
                        await _assignDriverToTrip(
                          selectedTripId!,
                          selectedDriverId!,
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Driver assigned successfully!'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error assigning driver: $e')),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text(
                'Assign',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignDriverToTrip(String tripId, String driverId) async {
    await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
      'driverId': driverId,
      'status': 'assigned',
      'assignedAt': FieldValue.serverTimestamp(),
    });
  }

  void _showVehicleTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VehicleTrackingPage()),
    );
  }

  void _showProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DispatcherProfilePage()),
    );
  }

  void _showSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DispatcherSettingsPage()),
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

  void _viewTripDetails(String tripId) {
    Navigator.of(context).pushNamed('/trip_details', arguments: tripId);
  }

  void _editTrip(String tripId) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('trips')
            .doc(tripId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(content: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Trip not found'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          final tripData = snapshot.data!.data() as Map<String, dynamic>;
          final pickupController = TextEditingController(
            text: tripData['pickup'] ?? '',
          );
          final destinationController = TextEditingController(
            text: tripData['destination'] ?? '',
          );
          final notesController = TextEditingController(
            text: tripData['notes'] ?? '',
          );

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Edit Trip'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: pickupController,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: destinationController,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: tripData['status'],
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      items:
                          [
                                'pending',
                                'assigned',
                                'in_progress',
                                'completed',
                                'cancelled',
                              ]
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.toUpperCase()),
                                ),
                              )
                              .toList(),
                      onChanged: (value) =>
                          setDialogState(() => tripData['status'] = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('trips')
                          .doc(tripId)
                          .update({
                            'pickup': pickupController.text.trim(),
                            'destination': destinationController.text.trim(),
                            'notes': notesController.text.trim(),
                            'status': tripData['status'],
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trip updated successfully!'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating trip: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    'Update Trip',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateTripStatus(String tripId, String status) async {
    try {
      final tripDoc = await FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .get();

      final tripData = tripDoc.data();
      final vehicleId = tripData?['vehicleId'];

      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (status == 'completed' && vehicleId != null) {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicleId)
            .update({
              'status': 'available',
              'lastUpdated': DateTime.now().millisecondsSinceEpoch,
            });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Trip status updated to $status and vehicle has been unassigned',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trip status updated to $status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating trip: $e')));
    }
  }

  void _viewDriverProfile(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver['name'] ?? 'Driver Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${driver['email'] ?? 'N/A'}'),
            Text('Phone: ${driver['phone'] ?? 'N/A'}'),
            Text('Total Trips: ${driver['totalTrips'] ?? 0}'),
            Text('Rating: ${(driver['rating'] ?? 5.0).toStringAsFixed(1)}⭐'),
            Text(
              'Status: ${driver['isActive'] ?? false ? 'Active' : 'Inactive'}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _assignTripToDriver(Map<String, dynamic> driver) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assign trip to ${driver['name']} - Coming soon!'),
      ),
    );
  }

  Future<void> _toggleDriverStatus(Map<String, dynamic> driver) async {
    final uid = driver['uid'];
    if (uid == null) return;

    try {
      final newStatus = !(driver['isActive'] ?? false);
      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Driver ${newStatus ? 'activated' : 'deactivated'} successfully',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating driver status: $e')),
      );
    }
  }

  void _viewVehicleDetails(Map<String, dynamic> vehicle, String vehicleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vehicle['vehicleName'] ?? 'Vehicle Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registration: ${vehicle['registrationNumber'] ?? 'N/A'}'),
              Text('Type: ${vehicle['vehicleType'] ?? 'N/A'}'),
              Text('Capacity: ${vehicle['capacity'] ?? 'N/A'} tons'),
              Text('Driver: ${vehicle['assignedDriver'] ?? 'Unassigned'}'),
              Text('Status: ${vehicle['status'] ?? 'Available'}'),
              Text('Location: ${vehicle['currentLocation'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text(
                'Last Updated: ${vehicle['lastUpdated'] != null ? DateTime.fromMillisecondsSinceEpoch(vehicle['lastUpdated']).toString() : 'N/A'}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (vehicle['status'] == 'maintenance')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markMaintenanceComplete(vehicle, vehicleId);
              },
              child: const Text('Mark Complete'),
            ),
        ],
      ),
    );
  }

  void _editVehicle(Map<String, dynamic> vehicle, String vehicleId) {
    final TextEditingController nameController = TextEditingController(
      text: vehicle['vehicleName'] ?? '',
    );
    final TextEditingController regController = TextEditingController(
      text: vehicle['registrationNumber'] ?? '',
    );
    final TextEditingController typeController = TextEditingController(
      text: vehicle['vehicleType'] ?? '',
    );
    final TextEditingController capacityController = TextEditingController(
      text: vehicle['capacity']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: regController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity (tons)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  regController.text.isNotEmpty) {
                await _updateVehicle(vehicleId, {
                  'vehicleName': nameController.text,
                  'registrationNumber': regController.text,
                  'vehicleType': typeController.text,
                  'capacity': double.tryParse(capacityController.text) ?? 0,
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateVehicle(
    String vehicleId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['lastUpdated'] = DateTime.now().millisecondsSinceEpoch;

      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update(updates);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating vehicle: $e')));
    }
  }

  void _assignVehicleToTrip(Map<String, dynamic> vehicle, String vehicleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign ${vehicle['vehicleName']} to Trip'),
        content: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('trips')
              .where('status', isEqualTo: 'pending')
              .where('vehicleId', isEqualTo: null)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final trips = snapshot.data!.docs;

            if (trips.isEmpty) {
              return const Text('No available trips for assignment');
            }

            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index].data() as Map<String, dynamic>;
                  final tripId = trips[index].id;

                  return ListTile(
                    title: Text(
                      trip['title'] ??
                          trip['pickup'] ??
                          trip['startLocation'] ??
                          'Unknown Trip',
                    ),
                    subtitle: Text(
                      'From: ${trip['startLocation'] ?? trip['pickup'] ?? 'Unknown'}\n'
                      'To: ${trip['endLocation'] ?? trip['destination'] ?? 'Unknown'}',
                    ),
                    onTap: () async {
                      await _assignVehicleToTripAction(vehicleId, tripId);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignVehicleToTripAction(
    String vehicleId,
    String tripId,
  ) async {
    try {
      // Update trip with assigned vehicle
      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'vehicleId': vehicleId,
        'status': 'assigned',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update vehicle status
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({
            'status': 'assigned',
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle assigned to trip successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error assigning vehicle: $e')));
    }
  }

  void _scheduleVehicleMaintenance(
    Map<String, dynamic> vehicle,
    String vehicleId,
  ) {
    final TextEditingController notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule Maintenance for ${vehicle['vehicleName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Maintenance Date'),
              subtitle: Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  selectedDate = date;
                  // Trigger rebuild would need setState if this was a StatefulWidget
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Maintenance Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _scheduleMaintenance(
                vehicleId,
                selectedDate,
                notesController.text,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleMaintenance(
    String vehicleId,
    DateTime date,
    String notes,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({
            'status': 'maintenance',
            'maintenanceScheduled': date.millisecondsSinceEpoch,
            'maintenanceNotes': notes,
          });

      // Create maintenance record
      await FirebaseFirestore.instance.collection('maintenance').add({
        'vehicleId': vehicleId,
        'scheduledDate': date.millisecondsSinceEpoch,
        'notes': notes,
        'status': 'scheduled',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance scheduled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scheduling maintenance: $e')),
      );
    }
  }

  Future<void> _markMaintenanceComplete(
    Map<String, dynamic> vehicle,
    String vehicleId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({
            'status': 'available',
            'lastMaintenance': DateTime.now().millisecondsSinceEpoch,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance marked as complete')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating maintenance status: $e')),
      );
    }
  }

  void _deleteVehicle(Map<String, dynamic> vehicle, String vehicleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
          'Are you sure you want to delete ${vehicle['vehicleName']}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _performVehicleDeletion(vehicleId);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performVehicleDeletion(String vehicleId) async {
    try {
      // Check if vehicle is assigned to any trips
      final trips = await FirebaseFirestore.instance
          .collection('trips')
          .where('vehicleId', isEqualTo: vehicleId)
          .where('status', whereIn: ['in_progress', 'assigned'])
          .get();

      if (trips.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot delete vehicle: It is assigned to active trips',
            ),
          ),
        );
        return;
      }

      // Delete vehicle
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting vehicle: $e')));
    }
  }

  Future<void> _unassignVehicle(
    Map<String, dynamic> vehicle,
    String vehicleId,
  ) async {
    try {
      // Find and update the trip that has this vehicle assigned
      final tripsSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('vehicleId', isEqualTo: vehicleId)
          .where('status', whereIn: ['pending', 'assigned', 'in_progress'])
          .get();

      // Update all trips that have this vehicle assigned
      for (final tripDoc in tripsSnapshot.docs) {
        await tripDoc.reference.update({
          'vehicleId': null,
          'status': tripDoc.data()['status'] == 'assigned'
              ? 'pending'
              : tripDoc.data()['status'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update vehicle status to available
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({
            'status': 'available',
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle ${vehicle['vehicleName']} has been unassigned successfully',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error unassigning vehicle: $e')));
    }
  }

  Future<void> _markVehicleAvailable(
    Map<String, dynamic> vehicle,
    String vehicleId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({
            'status': 'available',
            'lastMaintenance': DateTime.now().millisecondsSinceEpoch,
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle ${vehicle['vehicleName']} marked as available',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating vehicle status: $e')),
      );
    }
  }

  void _showAddVehicleDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController regController = TextEditingController();
    final TextEditingController typeController = TextEditingController();
    final TextEditingController capacityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: regController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'truck', child: Text('Truck')),
                  DropdownMenuItem(value: 'van', child: Text('Van')),
                  DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
                  DropdownMenuItem(value: 'trailer', child: Text('Trailer')),
                ],
                onChanged: (value) => typeController.text = value ?? '',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity (tons)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  regController.text.isNotEmpty &&
                  typeController.text.isNotEmpty) {
                await _addNewVehicle({
                  'vehicleName': nameController.text,
                  'registrationNumber': regController.text,
                  'vehicleType': typeController.text,
                  'capacity': double.tryParse(capacityController.text) ?? 0,
                  'status': 'available',
                  'assignedDriver': null,
                  'currentLocation': 'Depot',
                  'createdAt': DateTime.now().millisecondsSinceEpoch,
                  'lastUpdated': DateTime.now().millisecondsSinceEpoch,
                });
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                  ),
                );
              }
            },
            child: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewVehicle(Map<String, dynamic> vehicleData) async {
    try {
      await FirebaseFirestore.instance.collection('vehicles').add(vehicleData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding vehicle: $e')));
    }
  }
}

// Dispatcher Profile Page
class DispatcherProfilePage extends StatefulWidget {
  const DispatcherProfilePage({super.key});

  @override
  State<DispatcherProfilePage> createState() => _DispatcherProfilePageState();
}

class _DispatcherProfilePageState extends State<DispatcherProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    if (userProfile != null) {
      _nameController.text = userProfile['name'] ?? '';
      _emailController.text = userProfile['email'] ?? '';
      _phoneController.text = userProfile['phone'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('dispatchers')
            .doc(user.uid)
            .update({
              'name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
            });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatcher Profile'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.orange.shade100,
              child: const Icon(Icons.person, size: 60, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: false, // Email usually shouldn't be changed
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Profile',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

// Dispatcher Settings Page
class DispatcherSettingsPage extends StatefulWidget {
  const DispatcherSettingsPage({super.key});

  @override
  State<DispatcherSettingsPage> createState() => _DispatcherSettingsPageState();
}

class _DispatcherSettingsPageState extends State<DispatcherSettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  String _theme = 'Auto';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive app notifications'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive notifications via email'),
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
          ),
          SwitchListTile(
            title: const Text('SMS Notifications'),
            subtitle: const Text('Receive notifications via SMS'),
            value: _smsNotifications,
            onChanged: (value) => setState(() => _smsNotifications = value),
          ),
          const SizedBox(height: 20),
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_theme),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showThemeDialog(),
          ),
          const SizedBox(height: 20),
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
            trailing: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showPrivacyPolicy(),
          ),
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showTermsOfService(),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Auto', 'Light', 'Dark']
              .map(
                (theme) => RadioListTile<String>(
                  title: Text(theme),
                  value: theme,
                  groupValue: _theme,
                  onChanged: (value) {
                    setState(() => _theme = value!);
                    Navigator.of(context).pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Vaaganam Logistics respects your privacy. This app collects location data to enable fleet tracking and route optimization features. '
            'Your personal information is encrypted and stored securely. We do not share your data with third parties without your consent.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using Vaaganam Logistics, you agree to:\n\n'
            '1. Use the app responsibly and in accordance with traffic laws\n'
            '2. Provide accurate information for deliveries\n'
            '3. Report any issues or problems promptly\n'
            '4. Respect other users and maintain professional conduct\n\n'
            'The company reserves the right to suspend accounts for misuse.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Vehicle Tracking Page
class VehicleTrackingPage extends StatelessWidget {
  const VehicleTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Tracking'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No vehicles found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final vehicles = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index].data() as Map<String, dynamic>;
              final status = vehicle['status'] ?? 'unknown';
              final isActive = status == 'active' || status == 'assigned';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green : Colors.grey,
                    child: Icon(Icons.local_shipping, color: Colors.white),
                  ),
                  title: Text(
                    vehicle['model'] ?? 'Unknown Vehicle',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plate: ${vehicle['plateNumber'] ?? 'N/A'}'),
                      Text('Status: ${status.toUpperCase()}'),
                      if (vehicle['currentLocation'] != null)
                        Text('Location: ${vehicle['currentLocation']}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.gps_fixed : Icons.gps_off,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                      Text(
                        isActive ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  onTap: () =>
                      _showVehicleDetails(context, vehicle, vehicles[index].id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVehicleDialog(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showVehicleDetails(
    BuildContext context,
    Map<String, dynamic> vehicle,
    String vehicleId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vehicle['model'] ?? 'Vehicle Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Plate Number', vehicle['plateNumber'] ?? 'N/A'),
            _buildDetailRow('Status', vehicle['status'] ?? 'Unknown'),
            _buildDetailRow('Fuel Level', '${vehicle['fuelLevel'] ?? 0}%'),
            _buildDetailRow('Mileage', '${vehicle['mileage'] ?? 0} km'),
            _buildDetailRow('Last Service', vehicle['lastService'] ?? 'N/A'),
            if (vehicle['currentTrip'] != null)
              _buildDetailRow('Current Trip', vehicle['currentTrip']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (vehicle['status'] == 'maintenance')
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('vehicles')
                    .doc(vehicleId)
                    .update({'status': 'available'});
                Navigator.of(context).pop();
              },
              child: const Text('Mark Available'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final modelController = TextEditingController();
    final plateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: plateController,
              decoration: const InputDecoration(
                labelText: 'Plate Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (modelController.text.trim().isEmpty ||
                  plateController.text.trim().isEmpty)
                return;

              await FirebaseFirestore.instance.collection('vehicles').add({
                'model': modelController.text.trim(),
                'plateNumber': plateController.text.trim(),
                'status': 'available',
                'fuelLevel': 100,
                'mileage': 0,
                'createdAt': FieldValue.serverTimestamp(),
              });

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vehicle added successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'Add Vehicle',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
