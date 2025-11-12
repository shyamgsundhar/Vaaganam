import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  CollectionReference get drivers => _firestore.collection('drivers');
  CollectionReference get dispatchers => _firestore.collection('dispatchers');
  CollectionReference get trips => _firestore.collection('trips');
  CollectionReference get vehicles => _firestore.collection('vehicles');
  CollectionReference get routes => _firestore.collection('routes');

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<Map<String, dynamic>?> getDriverProfile(String uid) async {
    try {
      DocumentSnapshot doc = await drivers.doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    } catch (e) {
      throw Exception('Failed to get driver profile: $e');
    }
  }

  Future<void> updateDriverProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await drivers.doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update driver profile: $e');
    }
  }

  Future<void> createDriverProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? passcode,
    int? age,
    String? gender,
    String? licenseNumber,
    String? experience,
  }) async {
    try {
      await drivers.doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'passcode': passcode,
        'age': age,
        'gender': gender,
        'licenseNumber': licenseNumber,
        'experience': experience,
        'role': 'driver',
        'isActive': true,
        'totalTrips': 0,
        'rating': 5.0,
        'joiningDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create driver profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getDispatcherProfile(String uid) async {
    try {
      DocumentSnapshot doc = await dispatchers.doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    } catch (e) {
      throw Exception('Failed to get dispatcher profile: $e');
    }
  }

  Future<void> createDispatcherProfile({
    required String uid,
    required String name,
    required String email,
    String? department,
  }) async {
    try {
      await dispatchers.doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'department': department,
        'role': 'dispatcher',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create dispatcher profile: $e');
    }
  }

  Future<String> createTrip({
    required String driverId,
    required String routeId,
    required String vehicleId,
    required Map<String, dynamic> tripData,
  }) async {
    try {
      DocumentReference tripRef = await trips.add({
        'driverId': driverId,
        'routeId': routeId,
        'vehicleId': vehicleId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...tripData,
      });
      return tripRef.id;
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }

  Future<void> updateTripStatus(String tripId, String status) async {
    try {
      await trips.doc(tripId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update trip status: $e');
    }
  }

  Stream<QuerySnapshot> getDriverTrips(String driverId) {
    return trips
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllTrips() {
    return trips.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> createVehicle(Map<String, dynamic> vehicleData) async {
    try {
      await vehicles.add({
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...vehicleData,
      });
    } catch (e) {
      throw Exception('Failed to create vehicle: $e');
    }
  }

  Stream<QuerySnapshot> getVehicles() {
    return vehicles.snapshots();
  }

  Future<void> createRoute(Map<String, dynamic> routeData) async {
    try {
      await routes.add({
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...routeData,
      });
    } catch (e) {
      throw Exception('Failed to create route: $e');
    }
  }

  Stream<QuerySnapshot> getRoutes() {
    return routes.snapshots();
  }

  Stream<QuerySnapshot> getDrivers() {
    return drivers.snapshots();
  }

  Future<String> uploadFile(
    String path,
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      Reference ref = _storage.ref().child(path).child(fileName);
      UploadTask uploadTask = ref.putData(Uint8List.fromList(fileBytes));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
