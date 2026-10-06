// Testes dos filtros e da busca dentro da tela do feed, tocando nos chips e
// digitando, como o usuário faria.

import 'package:achei_no_campus/dados/itens_exemplo.dart';
import 'package:achei_no_campus/telas/feed.dart';
import 'package:achei_no_campus/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Os itens de exemplo são: Fone (achado, Biblioteca), Chave (perdido),
  // Garrafa (achado, Ginásio), Carteira (perdido) e Caderno (achado).
  Future<void> abrirFeed(WidgetTester tester) async {
    // Tela alta, para todos os cards caberem sem rolar.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: temaAchei(),
        home: TelaFeed(itens: Stream.value(itensDeExemplo())),
      ),
    );
    await tester.pump();
  }

  testWidgets('chip Perdidos mostra só os perdidos', (tester) async {
    await abrirFeed(tester);

    await tester.tap(find.text('Perdidos'));
    await tester.pump();

    expect(find.text('Chave com chaveiro do Flamengo'), findsOneWidget);
    expect(find.text('Carteira marrom'), findsOneWidget);
    expect(find.text('Fone de ouvido branco'), findsNothing);
  });

  testWidgets('chip Local abre a lista e filtra pelo escolhido', (
    tester,
  ) async {
    await abrirFeed(tester);

    await tester.tap(find.text('Local'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Ginásio'));
    await tester.pumpAndSettle();

    expect(find.text('Garrafa térmica azul'), findsOneWidget);
    expect(find.text('Fone de ouvido branco'), findsNothing);
    // O chip passa a mostrar o local escolhido.
    expect(find.widgetWithText(FilterChip, 'Ginásio'), findsOneWidget);
  });

  testWidgets('busca sem acento acha título com acento', (tester) async {
    await abrirFeed(tester);

    await tester.enterText(find.byType(TextField), 'TERMICA');
    await tester.pump();

    expect(find.text('Garrafa térmica azul'), findsOneWidget);
    expect(find.text('Carteira marrom'), findsNothing);
  });

  testWidgets('filtro sem resultado mostra aviso, e Limpar volta tudo', (
    tester,
  ) async {
    await abrirFeed(tester);

    await tester.tap(find.text('Perdidos'));
    await tester.enterText(find.byType(TextField), 'fone');
    await tester.pump();

    expect(find.text('Nenhum item com esses filtros.'), findsOneWidget);

    await tester.tap(find.text('Limpar filtros'));
    await tester.pump();

    expect(find.text('Fone de ouvido branco'), findsOneWidget);
    expect(find.text('Carteira marrom'), findsOneWidget);
    // O texto digitado também some.
    expect(find.text('fone'), findsNothing);
  });
}
