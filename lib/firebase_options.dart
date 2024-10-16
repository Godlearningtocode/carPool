// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyCQOpsVVuNRmHuG-ydAwo0-hdM6ajCMN5M',
    appId: '1:930055685859:web:7f61b4abd8162e6ff4a7d6',
    messagingSenderId: '930055685859',
    projectId: 'car-pool-786eb',
    authDomain: 'car-pool-786eb.firebaseapp.com',
    storageBucket: 'car-pool-786eb.appspot.com',
    measurementId: 'G-ZMS2DP8YWF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC3gOJDyIviVzsjmfqOR66CzIjiVn8U2z8',
    appId: '1:930055685859:android:cc17a002447b40c2f4a7d6',
    messagingSenderId: '930055685859',
    projectId: 'car-pool-786eb',
    storageBucket: 'car-pool-786eb.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCyMKX4vU-aEDqC_ScWYGIZYXauXRZ5cM8',
    appId: '1:930055685859:ios:b15c103518a409a6f4a7d6',
    messagingSenderId: '930055685859',
    projectId: 'car-pool-786eb',
    storageBucket: 'car-pool-786eb.appspot.com',
    iosBundleId: 'com.example.carPool',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCyMKX4vU-aEDqC_ScWYGIZYXauXRZ5cM8',
    appId: '1:930055685859:ios:b15c103518a409a6f4a7d6',
    messagingSenderId: '930055685859',
    projectId: 'car-pool-786eb',
    storageBucket: 'car-pool-786eb.appspot.com',
    iosBundleId: 'com.example.carPool',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCQOpsVVuNRmHuG-ydAwo0-hdM6ajCMN5M',
    appId: '1:930055685859:web:b93fc8c333693e49f4a7d6',
    messagingSenderId: '930055685859',
    projectId: 'car-pool-786eb',
    authDomain: 'car-pool-786eb.firebaseapp.com',
    storageBucket: 'car-pool-786eb.appspot.com',
    measurementId: 'G-9C2GY1BVMG',
  );

}