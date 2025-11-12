import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:vaaganam/screens/driver.dart';

class TripSummaryPage extends StatefulWidget {
  final String? tripId;

  const TripSummaryPage({super.key, this.tripId});

  @override
  State<TripSummaryPage> createState() => _TripSummaryPageState();
}

class _TripSummaryPageState extends State<TripSummaryPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rotateAnim;

  Map<String, dynamic>? _tripData;
  List<Map<String, dynamic>> _fuelLogs = [];
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _stops = [];
  bool _isLoading = true;
  String? _tripId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tripId == null) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      _tripId = args?['id']?.toString() ?? widget.tripId;
      if (_tripId != null && _tripData == null) {
        _loadTripSummary();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tripId = widget.tripId;
    if (_tripId != null) {
      _loadTripSummary();
    }
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.9, end: 1.12).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _rotateAnim = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _loadTripSummary();
  }

  Future<void> _loadTripSummary() async {
    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      String tripId = _tripId ?? 'default';

      DocumentSnapshot tripDoc = await FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .get();

      if (tripDoc.exists) {
        _tripData = tripDoc.data() as Map<String, dynamic>?;

        if (_tripData != null) {
          _stops = List<Map<String, dynamic>>.from(
            _tripData!['stopsDetails'] ?? [],
          );

          await _loadTripLogs(tripId);
        }
      } else {
        throw Exception('Trip not found in database');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading trip summary: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTripLogs(String tripId) async {
    QuerySnapshot fuelSnapshot = await FirebaseFirestore.instance
        .collection('trips')
        .doc(tripId)
        .collection('fuel_logs')
        .orderBy('timestamp', descending: true)
        .get();

    _fuelLogs = fuelSnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();

    QuerySnapshot notesSnapshot = await FirebaseFirestore.instance
        .collection('trips')
        .doc(tripId)
        .collection('notes')
        .orderBy('timestamp', descending: true)
        .get();

    _notes = notesSnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '00:00';
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h.toString().padLeft(2, '0')}:$m:$s' : '$m:$s';
  }

  String _timeOf(DateTime? t) {
    if (t == null) return '-';
    return DateFormat('HH:mm').format(t);
  }

  Future<bool> _goToTripDetails(Map<String, dynamic>? args) async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const DriverPage(),
        settings: RouteSettings(arguments: args ?? {}),
      ),
      (route) => false,
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (_isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading Summary...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final title = _tripData?['title']?.toString() ?? 'Trip Summary';
        final deliveries = _tripData?['deliveriesLogged'] ?? 0;
        final elapsed = _tripData?['elapsedSeconds'] as int?;

        final totalFuel = _fuelLogs.fold<double>(0.0, (prev, e) {
          try {
            return prev + (e['amount'] as double? ?? 0.0);
          } catch (_) {
            return prev;
          }
        });

        return WillPopScope(
          onWillPop: () => _goToTripDetails(null),
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goToTripDetails(null),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              title: Text(
                title,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              centerTitle: true,
              iconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotateAnim.value,
                                child: Transform.scale(
                                  scale: _scaleAnim.value,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(18.0),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.local_shipping_rounded,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Congratulations!',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Trip completed — great job on the deliveries 👏',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Deliveries',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$deliveries',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDuration(elapsed),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fuel',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${totalFuel.toStringAsFixed(2)} L',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car_outlined, size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _tripData?['vehicleId'] ?? 'Vehicle',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _tripData != null
                                        ? 'Trip ID: ${_tripData!['id'] ?? '-'}'
                                        : 'No trip data',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route & Stops',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_stops.isEmpty) ...[
                              Text(
                                'No stops recorded',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.black54),
                              ),
                            ] else ...[
                              for (var i = 0; i < _stops.length; i++)
                                ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: _stops[i]['done'] == true
                                        ? Theme.of(context).colorScheme.primary
                                        : _stops[i]['skipped'] == true
                                        ? Colors.orangeAccent
                                        : Colors.grey.shade200,
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: _stops[i]['done'] == true
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimary
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    _stops[i]['name'] ?? 'Stop ${i + 1}',
                                  ),
                                  subtitle: Text(_stops[i]['address'] ?? ''),
                                  trailing: Chip(
                                    label: Text(
                                      _stops[i]['done'] == true
                                          ? 'Delivered'
                                          : (_stops[i]['skipped'] == true
                                                ? 'Skipped'
                                                : 'Pending'),
                                    ),
                                    backgroundColor: _stops[i]['done'] == true
                                        ? Theme.of(context).colorScheme.primary
                                        : (_stops[i]['skipped'] == true
                                              ? Colors.orange.shade100
                                              : Colors.grey.shade200),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fuel logs',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_fuelLogs.isEmpty)
                              Text(
                                'No fuel entries',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.black54),
                              )
                            else
                              ..._fuelLogs.map((f) {
                                final t = f['timestamp'] is DateTime
                                    ? f['timestamp'] as DateTime
                                    : (f['timestamp'] is Timestamp
                                          ? (f['timestamp'] as Timestamp)
                                                .toDate()
                                          : null);
                                final stopName = f['stopName'] as String?;
                                final amt = (f['amount'] as double?) ?? 0.0;
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.local_gas_station),
                                  title: Text('${amt.toStringAsFixed(2)} L'),
                                  subtitle: Text(
                                    '${stopName != null ? '$stopName • ' : ''}${t != null ? _timeOf(t) : '-'}',
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notes',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_notes.isEmpty)
                              Text(
                                'No notes',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.black54),
                              )
                            else
                              ..._notes.map((n) {
                                final t = n['timestamp'] is DateTime
                                    ? n['timestamp'] as DateTime
                                    : (n['timestamp'] is Timestamp
                                          ? (n['timestamp'] as Timestamp)
                                                .toDate()
                                          : null);
                                final stopName = n['stopName'] as String?;
                                final text =
                                    n['text'] as String? ?? n.toString();
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.note),
                                  title: Text(text),
                                  subtitle: Text(
                                    '${stopName != null ? '$stopName • ' : ''}${t != null ? _timeOf(t) : '-'}',
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _goToTripDetails(null),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                        ),
                        child: const Text('Back to Trip Details'),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
