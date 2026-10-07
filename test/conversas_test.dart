import 'package:achei_no_campus/conversas.dart';
import 'package:achei_no_campus/modelos/conversa.dart';
import 'package:achei_no_campus/modelos/item.dart';
import 'package:achei_no_campus/sessao.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sessão de mentira de um aluno, toda num Firestore compartilhado.
Sessao sessaoDe(String uid, FakeFirebaseFirestore banco) {
  return Sessao(
    auth: MockFirebaseAuth(
      mockUser: MockUser(
        uid: uid,
        email: '$uid@cs.unipe.edu.br',
        isEmailVerified: true,
      ),
      signedIn: true,
    ),
    firestore: banco,
  );
}

void main() {
  late FakeFirebaseFirestore banco;
  late Conversas daAna; // dona do item
  late Conversas doBruno; // interessado
  late Item fone;

  setUp(() async {
    banco = FakeFirebaseFirestore();
    daAna = Conversas(sessao: sessaoDe('ana', banco));
    doBruno = Conversas(sessao: sessaoDe('bruno', banco));

    await banco.collection('usuarios').doc('ana').set({'nome': 'Ana'});
    await banco.collection('usuarios').doc('bruno').set({'nome': 'Bruno'});
    await banco.collection('itens').doc('fone').set({
      'tipo': 'achado',
      'titulo': 'Fone de ouvido',
      'autorId': 'ana',
      'autorNome': 'Ana',
      'status': 'aberto',
    });
    fone = Item.deMapa(
      'fone',
      (await banco.collection('itens').doc('fone').get()).data()!,
    );
  });

  test('o ID da conversa é item + interessado', () {
    final conversa = Conversa.nova(fone, 'bruno');

    expect(conversa.id, 'fone_bruno');
    expect(conversa.participantes, ['ana', 'bruno']);
    expect(conversa.outro('bruno'), 'ana');
    expect(conversa.outro('ana'), 'bruno');
  });

  test('a primeira mensagem cria a conversa no formato das regras', () async {
    await doBruno.enviar(
      Conversa.nova(fone, 'bruno'),
      '  Oi, é meu!  ',
      jaExiste: false,
    );

    final dados = (await banco.doc('conversas/fone_bruno').get()).data()!;
    expect(dados.keys.toSet(), {
      'itemId',
      'participantes',
      'ultimaMensagem',
      'atualizadoEm',
      'naoLidas',
    });
    expect(dados['participantes'], ['ana', 'bruno']);
    expect(dados['ultimaMensagem'], 'Oi, é meu!');
    expect(dados['naoLidas'], {'bruno': 0, 'ana': 1});

    final mensagens = await doBruno.mensagens('fone_bruno').first;
    expect(mensagens.single.texto, 'Oi, é meu!');
    expect(mensagens.single.autorId, 'bruno');
  });

  test(
    'critério de pronto: o contador sobe para quem recebe e zera ao abrir',
    () async {
      final nova = Conversa.nova(fone, 'bruno');
      await doBruno.enviar(nova, 'Oi', jaExiste: false);
      await doBruno.enviar(nova, 'Ainda está com você?', jaExiste: true);

      expect(await daAna.totalNaoLidas().first, 2);
      expect(await doBruno.totalNaoLidas().first, 0);

      // A Ana abre a conversa.
      final daVisaoDaAna = (await daAna.minhas().first).single;
      await daAna.marcarComoLida(daVisaoDaAna);
      expect(await daAna.totalNaoLidas().first, 0);

      // Ela responde: agora é o Bruno que tem 1 para ler.
      await daAna.enviar(daVisaoDaAna, 'Está sim!', jaExiste: true);
      expect(await doBruno.totalNaoLidas().first, 1);
      expect(await daAna.totalNaoLidas().first, 0);

      final textos = (await daAna.mensagens('fone_bruno').first)
          .map((m) => m.texto)
          .toList();
      expect(textos, ['Oi', 'Ainda está com você?', 'Está sim!']);
    },
  );

  test('cada um vê só as próprias conversas', () async {
    await banco.collection('usuarios').doc('carla').set({'nome': 'Carla'});
    final daCarla = Conversas(sessao: sessaoDe('carla', banco));

    await doBruno.enviar(Conversa.nova(fone, 'bruno'), 'Oi', jaExiste: false);
    await daCarla.enviar(Conversa.nova(fone, 'carla'), 'Olá', jaExiste: false);

    expect((await doBruno.minhas().first).map((c) => c.id), ['fone_bruno']);
    expect((await daCarla.minhas().first).map((c) => c.id), ['fone_carla']);
    // A dona do item vê as duas.
    expect((await daAna.minhas().first).map((c) => c.id).toSet(), {
      'fone_bruno',
      'fone_carla',
    });
  });

  test('não envia mensagem vazia nem longa demais', () async {
    final nova = Conversa.nova(fone, 'bruno');

    expect(
      () => doBruno.enviar(nova, '   ', jaExiste: false),
      throwsArgumentError,
    );
    expect(
      () => doBruno.enviar(nova, 'a' * 5001, jaExiste: false),
      throwsArgumentError,
    );
    expect((await banco.collection('conversas').get()).docs, isEmpty);
  });

  test('busca o título do item e o nome do outro participante', () async {
    expect((await doBruno.item('fone'))?.titulo, 'Fone de ouvido');
    expect(await doBruno.item('apagado'), isNull);
    expect(await doBruno.nomeDe('ana'), 'Ana');
    expect(await doBruno.nomeDe('sem-perfil'), 'Alguém');
  });
}
