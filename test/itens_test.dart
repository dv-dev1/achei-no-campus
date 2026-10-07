import 'package:achei_no_campus/itens.dart';
import 'package:achei_no_campus/modelos/item.dart';
import 'package:achei_no_campus/sessao.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late Sessao sessao;
  late Itens itens;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    sessao = Sessao(
      auth: MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'ana',
          email: 'ana@cs.unipe.edu.br',
          isEmailVerified: true,
          displayName: 'Ana',
        ),
        signedIn: true,
      ),
      firestore: firestore,
    );
    itens = Itens(sessao: sessao);
    await firestore.collection('usuarios').doc('ana').set({
      'nome': 'Ana Silva',
      'curso': '',
      'criadoEm': Timestamp.now(),
    });
  });

  Future<String> publicar({Item? item, String titulo = 'Garrafa azul'}) =>
      itens.salvar(
        item: item,
        tipo: 'achado',
        titulo: titulo,
        descricao: '',
        categoria: 'Garrafa/Copo',
        local: 'Biblioteca',
        fotoUrl: '',
      );

  test('publica sem foto com nome atual do perfil e schema de Cauê', () async {
    final id = await publicar();
    final dados = (await firestore.collection('itens').doc(id).get()).data()!;
    expect(dados['titulo'], 'Garrafa azul');
    expect(dados['fotoUrl'], '');
    expect(dados['autorNome'], 'Ana Silva');
    expect(dados['autorId'], 'ana');
    expect(dados['status'], 'aberto');
    expect(dados['criadoEm'], isA<Timestamp>());
  });

  test('edita conteúdo preservando autoria, data e devolução', () async {
    final id = await publicar();
    final ref = firestore.collection('itens').doc(id);
    await ref.update({'status': 'devolvido'});
    final antes = (await ref.get()).data()!;
    await sessao.salvarPerfil('Ana Nova', 'Computação');
    await publicar(item: Item.deMapa(id, antes), titulo: 'Garrafa verde');
    final depois = (await ref.get()).data()!;
    expect(depois['titulo'], 'Garrafa verde');
    for (final campo in ['autorId', 'autorNome', 'criadoEm', 'status']) {
      expect(depois[campo], antes[campo], reason: campo);
    }
  });

  test('nega título vazio e edição de item alheio', () async {
    await expectLater(publicar(titulo: ' '), throwsArgumentError);
    final id = await publicar();
    final ref = firestore.collection('itens').doc(id);
    await ref.update({'autorId': 'bruno'});
    final item = Item.deMapa(id, (await ref.get()).data()!);
    await expectLater(publicar(item: item), throwsA(isA<StateError>()));
    await expectLater(itens.apagar(id), throwsA(isA<StateError>()));
    expect((await ref.get()).exists, isTrue);
  });

  test('apaga item próprio', () async {
    final id = await publicar();
    await itens.apagar(id);
    expect((await firestore.collection('itens').doc(id).get()).exists, isFalse);
  });
}
