import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating,
}

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  Map<String, dynamic>? _userProfile;
  String? _userRole;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get userRole => _userRole;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isDriver => _userRole == 'driver';
  bool get isDispatcher => _userRole == 'dispatcher';

  AuthProvider() {
    _init();
  }

  void _init() {
    _firebaseService.auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      _userProfile = null;
      _userRole = null;
      _errorMessage = null;
    } else {
      _user = user;
      await _loadUserProfile();
    }
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    try {
      Map<String, dynamic>? driverProfile = await _firebaseService
          .getDriverProfile(_user!.uid);
      if (driverProfile != null) {
        _userProfile = driverProfile;
        _userRole = 'driver';
        _status = AuthStatus.authenticated;
        return;
      }

      Map<String, dynamic>? dispatcherProfile = await _firebaseService
          .getDispatcherProfile(_user!.uid);
      if (dispatcherProfile != null) {
        _userProfile = dispatcherProfile;
        _userRole = 'dispatcher';
        _status = AuthStatus.authenticated;
        return;
      }

      _status = AuthStatus.unauthenticated;
      _errorMessage = 'User profile not found. Please complete registration.';
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Failed to load user profile: $e';
    }
  }

  Future<bool> loginDriver(String email, String passcode) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();
      QuerySnapshot driverQuery = await _firebaseService.drivers
          .where('email', isEqualTo: email)
          .where('passcode', isEqualTo: passcode)
          .limit(1)
          .get();

      if (driverQuery.docs.isEmpty) {
        throw Exception('Invalid email or passcode');
      }

      driverQuery.docs.first.data() as Map<String, dynamic>;
      String defaultPassword = 'driver_${passcode}_password';

      try {
        await _firebaseService.signInWithEmailAndPassword(
          email,
          defaultPassword,
        );
      } catch (e) {
        await _firebaseService.createUserWithEmailAndPassword(
          email,
          defaultPassword,
        );
      }

      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginDispatcher(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      await _firebaseService.signInWithEmailAndPassword(email, password);
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerDriver({
    required String name,
    required String email,
    required String phone,
    required String passcode,
    int? age,
    String? gender,
    String? licenseNumber,
    String? experience,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      String defaultPassword = 'driver_${passcode}_password';
      UserCredential? userCredential = await _firebaseService
          .createUserWithEmailAndPassword(email, defaultPassword);

      if (userCredential != null && userCredential.user != null) {
        await _firebaseService.createDriverProfile(
          uid: userCredential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          passcode: passcode,
          age: age,
          gender: gender,
          licenseNumber: licenseNumber,
          experience: experience,
        );

        return true;
      }
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerDispatcher({
    required String name,
    required String email,
    required String password,
    String? department,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      UserCredential? userCredential = await _firebaseService
          .createUserWithEmailAndPassword(email, password);

      if (userCredential?.user != null) {
        await _firebaseService.createDispatcherProfile(
          uid: userCredential!.user!.uid,
          name: name,
          email: email,
          department: department,
        );

        return true;
      }
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      if (_user == null || _userRole == null) return false;

      if (_userRole == 'driver') {
        await _firebaseService.updateDriverProfile(_user!.uid, profileData);
      } else {
        await _firebaseService.dispatchers.doc(_user!.uid).update({
          ...profileData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await _loadUserProfile();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseService.signOut();

      _user = null;
      _userProfile = null;
      _userRole = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Logout failed: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _firebaseService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
