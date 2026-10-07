import 'package:achei_no_campus/sessao.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

// User muda no reload; a anotação de imutabilidade vem do mock.
// ignore: must_be_immutable
class UsuarioVerificavel extends MockUser {
  UsuarioVerificavel({this.verificado = false})
    : super(uid: 'ana', email: 'ana@cs.unipe.edu.br', displayName: 'Ana');

  bool verificado;
  bool verificarNoReload = false;
  final eventos = <String>[];

  @override
  bool get emailVerified => verificado;

  @override
  Future<void> reload() async {
    eventos.add('reload');
    if (verificarNoReload) verificado = true;
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

void main() {
  test('não cria perfil nem libera feed antes da verificação', () async {
    final user = UsuarioVerificavel();
    final firestore = FakeFirebaseFirestore();
    final sessao = Sessao(
      auth: MockFirebaseAuth(mockUser: user, signedIn: true),
      firestore: firestore,
    );
    expect(await sessao.prepararAcesso(), isFalse);
    expect((await firestore.collection('usuarios').get()).docs, isEmpty);
  });

  test(
    'verificação externa exige reload e token novo antes do perfil',
    () async {
      final user = UsuarioVerificavel()..verificarNoReload = true;
      final firestore = FakeFirebaseFirestore();
      final sessao = Sessao(
        auth: MockFirebaseAuth(mockUser: user, signedIn: true),
        firestore: firestore,
      );
      expect(await sessao.prepararAcesso(), isTrue);
      expect(user.eventos.take(2), ['reload', 'token:true']);
      final perfil = (await firestore.collection('usuarios').doc('ana').get())
          .data()!;
      expect(perfil['nome'], 'Ana');
      expect(perfil['curso'], '');
      expect(perfil['criadoEm'], isNotNull);
    },
  );

  test('novo acesso preserva perfil já editado', () async {
    final user = UsuarioVerificavel(verificado: true);
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

  test('reenviar verificação e sair atuam na sessão atual', () async {
    final user = UsuarioVerificavel();
    final sessao = Sessao(
      auth: MockFirebaseAuth(mockUser: user, signedIn: true),
      firestore: FakeFirebaseFirestore(),
    );
    await sessao.reenviarVerificacao();
    expect(user.eventos, ['verificacao']);
    await sessao.sair();
    expect(sessao.usuario, isNull);
  });
}
