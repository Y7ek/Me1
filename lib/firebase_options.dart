import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsAUS_RK0x3ynd9Oh0U1pnvV_He3tqcoc',
    appId: '1:392910674178:android:39a8cc6fb97f24d5cd4a1b',
    messagingSenderId: '392910674178',
    projectId: 'memm-916bc',
    storageBucket: 'memm-916bc.firebasestorage.app',
  );
}