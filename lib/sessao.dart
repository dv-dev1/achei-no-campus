import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'config.dart';

class Sessao {
  Sessao({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : auth = auth ?? FirebaseAuth.instance,
      firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  User? get usuario => auth.currentUser;
  Future<bool> prepararAcesso() async {
    final user = usuario;
    if (user == null || !emailPermitido(user.email ?? '')) return false;
    final ref = firestore.collection('usuarios').doc(user.uid);
    await firestore.runTransaction((transaction) async {
      if (!(await transaction.get(ref)).exists) {
        final nome = user.displayName?.trim();
        final fallback = user.email!.split('@').first;
        transaction.set(ref, {
          'nome': nome != null && nome.isNotEmpty && nome.length <= 80
              ? nome
              : fallback,
          'curso': '',
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
    });
    return true;
  }

  Future<void> cadastrar(String nome, String email, String senha) async {
    _validarEmail(email);
    _validarPerfil(nome, '');
    if (senha.length < 6) {
      throw ArgumentError('Use uma senha com pelo menos 6 caracteres.');
    }
    final credencial = await auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: senha,
    );
    final nomeLimpo = nome.trim();
    await credencial.user!.updateDisplayName(nomeLimpo);
    // O portão (authStateChanges) pode criar o perfil com o pedaço do e-mail
    // antes do updateDisplayName terminar; aqui o nome digitado vence.
    final ref = firestore.collection('usuarios').doc(credencial.user!.uid);
    await firestore.runTransaction((transaction) async {
      if ((await transaction.get(ref)).exists) {
        transaction.update(ref, {'nome': nomeLimpo});
      } else {
        transaction.set(ref, {
          'nome': nomeLimpo,
          'curso': '',
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> entrar(String email, String senha) async {
    _validarEmail(email);
    await auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: senha,
    );
  }

  Future<void> salvarPerfil(String nome, String curso) async {
    _validarPerfil(nome, curso);
    final user = usuario;
    if (user == null || !emailPermitido(user.email ?? '')) {
      throw StateError('Entre com seu e-mail acadêmico.');
    }
    await firestore.collection('usuarios').doc(user.uid).update({
      'nome': nome.trim(),
      'curso': curso.trim(),
    });
  }

  Future<void> sair() => auth.signOut();

  void _validarEmail(String email) {
    if (!emailPermitido(email)) {
      throw ArgumentError(avisoDominio);
    }
  }

  void _validarPerfil(String nome, String curso) {
    if (nome.trim().isEmpty ||
        nome.trim().length > 80 ||
        curso.trim().length > 120) {
      throw ArgumentError(
        'Informe um nome de até 80 caracteres e curso de até 120.',
      );
    }
  }
}

String mensagemDeErro(Object erro) {
  if (erro is ArgumentError) return erro.message.toString();
  if (erro is StateError) return erro.message;
  if (erro is FirebaseAuthException) {
    return switch (erro.code) {
      'email-already-in-use' => 'Este e-mail já tem cadastro. Use Entrar.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'E-mail ou senha incorretos.',
      'weak-password' => 'Use uma senha com pelo menos 6 caracteres.',
      'too-many-requests' =>
        'Muitas tentativas. Aguarde um pouco e tente novamente.',
      'network-request-failed' => 'Confira a conexão e tente novamente.',
      _ => 'Não foi possível entrar. Confira os dados e tente novamente.',
    };
  }
  return 'Não foi possível concluir. Confira a conexão e tente novamente.';
}
