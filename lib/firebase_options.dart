import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC84GdbPkDdGyY3UFC-ri6lLMfr2Rn5_ao',
    appId: '1:103528733913:web:7b3f2cf4424677dd5cf2c8',
    messagingSenderId: '103528733913',
    projectId: 'vaaganam-7779b',
    authDomain: 'vaaganam-7779b.firebaseapp.com',
    storageBucket: 'vaaganam-7779b.firebasestorage.app',
    measurementId: 'G-P275T85G8L',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBSyDjxzIyLhnujDYRIr8tWy9ODUa8FUww',
    appId: '1:103528733913:android:db4067a5b168631f5cf2c8',
    messagingSenderId: '103528733913',
    projectId: 'vaaganam-7779b',
    storageBucket: 'vaaganam-7779b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCRdpoLMYa4cteCDbsFhTF95WQ2Xp1Ejv8',
    appId: '1:103528733913:ios:9589e7b5ba08f5d55cf2c8',
    messagingSenderId: '103528733913',
    projectId: 'vaaganam-7779b',
    storageBucket: 'vaaganam-7779b.firebasestorage.app',
    iosBundleId: 'com.example.vaaganam',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCRdpoLMYa4cteCDbsFhTF95WQ2Xp1Ejv8',
    appId: '1:103528733913:ios:9589e7b5ba08f5d55cf2c8',
    messagingSenderId: '103528733913',
    projectId: 'vaaganam-7779b',
    storageBucket: 'vaaganam-7779b.firebasestorage.app',
    iosBundleId: 'com.example.vaaganam',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC84GdbPkDdGyY3UFC-ri6lLMfr2Rn5_ao',
    appId: '1:103528733913:web:e71b1bb4068f73b05cf2c8',
    messagingSenderId: '103528733913',
    projectId: 'vaaganam-7779b',
    authDomain: 'vaaganam-7779b.firebaseapp.com',
    storageBucket: 'vaaganam-7779b.firebasestorage.app',
    measurementId: 'G-X1XKZJNQNZ',
  );
}
