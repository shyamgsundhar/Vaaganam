import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class TripInProgressPage extends StatefulWidget {
  final String? tripId;

  const TripInProgressPage({super.key, this.tripId});

  @override
  State<TripInProgressPage> createState() => _TripInProgressPageState();
}

class _TripInProgressPageState extends State<TripInProgressPage> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _paused = false;
  bool _showNotes = false;
  bool _showFuelDetails = false;

  // Firebase-driven data
  Map<String, dynamic>? _tripData;
  List<Map<String, dynamic>> _stops = [];
  List<Map<String, dynamic>> _fuelLogs = [];
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  String? _tripId;

  int _currentStop = 0;
  int _deliveriesLogged = 0;
  final MapController _mapController = MapController();
  double _mapZoom = 13.0;
  List<LatLng> _polyline = [];

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _fuelController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tripId == null) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      _tripId = args?['id']?.toString() ?? widget.tripId;
      if (_tripId != null && _tripData == null) {
        _loadTripData();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tripId = widget.tripId;
    if (_tripId != null) {
      _loadTripData();
    }
    _startTimer();
  }

  Future<void> _loadTripData() async {
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

          _updatePolyline();
        }
      } else {
        throw Exception('Trip not found in database');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading trip: $e')));
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

  void _updatePolyline() {
    if (_stops.isNotEmpty) {
      _polyline = _stops
          .where((stop) => stop['lat'] != null && stop['lng'] != null)
          .map(
            (stop) => LatLng(
              (stop['lat'] as num).toDouble(),
              (stop['lng'] as num).toDouble(),
            ),
          )
          .toList();
    }
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused) setState(() => _elapsedSeconds++);
    });
    setState(() {});
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
  }

  void _logDelivery(bool success) {
    setState(() {
      _deliveriesLogged += 1;
      if (_stops.isNotEmpty && _currentStop < _stops.length) {
        if (success) {
          _stops[_currentStop]['done'] = true;
          _currentStop = (_currentStop + 1).clamp(0, _stops.length - 1);
        }
      }
    });

    _updateStopStatus(success);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Delivery logged: success' : 'Delivery logged: failure',
        ),
      ),
    );
  }

  void _skipDelivery() {
    setState(() {
      if (_stops.isNotEmpty && _currentStop < _stops.length) {
        _stops[_currentStop]['skipped'] = true;
        if (_currentStop + 1 < _stops.length) {
          _currentStop += 1;
        }
      }
    });

    _updateStopStatus(false, skipped: true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delivery canceled — moving to next stop')),
    );
  }

  Future<void> _updateStopStatus(bool success, {bool skipped = false}) async {
    try {
      String tripId = _tripId ?? 'default';

      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'stopsDetails': _stops,
        'currentStop': _currentStop,
        'deliveriesLogged': _deliveriesLogged,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating stop status: $e');
    }
  }

  bool get _allStopsDone =>
      _stops.isNotEmpty && _stops.every((s) => s['done'] == true);

  bool get _canCompleteTrip {
    if (_stops.isEmpty) return false;
    final allDone = _stops.every((s) => s['done'] == true);
    return allDone && _stops.length >= 2;
  }

  Future<void> _deliverWithFuelAndNote() async {
    final litersController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery - ${_stops.isNotEmpty ? _stops[_currentStop]['name'] : ''}',
            ),
            const SizedBox(height: 6),
            Text(
              'Enter litres (required) and an optional note',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: litersController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Litres (L)',
                  hintText: 'e.g. 12.5',
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Please enter litres';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0)
                    return 'Enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Tap to add a short note about this delivery',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              final liters = double.parse(litersController.text.trim());
              setState(() {
                _fuelLogs.add({
                  'amount': liters,
                  'time': DateTime.now(),
                  'stopIndex': _currentStop,
                  'stopName': _stops.isNotEmpty
                      ? _stops[_currentStop]['name']
                      : null,
                });
                final noteText = noteController.text.trim();
                if (noteText.isNotEmpty) {
                  _notes.add({
                    'text': noteText,
                    'time': DateTime.now(),
                    'stopIndex': _currentStop,
                    'stopName': _stops.isNotEmpty
                        ? _stops[_currentStop]['name']
                        : null,
                  });
                }
              });
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _logDelivery(true);
    }
  }

  Future<void> _logFuel() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Fuel (liters)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'e.g. 25.5'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final val = double.tryParse(controller.text) ?? 0.0;
              try {
                String tripId = _tripId ?? 'default';

                final fuelLog = {
                  'amount': val,
                  'timestamp': FieldValue.serverTimestamp(),
                  'stopIndex': _currentStop,
                  'stopName': _stops.isNotEmpty
                      ? _stops[_currentStop]['name']
                      : null,
                  'location': 'Current Location',
                };

                await FirebaseFirestore.instance
                    .collection('trips')
                    .doc(tripId)
                    .collection('fuel_logs')
                    .add(fuelLog);

                setState(
                  () => _fuelLogs.insert(0, {
                    'amount': val,
                    'time': DateTime.now(),
                    'stopIndex': _currentStop,
                    'stopName': _stops.isNotEmpty
                        ? _stops[_currentStop]['name']
                        : null,
                  }),
                );

                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Fuel logged: $val L')));
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error logging fuel: $e')),
                );
              }
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  String tripId = _tripId ?? 'default';

                  final note = {
                    'text': controller.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                    'stopIndex': _currentStop,
                    'stopName': _stops.isNotEmpty
                        ? _stops[_currentStop]['name']
                        : null,
                  };

                  await FirebaseFirestore.instance
                      .collection('trips')
                      .doc(tripId)
                      .collection('notes')
                      .add(note);

                  setState(
                    () => _notes.insert(0, {
                      'text': controller.text.trim(),
                      'time': DateTime.now(),
                      'stopIndex': _currentStop,
                      'stopName': _stops.isNotEmpty
                          ? _stops[_currentStop]['name']
                          : null,
                    }),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding note: $e')),
                  );
                }
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h == '00' ? '$m:$s' : '$h:$m:$s';
  }

  double get _totalFuel => _fuelLogs.fold(
    0.0,
    (prev, item) => prev + (item['amount'] as double? ?? 0.0),
  );

  Widget _buildFuelCard(ThemeData theme) {
    final total = _totalFuel;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _showFuelDetails = !_showFuelDetails),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  const Icon(Icons.local_gas_station),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fuel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${total.toStringAsFixed(2)} L',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _showFuelDetails ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Column(
                  children: _fuelLogs.isEmpty
                      ? [
                          Text(
                            'No fuel entries',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                        ]
                      : _fuelLogs.reversed.map((f) {
                          final t = f['time'] as DateTime;
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.local_gas_station),
                            title: Text(
                              '${((f['amount'] as num?) ?? 0).toDouble().toStringAsFixed(2)} L',
                            ),
                            subtitle: Text(
                              '${f['stopName'] != null ? '${f['stopName']} • ' : ''}${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                            ),
                          );
                        }).toList(),
                ),
              ),
              crossFadeState: _showFuelDetails
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _showNotes = !_showNotes),
              child: Row(
                children: [
                  const Icon(Icons.note),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _notes.isEmpty
                              ? 'No notes'
                              : '${_notes.length} notes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showNotes ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Column(
                  children: _notes.isEmpty
                      ? [
                          Text(
                            'No notes yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                        ]
                      : _notes.asMap().entries.map((e) {
                          final idx = e.key;
                          final n = e.value;
                          final t = n['time'] as DateTime?;
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.note),
                            title: Text(n['text'] as String? ?? ''),
                            subtitle: Text(
                              n['stopName'] != null
                                  ? '${n['stopName']} • ${t != null ? '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}' : ''}'
                                  : (t != null
                                        ? '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
                                        : ''),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  setState(() => _notes.removeAt(idx)),
                            ),
                          );
                        }).toList(),
                ),
              ),
              crossFadeState: _showNotes
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeTrip() async {
    _stopTimer();

    try {
      String tripId = _tripId ?? 'default';

      final tripDoc = await FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .get();

      Map<String, dynamic>? tripData;
      if (tripDoc.exists) {
        tripData = tripDoc.data();
      }

      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'completed',
        'endTime': FieldValue.serverTimestamp(),
        'deliveriesLogged': _deliveriesLogged,
        'elapsedSeconds': _elapsedSeconds,
        'stopsDetails': _stops,
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final driverId = authProvider.user?.uid;
      if (driverId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('drivers')
              .doc(driverId)
              .update({'totalTrips': FieldValue.increment(1)});
          print('Driver $driverId total trips incremented.');
        } catch (driverError) {
          print('Error updating driver total trips: $driverError');
        }
      }

      final vehicleId = tripData?['vehicleId'];
      if (vehicleId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(vehicleId)
              .update({
                'status': 'available',
                'lastUpdated': DateTime.now().millisecondsSinceEpoch,
              });

          print(
            'Vehicle $vehicleId has been unassigned and marked as available',
          );
        } catch (vehicleError) {
          print('Error unassigning vehicle: $vehicleError');
        }
      }

      final summary = {
        'id': tripId,
        'title': _tripData?['title']?.toString() ?? 'Trip',
        'deliveries': _deliveriesLogged,
        'fuelLogs': _fuelLogs,
        'notes': _notes,
        'elapsedSeconds': _elapsedSeconds,
        'stopsCompleted': _stops.where((stop) => stop['done'] == true).length,
        'totalStops': _stops.length,
      };
      Navigator.of(context).pushNamed('/trip_summary', arguments: summary);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error completing trip: $e')));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    _fuelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (_isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading Trip...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final tripTitle = _tripData?['title']?.toString() ?? 'Trip In Progress';
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(tripTitle),
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.colorScheme.primary),
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(_paused ? 'Paused' : 'In Progress'),
                      backgroundColor: _paused
                          ? Colors.orange.shade100
                          : theme.colorScheme.primary.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: _paused
                            ? Colors.orange.shade800
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Time',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_elapsedSeconds),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        _togglePause();
                      },
                      icon: Icon(
                        _paused ? Icons.play_arrow : Icons.pause,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    height: 220,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            center: _polyline.isNotEmpty
                                ? _polyline[0]
                                : LatLng(37.7749, -122.4194),
                            zoom: _mapZoom,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _polyline,
                                  color: theme.colorScheme.primary,
                                  strokeWidth: 4.0,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: _stops
                                  .asMap()
                                  .entries
                                  .where(
                                    (entry) =>
                                        entry.value['lat'] != null &&
                                        entry.value['lng'] != null,
                                  )
                                  .map((entry) {
                                    final i = entry.key;
                                    final s = entry.value;
                                    return Marker(
                                      point: LatLng(
                                        (s['lat'] as num).toDouble(),
                                        (s['lng'] as num).toDouble(),
                                      ),
                                      width: 36,
                                      height: 36,
                                      builder: (ctx) => CircleAvatar(
                                        backgroundColor: i == _currentStop
                                            ? theme.colorScheme.primary
                                            : Colors.white,
                                        child: Icon(
                                          i == _currentStop
                                              ? Icons.flag
                                              : Icons.location_pin,
                                          size: 18,
                                          color: i == _currentStop
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.primary,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          ],
                        ),

                        Positioned(
                          right: 8,
                          top: 8,
                          child: Column(
                            children: [
                              FloatingActionButton.small(
                                heroTag: 'zoom_in',
                                onPressed: () {
                                  _mapZoom = (_mapZoom + 1).clamp(3.0, 19.0);
                                  final center = _mapController.center;
                                  _mapController.move(center, _mapZoom);
                                  setState(() {});
                                },
                                child: const Icon(Icons.add, size: 18),
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton.small(
                                heroTag: 'zoom_out',
                                onPressed: () {
                                  _mapZoom = (_mapZoom - 1).clamp(3.0, 19.0);
                                  final center = _mapController.center;
                                  _mapController.move(center, _mapZoom);
                                  setState(() {});
                                },
                                child: const Icon(Icons.remove, size: 18),
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
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(
                      'Drop details',
                      style: theme.textTheme.titleMedium,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: _stops.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current: ${_stops[_currentStop]['name']}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
                                        '${_stops[_currentStop]['window']}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.black54),
                                      ),
                                      const SizedBox(width: 12),
                                      Chip(
                                        label: Text(
                                          _stops[_currentStop]['done']
                                              ? 'Completed'
                                              : 'Pending',
                                        ),
                                        backgroundColor:
                                            _stops[_currentStop]['done']
                                            ? theme.colorScheme.primary
                                            : Colors.grey.shade200,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (_currentStop + 1 < _stops.length)
                                    Text(
                                      'Next: ${_stops[_currentStop + 1]['name']}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.black54),
                                    ),
                                ],
                              )
                            : Text(
                                'No stops available',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _togglePause(),
                                icon: Icon(
                                  _paused ? Icons.play_arrow : Icons.pause,
                                ),
                                label: Text(_paused ? 'Resume' : 'Pause'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _paused
                                    ? () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Cannot log delivery while paused',
                                            ),
                                          ),
                                        );
                                      }
                                    : () => showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Log Delivery'),
                                          content: const Text('Select outcome'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                _deliverWithFuelAndNote();
                                              },
                                              child: const Text('Delivered'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text(
                                                      'Cancel Delivery?',
                                                    ),
                                                    content: const Text(
                                                      'Are you sure you want to cancel this delivery and move to the next stop?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              ctx,
                                                            ).pop(false),
                                                        child: const Text('No'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(true);
                                                          _skipDelivery();
                                                        },
                                                        child: const Text(
                                                          'Yes',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Cancel Delivery',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                icon: const Icon(Icons.check),
                                label: const Text('Log Delivery'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _logFuel,
                                icon: const Icon(Icons.local_gas_station),
                                label: const Text('Log Fuel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor:
                                      theme.colorScheme.onSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _addNote,
                                icon: const Icon(Icons.note_add),
                                label: const Text('Add Note'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.tertiary,
                                  foregroundColor: theme.colorScheme.onTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildFuelCard(theme),
                        const SizedBox(height: 12),

                        _buildNotesCard(theme),
                        const SizedBox(height: 12),

                        Dismissible(
                          key: const ValueKey('force_complete'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (dir) async {
                            final res = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Force complete trip?'),
                                content: const Text(
                                  'This will complete the trip even if not all stops have been delivered.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Force Complete'),
                                  ),
                                ],
                              ),
                            );
                            return res == true;
                          },
                          onDismissed: (_) => _completeTrip(),
                          background: Container(
                            color: Colors.redAccent,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16.0),
                            child: const Icon(Icons.flag, color: Colors.white),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14.0,
                                ),
                              ),
                              onPressed: _canCompleteTrip
                                  ? () => _completeTrip()
                                  : null,
                              child: Text(
                                _canCompleteTrip
                                    ? 'Complete Trip'
                                    : 'Complete Trip (all stops must be delivered)',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
