import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'auth_local_stub.dart'
    if (dart.library.js_interop) 'auth_local_web.dart';

Future<void> inicializarFirebaseLocal() async {
  const hostConfigurado = String.fromEnvironment('EMULATOR_HOST');
  final host = hostConfigurado.isNotEmpty
      ? hostConfigurado
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';
  const options = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:1234567890:web:0000000000000000000000',
    messagingSenderId: '1234567890',
    projectId: 'demo-achei-no-campus',
    authDomain: 'demo-achei-no-campus.firebaseapp.com',
  );
  await configurarAuthLocal(host, options);
  await Firebase.initializeApp(options: options);
  if (!kIsWeb) {
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  }
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
}
