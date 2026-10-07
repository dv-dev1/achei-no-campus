import 'dart:js_interop';

import 'package:firebase_core/firebase_core.dart';

@JS('configurarFirebaseAuthLocal')
external JSPromise<JSAny?> _configurarFirebaseAuthLocal(
  JSAny options,
  JSString host,
);

Future<void> configurarAuthLocal(String host, FirebaseOptions options) async {
  await _configurarFirebaseAuthLocal(options.asMap.jsify()!, host.toJS).toDart;
}
