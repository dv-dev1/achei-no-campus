import 'package:achei_no_campus/sessao.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

// User muda no reload; a anotação de imutabilidade vem do mock.
// ignore: must_be_immutable
class UsuarioEspia extends MockUser {
  UsuarioEspia()
    : super(
        uid: 'ana',
        email: 'ana@cs.unipe.edu.br',
        displayName: 'Ana',
        isEmailVerified: false,
      );

  final eventos = <String>[];

  // Roda dentro do updateDisplayName: simula o portão chegando antes do fim
  // do cadastro (o authStateChanges dispara com o createUser).
  Future<void> Function()? aoAtualizarNome;

  @override
  Future<void> updateDisplayName(String? displayName) async {
    await aoAtualizarNome?.call();
    await super.updateDisplayName(displayName);
  }

  @override
  Future<void> reload() async {
    eventos.add('reload');
  }

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    eventos.add('token:$forceRefresh');
    return 'token-local';
  }

  @override
  Future<void> sendEmailVerification([dynamic actionCodeSettings]) async {
    eventos.add('verificacao');
  }
}

// O mock cria um usuário novo no cadastro; aqui o cadastro devolve o espião.
class AuthComEspia extends MockFirebaseAuth {
  AuthComEspia(UsuarioEspia espia) : super(mockUser: espia);

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) => signInWithEmailAndPassword(email: email, password: password);
}

void main() {
  test('cadastro não envia e-mail e prepararAcesso cria o perfil na primeira entrada', () async {
    final espia = UsuarioEspia();
    final firestore = FakeFirebaseFirestore();
    final sessao = Sessao(auth: AuthComEspia(espia), firestore: firestore);
    await sessao.cadastrar('Ana', 'ana@cs.unipe.edu.br', 'senha123');
    expect(espia.eventos, isNot(contains('verificacao')));

    expect(await sessao.prepararAcesso(), isTrue);
    expect(espia.eventos, isNot(contains('verificacao')));
    expect(espia.eventos, isNot(contains('token:true')));
    final perfil = (await firestore.collection('usuarios').doc('ana').get())
        .data()!;
    expect(perfil['nome'], 'Ana');
    expect(perfil['curso'], '');
    expect(perfil['criadoEm'], isNotNull);
  });

  test(
    'cadastro cria o perfil com o nome digitado quando não há perfil',
    () async {
      final espia = UsuarioEspia();
      final firestore = FakeFirebaseFirestore();
      final sessao = Sessao(auth: AuthComEspia(espia), firestore: firestore);
      await sessao.cadastrar(
        '  Lúcia Tester ',
        'ana@cs.unipe.edu.br',
        'senha123',
      );
      final perfil = (await firestore.collection('usuarios').doc('ana').get())
          .data()!;
      expect(perfil['nome'], 'Lúcia Tester');
      expect(perfil['curso'], '');
      expect(perfil['criadoEm'], isNotNull);
    },
  );

  test('cadastro corrige o perfil que o portão criou antes, sem mexer em curso e criadoEm', () async {
    final espia = UsuarioEspia();
    final firestore = FakeFirebaseFirestore();
    final criadoEm = Timestamp.fromDate(DateTime(2026, 11, 26, 10));
    espia.aoAtualizarNome = () => firestore
        .collection('usuarios')
        .doc('ana')
        .set({'nome': 'ana', 'curso': 'Computação', 'criadoEm': criadoEm});
    final sessao = Sessao(auth: AuthComEspia(espia), firestore: firestore);
    await sessao.cadastrar('Lúcia Tester', 'ana@cs.unipe.edu.br', 'senha123');
    final perfil = (await firestore.collection('usuarios').doc('ana').get())
        .data()!;
    expect(perfil['nome'], 'Lúcia Tester');
    expect(perfil['curso'], 'Computação');
    expect(perfil['criadoEm'], criadoEm);
  });

  test(
    'prepararAcesso recusa quem não está logado ou tem outro domínio',
    () async {
      final firestore = FakeFirebaseFirestore();
      final deslogado = Sessao(auth: MockFirebaseAuth(), firestore: firestore);
      expect(await deslogado.prepararAcesso(), isFalse);
      final externo = Sessao(
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: 'bia', email: 'bia@gmail.com'),
          signedIn: true,
        ),
        firestore: firestore,
      );
      expect(await externo.prepararAcesso(), isFalse);
      expect((await firestore.collection('usuarios').get()).docs, isEmpty);
    },
  );

  test('novo acesso preserva perfil já editado', () async {
    final user = MockUser(
      uid: 'ana',
      email: 'ana@cs.unipe.edu.br',
      displayName: 'Ana',
      isEmailVerified: false,
    );
    final firestore = FakeFirebaseFirestore();
    final sessao = Sessao(
      auth: MockFirebaseAuth(mockUser: user, signedIn: true),
      firestore: firestore,
    );
    await sessao.prepararAcesso();
    await sessao.salvarPerfil('Ana Silva', 'Computação');
    await sessao.prepararAcesso();
    final perfil = (await firestore.collection('usuarios').doc('ana').get())
        .data()!;
    expect(perfil['nome'], 'Ana Silva');
    expect(perfil['curso'], 'Computação');
    await expectLater(sessao.salvarPerfil('  ', ''), throwsArgumentError);
  });

  test('domínio externo e cadastro sem nome são recusados', () async {
    final sessao = Sessao(
      auth: MockFirebaseAuth(),
      firestore: FakeFirebaseFirestore(),
    );
    await expectLater(
      sessao.cadastrar('Ana', 'ana@gmail.com', 'senha123'),
      throwsArgumentError,
    );
    await expectLater(
      sessao.cadastrar(' ', 'ana@cs.unipe.edu.br', 'senha123'),
      throwsArgumentError,
    );
    await expectLater(
      sessao.entrar('ana@cs.unipe.edu.br.evil.com', 'senha123'),
      throwsArgumentError,
    );
  });

  test('sair encerra a sessão atual', () async {
    final sessao = Sessao(
      auth: MockFirebaseAuth(
        mockUser: MockUser(uid: 'ana', email: 'ana@cs.unipe.edu.br'),
        signedIn: true,
      ),
      firestore: FakeFirebaseFirestore(),
    );
    await sessao.sair();
    expect(sessao.usuario, isNull);
  });
}
