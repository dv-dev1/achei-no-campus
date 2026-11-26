import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

/// Liga o app ao projeto real (`achei-no-campus-unipe`). Não chama o
/// `configurarAuthLocal`: em produção nada aponta para os emuladores.
Future<void> inicializarFirebaseProducao() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Igual ao modo local, para os dois modos se comportarem do mesmo jeito.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}
