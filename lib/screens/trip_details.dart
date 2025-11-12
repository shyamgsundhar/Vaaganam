import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TripDetailsPage extends StatefulWidget {
  const TripDetailsPage({super.key});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  double _buttonScale = 1.0;

  Map<String, dynamic>? _tripData;
  List<Map<String, dynamic>> _stops = [];
  Map<String, dynamic>? _vehicleData;
  bool _isLoading = true;
  String? _tripId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tripId == null) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      _tripId = args?['id']?.toString();
      if (_tripId != null) {
        _loadTripDetails();
      } else {
        _loadExampleData();
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTripDetails() async {
    setState(() => _isLoading = true);

    try {
      if (_tripId != null && _tripId != 'example_001') {
        final tripDoc = await FirebaseFirestore.instance
            .collection('trips')
            .doc(_tripId)
            .get();

        if (tripDoc.exists) {
          _tripData = tripDoc.data() as Map<String, dynamic>;
          _tripData!['id'] = tripDoc.id;

          _stops = List<Map<String, dynamic>>.from(
            _tripData?['stopsDetails'] ?? [],
          );

          if (_tripData?['vehicleId'] != null) {
            final vehicleDoc = await FirebaseFirestore.instance
                .collection('vehicles')
                .doc(_tripData!['vehicleId'].toString())
                .get();

            if (vehicleDoc.exists) {
              _vehicleData = vehicleDoc.data() as Map<String, dynamic>;
              _vehicleData!['id'] = vehicleDoc.id;
            }
          }
        } else {
          _loadExampleData();
        }
      } else {
        _loadExampleData();
      }
    } catch (e) {
      print('Error loading trip details: $e');
      _loadExampleData();
    }

    setState(() => _isLoading = false);
  }

  void _loadExampleData() {
    _tripData = {
      'id': 'example_001',
      'title': 'AA to BB',
      'startLocation': 'A',
      'endLocation': 'B',
      'startTime': '07:15',
      'endTime': '12:30',
      'startDetails': 'Dock 3',
      'endDetails': 'Gate B',
      'status': 'scheduled',
      'route': 'AA → BB',
    };

    _vehicleData = {
      'id': 'AB-1234',
      'vehicleName': 'AB-1234 (Truck)',
      'vehicleType': 'Truck',
      'capacity': 1.2,
      'registrationNumber': 'AB-1234',
    };
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final tripTitle =
        _tripData?['title']?.toString() ??
        args?['title']?.toString() ??
        'Trip Details';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tripTitle),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 72,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onBackground,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          if (!_isLoading && _tripData != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTripDetails,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tripData == null
          ? const Center(child: Text('Trip not found'))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteCard(theme),
                  const SizedBox(height: 14),
                  _buildStopsCard(theme),
                  const SizedBox(height: 14),
                  _buildVehicleCard(theme),
                  const SizedBox(height: 20),
                  _buildStartButton(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildRouteCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.alt_route, size: 28, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Route', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.radio_button_checked,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Start',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _tripData?['startLocation']?.toString() ??
                                  'Warehouse A',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_tripData?['startTime']?.toString() ?? '07:15'} • ${_tripData?['startDetails']?.toString() ?? 'Dock 3'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.black45,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'End',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _tripData?['endLocation']?.toString() ??
                                  'North Hub',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_tripData?['endTime']?.toString() ?? '12:30'} • ${_tripData?['endDetails']?.toString() ?? 'Gate B'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopsCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Planned stops (${_stops.length})',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              children: List.generate(_stops.length, (i) {
                final stop = _stops[i];
                final isLast = i == _stops.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _updateStopStatus(i, !stop['done']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: stop['done']
                                  ? theme.colorScheme.primary
                                  : Colors.white,
                              border: Border.all(
                                color: theme.colorScheme.primary,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              stop['done'] ? Icons.check : Icons.circle,
                              size: 12,
                              color: stop['done']
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 48,
                            margin: const EdgeInsets.only(top: 6),
                            color: theme.dividerColor,
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop['name']?.toString() ?? 'Unknown Stop',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (stop['address'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                stop['address']?.toString() ?? 'No address',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Window: ${stop['window']?.toString() ?? 'TBD'}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Chip(
                                  label: Text(
                                    stop['done'] ? 'Completed' : 'Pending',
                                    style: TextStyle(
                                      color: stop['done']
                                          ? theme.colorScheme.onPrimary
                                          : Colors.black87,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: stop['done']
                                      ? theme.colorScheme.primary
                                      : Colors.grey.shade200,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_shipping,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vehicle info', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Name',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _vehicleData?['vehicleName']?.toString() ??
                        'AB-1234 (Truck)',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_number,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ID:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _vehicleData?['registrationNumber']?.toString() ??
                            'AB-1234',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Icon(Icons.line_weight, size: 16, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text(
                        'Capacity:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _vehicleData?['capacity'] != null
                            ? '${_vehicleData!['capacity']} tons'
                            : '1200 kg',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(ThemeData theme) {
    final isStarted =
        _tripData?['status']?.toString() == 'in_progress' ||
        _tripData?['status']?.toString() == 'completed';

    return Center(
      child: AnimatedScale(
        scale: _buttonScale,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              backgroundColor: isStarted
                  ? Colors.grey
                  : theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            onPressed: isStarted
                ? null
                : () => _animateAndStart({
                    'id': _tripData?['id']?.toString() ?? _tripId,
                    'title': _tripData?['title']?.toString() ?? 'Trip',
                  }),
            child: Text(
              isStarted
                  ? 'Trip ${_tripData?['status']?.toString() ?? 'Started'}'
                  : 'Start Trip',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  void _animateAndStart(Map<String, dynamic> args) async {
    setState(() => _buttonScale = 0.96);
    await Future.delayed(const Duration(milliseconds: 120));
    setState(() => _buttonScale = 1.0);

    if (_tripData?['id'] != null &&
        _tripData!['id'].toString() != 'example_001') {
      try {
        await FirebaseFirestore.instance
            .collection('trips')
            .doc(_tripData!['id'].toString())
            .update({'status': 'in_progress'});

        _tripData!['status'] = 'in_progress';
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    Navigator.of(context).pushNamed('/trip_in_progress', arguments: args);
  }

  Future<void> _updateStopStatus(int index, bool completed) async {
    setState(() {
      _stops[index]['done'] = completed;
    });

    if (_tripData?['id'] != null &&
        _tripData!['id'].toString() != 'example_001') {
      try {
        await FirebaseFirestore.instance
            .collection('trips')
            .doc(_tripData!['id'].toString())
            .update({'stopsDetails': _stops});
      } catch (e) {
        print('Error updating stop status: $e');
      }
    }
  }
}
