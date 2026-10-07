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
    await usuario?.reload();
    final user = usuario;
    if (user == null ||
        !user.emailVerified ||
        !emailPermitido(user.email ?? '')) {
      return false;
    }
    await user.getIdToken(true);
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
    await credencial.user!.updateDisplayName(nome.trim());
    await credencial.user!.sendEmailVerification();
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
    if (user == null ||
        !user.emailVerified ||
        !emailPermitido(user.email ?? '')) {
      throw StateError('Entre com um e-mail acadêmico verificado.');
    }
    await firestore.collection('usuarios').doc(user.uid).update({
      'nome': nome.trim(),
      'curso': curso.trim(),
    });
  }

  Future<void> reenviarVerificacao() async {
    final user = usuario;
    if (user == null) {
      throw StateError('Entre novamente para verificar seu e-mail.');
    }
    await user.sendEmailVerification();
  }

  Future<void> sair() => auth.signOut();

  void _validarEmail(String email) {
    if (!emailPermitido(email)) {
      throw ArgumentError('Use seu e-mail @cs.unipe.edu.br.');
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
