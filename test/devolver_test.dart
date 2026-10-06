import 'dart:async';

import 'package:achei_no_campus/dados/itens_exemplo.dart';
import 'package:achei_no_campus/modelos/item.dart';
import 'package:achei_no_campus/telas/detalhe.dart';
import 'package:achei_no_campus/telas/feed.dart';
import 'package:achei_no_campus/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Item itemDa(String autorId, {String status = 'aberto'}) {
    return Item.deMapa('chave', {
      'tipo': 'perdido',
      'titulo': 'Chave do carro',
      'categoria': 'Chaves',
      'local': 'Estacionamento',
      'autorId': autorId,
      'autorNome': 'Ana',
      'status': status,
    });
  }

  void telaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> abrirDetalhe(
    WidgetTester tester,
    Item item, {
    required String uid,
    Future<void> Function(String)? devolver,
  }) async {
    telaAlta(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: temaAchei(),
        home: TelaDetalhe(item: item, uidDoUsuario: uid, devolver: devolver),
      ),
    );
  }

  testWidgets('o dono vê Marcar como devolvido, e não Conversar', (
    tester,
  ) async {
    await abrirDetalhe(tester, itemDa('ana'), uid: 'ana');

    expect(find.text('Marcar como devolvido'), findsOneWidget);
    expect(find.text('Conversar'), findsNothing);
  });

  testWidgets('outra pessoa não vê Marcar como devolvido', (tester) async {
    await abrirDetalhe(tester, itemDa('ana'), uid: 'bruno');

    expect(find.text('Marcar como devolvido'), findsNothing);
    expect(find.text('Conversar'), findsOneWidget);
  });

  testWidgets('pede confirmação, e Cancelar não muda nada', (tester) async {
    var chamadas = 0;
    await abrirDetalhe(
      tester,
      itemDa('ana'),
      uid: 'ana',
      devolver: (_) async => chamadas++,
    );

    await tester.tap(find.text('Marcar como devolvido'));
    await tester.pumpAndSettle();
    expect(find.text('Marcar como devolvido?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(chamadas, 0);
    expect(find.text('Marcar como devolvido?'), findsNothing);
  });

  testWidgets('se der erro, avisa e continua no detalhe', (tester) async {
    await abrirDetalhe(
      tester,
      itemDa('ana'),
      uid: 'ana',
      devolver: (_) async => throw Exception('sem internet'),
    );

    await tester.tap(find.text('Marcar como devolvido'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Marcar como devolvido').last,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Não foi possível marcar'), findsOneWidget);
    expect(find.byType(TelaDetalhe), findsOneWidget);
  });

  testWidgets('item já devolvido mostra o aviso e nenhum botão', (
    tester,
  ) async {
    await abrirDetalhe(tester, itemDa('ana', status: 'devolvido'), uid: 'ana');

    expect(find.text('Este item já foi devolvido.'), findsOneWidget);
    expect(find.text('Marcar como devolvido'), findsNothing);
    expect(find.text('Conversar'), findsNothing);
  });

  testWidgets('critério de pronto: depois de marcar, o item some do feed', (
    tester,
  ) async {
    telaAlta(tester);

    // Um Firestore de mentira: guarda a lista e manda a versão nova ao feed
    // quando um item é devolvido, como o Firestore de verdade faz.
    final itens = itensDeExemplo();
    final firestoreDeMentira = StreamController<List<Item>>();
    String? devolvido;

    Future<void> devolver(String id) async {
      devolvido = id;
      itens.removeWhere((item) => item.id == id);
      firestoreDeMentira.add(List.of(itens));
    }

    // O usuário é o autor dos itens de exemplo.
    await tester.pumpWidget(
      MaterialApp(
        theme: temaAchei(),
        home: TelaFeed(
          itens: firestoreDeMentira.stream,
          uidDoUsuario: 'aluno-exemplo',
          devolver: devolver,
        ),
      ),
    );
    firestoreDeMentira.add(List.of(itens));
    await tester.pump();

    // Abre a carteira, toca em Marcar como devolvido e confirma.
    await tester.tap(find.text('Carteira marrom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar como devolvido'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Marcar como devolvido').last,
    );
    await tester.pumpAndSettle();

    expect(devolvido, '4'); // id da carteira nos itens de exemplo
    // Voltou ao feed, com o aviso, e a carteira não está mais lá.
    expect(find.byType(TelaFeed), findsOneWidget);
    expect(find.byType(TelaDetalhe), findsNothing);
    expect(find.text('Item marcado como devolvido.'), findsOneWidget);
    expect(find.text('Carteira marrom'), findsNothing);
    expect(find.text('Fone de ouvido branco'), findsOneWidget);

    await firestoreDeMentira.close();
  });
}
