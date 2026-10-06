import 'dart:async';

import 'package:achei_no_campus/dados/itens_exemplo.dart';
import 'package:achei_no_campus/modelos/item.dart';
import 'package:achei_no_campus/telas/feed.dart';
import 'package:achei_no_campus/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Abre o feed com os itens que o teste mandar, em vez do Firestore.
  Future<void> abrirFeed(WidgetTester tester, Stream<List<Item>> itens) {
    return tester.pumpWidget(
      MaterialApp(
        theme: temaAchei(),
        home: TelaFeed(itens: itens),
        routes: {'/publicar': (_) => const Text('tela de publicar')},
      ),
    );
  }

  testWidgets('mostra o carregando enquanto os itens não chegam', (
    tester,
  ) async {
    await abrirFeed(tester, StreamController<List<Item>>().stream);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('mostra o aviso quando não há nenhum item', (tester) async {
    await abrirFeed(tester, Stream.value([]));
    await tester.pump();

    expect(find.textContaining('Nenhum item ainda'), findsOneWidget);
  });

  testWidgets('mostra o aviso de erro se a leitura falhar', (tester) async {
    await abrirFeed(tester, Stream.error('sem internet'));
    await tester.pump();

    expect(find.textContaining('Não foi possível carregar'), findsOneWidget);
  });

  testWidgets('cada card mostra título, etiqueta, categoria, local e tempo', (
    tester,
  ) async {
    await abrirFeed(tester, Stream.value(itensDeExemplo()));
    await tester.pump();

    expect(find.text('Fone de ouvido branco'), findsOneWidget);
    expect(find.text('Achado'), findsWidgets);
    expect(find.text('Perdido'), findsWidgets);
    expect(find.text('Eletrônicos · Biblioteca'), findsOneWidget);
    expect(find.text('há 12 min'), findsOneWidget);
  });

  testWidgets('item publicado aparece sem recarregar (tempo real)', (
    tester,
  ) async {
    final firestoreDeMentira = StreamController<List<Item>>();
    await abrirFeed(tester, firestoreDeMentira.stream);

    final antes = itensDeExemplo();
    firestoreDeMentira.add(antes);
    await tester.pump();
    expect(find.text('Celular preto'), findsNothing);

    // Outro usuário publica: o Firestore manda a lista nova, com ele no topo.
    final novo = Item.deMapa('novo', {
      'tipo': 'perdido',
      'titulo': 'Celular preto',
      'categoria': 'Eletrônicos',
      'local': 'Reitoria',
      'criadoEm': DateTime.now(),
    });
    firestoreDeMentira.add([novo, ...antes]);
    await tester.pump();

    expect(find.text('Celular preto'), findsOneWidget);
    await firestoreDeMentira.close();
  });

  testWidgets('o botão Publicar abre a tela de publicar', (tester) async {
    await abrirFeed(tester, Stream.value([]));
    await tester.pump();

    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(find.text('tela de publicar'), findsOneWidget);
  });
}
