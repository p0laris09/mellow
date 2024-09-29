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
    apiKey: 'AIzaSyD_Hp71KWktWanL32Ok0dYloaebZW2MmqE',
    appId: '1:924615431516:web:fba7e1f7d5d8b222fddd99',
    messagingSenderId: '924615431516',
    projectId: 'auth-mellow',
    authDomain: 'auth-mellow.firebaseapp.com',
    storageBucket: 'auth-mellow.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAYQeDU60qcHwdlkTMQ1c15WsQ8V7dnZ2Q',
    appId: '1:924615431516:android:6b89240b3557928bfddd99',
    messagingSenderId: '924615431516',
    projectId: 'auth-mellow',
    storageBucket: 'auth-mellow.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBQgnIQ4MaL4g7TUQlZuhxlIcivo-BIcp4',
    appId: '1:924615431516:ios:dc1b7188ffe5f90bfddd99',
    messagingSenderId: '924615431516',
    projectId: 'auth-mellow',
    storageBucket: 'auth-mellow.appspot.com',
    iosBundleId: 'com.example.mellow',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBQgnIQ4MaL4g7TUQlZuhxlIcivo-BIcp4',
    appId: '1:924615431516:ios:dc1b7188ffe5f90bfddd99',
    messagingSenderId: '924615431516',
    projectId: 'auth-mellow',
    storageBucket: 'auth-mellow.appspot.com',
    iosBundleId: 'com.example.mellow',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD_Hp71KWktWanL32Ok0dYloaebZW2MmqE',
    appId: '1:924615431516:web:92e8358bcf4aebdbfddd99',
    messagingSenderId: '924615431516',
    projectId: 'auth-mellow',
    authDomain: 'auth-mellow.firebaseapp.com',
    storageBucket: 'auth-mellow.appspot.com',
  );
}
