import 'dart:async';

import 'package:achei_no_campus/modelos/item.dart';
import 'package:achei_no_campus/telas/meus_itens.dart';
import 'package:achei_no_campus/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Item item(
    String id,
    String titulo, {
    required String autor,
    String status = 'aberto',
    int diasAtras = 0,
  }) {
    return Item.deMapa(id, {
      'tipo': 'achado',
      'titulo': titulo,
      'categoria': 'Outros',
      'local': 'Biblioteca',
      'autorId': autor,
      'autorNome': autor,
      'status': status,
      'criadoEm': DateTime.now().subtract(Duration(days: diasAtras)),
    });
  }

  void telaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> abrir(
    WidgetTester tester,
    Stream<List<Item>> itens, {
    String uid = 'ana',
    Future<void> Function(String)? devolver,
  }) async {
    telaAlta(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: temaAchei(),
        home: TelaMeusItens(
          uidDoUsuario: uid,
          itens: itens,
          devolver: devolver,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('critério de pronto: cada usuário vê só os próprios itens', (
    tester,
  ) async {
    await abrir(
      tester,
      Stream.value([
        item('1', 'Fone da Ana', autor: 'ana'),
        item('2', 'Chave do Bruno', autor: 'bruno'),
        item('3', 'Caderno da Ana', autor: 'ana', status: 'devolvido'),
      ]),
    );

    expect(find.text('Fone da Ana'), findsOneWidget);
    expect(find.text('Caderno da Ana'), findsOneWidget);
    expect(find.text('Chave do Bruno'), findsNothing);
  });

  testWidgets('mostra a etiqueta do status em cada item', (tester) async {
    await abrir(
      tester,
      Stream.value([
        item('1', 'Fone', autor: 'ana'),
        item('2', 'Caderno', autor: 'ana', status: 'devolvido'),
      ]),
    );

    expect(find.text('Aberto'), findsOneWidget);
    expect(find.text('Devolvido'), findsWidgets);
  });

  test('abertos vêm antes dos devolvidos, mais recentes primeiro', () {
    final ordem = ordenarMeusItens([
      item('velho', 'Velho', autor: 'ana', diasAtras: 5),
      item('devolvido', 'Devolvido', autor: 'ana', status: 'devolvido'),
      item('novo', 'Novo', autor: 'ana'),
    ]);

    expect(ordem.map((i) => i.id), ['novo', 'velho', 'devolvido']);
  });

  testWidgets('item devolvido não tem o botão Marcar devolvido', (
    tester,
  ) async {
    await abrir(
      tester,
      Stream.value([item('1', 'Caderno', autor: 'ana', status: 'devolvido')]),
    );

    expect(find.widgetWithText(TextButton, 'Marcar devolvido'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Editar'), findsOneWidget);
  });

  testWidgets(
    'critério de pronto: marcado aqui, o item passa a aparecer como devolvido',
    (tester) async {
      // Firestore de mentira: ao devolver, manda a lista com o status novo.
      final itens = [item('1', 'Fone', autor: 'ana')];
      final firestoreDeMentira = StreamController<List<Item>>();

      Future<void> devolver(String id) async {
        final antigo = itens.single;
        itens[0] = Item.deMapa(id, {
          ...antigo.paraMapa(),
          'status': 'devolvido',
        });
        firestoreDeMentira.add(List.of(itens));
      }

      await abrir(tester, firestoreDeMentira.stream, devolver: devolver);
      firestoreDeMentira.add(List.of(itens));
      await tester.pump();
      expect(find.text('Aberto'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Marcar devolvido'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Marcar como devolvido'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aberto'), findsNothing);
      expect(find.text('Devolvido'), findsOneWidget); // só a etiqueta
      expect(find.text('Item marcado como devolvido.'), findsOneWidget);

      await firestoreDeMentira.close();
    },
  );

  testWidgets('sem itens, mostra o aviso', (tester) async {
    await abrir(tester, Stream.value([]));

    expect(find.textContaining('ainda não publicou'), findsOneWidget);
  });

  testWidgets('Editar avisa enquanto a edição não existe', (tester) async {
    await abrir(tester, Stream.value([item('1', 'Fone', autor: 'ana')]));

    await tester.tap(find.text('Editar'));
    await tester.pump();

    expect(find.text('A edição ainda está sendo feita.'), findsOneWidget);
  });
}
