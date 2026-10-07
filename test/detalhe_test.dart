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

  final item = Item.deMapa('fone', {
    'tipo': 'achado',
    'titulo': 'Fone de ouvido branco',
    'descricao': 'Estava em cima da mesa 12, no segundo andar.',
    'categoria': 'Eletrônicos',
    'local': 'Biblioteca',
    'autorId': 'ana',
    'autorNome': 'Ana Souza',
    'criadoEm': DateTime(2026, 10, 6, 14, 30),
  });

  Future<void> abrirDetalhe(WidgetTester tester, {required String uid}) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: temaAchei(),
        home: TelaDetalhe(item: item, uidDoUsuario: uid),
      ),
    );
  }

  testWidgets('mostra todos os dados do item', (tester) async {
    await abrirDetalhe(tester, uid: 'bruno');

    expect(find.text('Item achado'), findsOneWidget);
    expect(find.text('Achado'), findsOneWidget);
    expect(find.text('Fone de ouvido branco'), findsOneWidget);
    expect(find.textContaining('mesa 12'), findsOneWidget);
    expect(find.text('Eletrônicos'), findsOneWidget);
    expect(find.text('Achado em'), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.textContaining('06/10/2026 às 14:30'), findsOneWidget);
    expect(find.text('Ana Souza'), findsOneWidget);
  });

  testWidgets('outra pessoa vê o botão Conversar', (tester) async {
    await abrirDetalhe(tester, uid: 'bruno');

    // O que acontece ao tocar está em chat_telas_test.dart.
    expect(find.text('Conversar'), findsOneWidget);
  });

  testWidgets('o autor não vê o botão Conversar', (tester) async {
    await abrirDetalhe(tester, uid: 'ana');

    expect(find.text('Conversar'), findsNothing);
    expect(find.text('Ana Souza (você)'), findsOneWidget);
  });

  testWidgets('tocar num card do feed abre o detalhe certo', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: temaAchei(),
        home: TelaFeed(
          itens: Stream.value(itensDeExemplo()),
          uidDoUsuario: 'bruno',
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Garrafa térmica azul'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDetalhe), findsOneWidget);
    expect(find.text('Item achado'), findsOneWidget);
    expect(find.text('Ginásio'), findsOneWidget);
    expect(find.text('Conversar'), findsOneWidget);
  });

  test('data e hora por extenso', () {
    final agora = DateTime(2026, 10, 6, 16, 30);
    expect(
      dataEHora(DateTime(2026, 10, 6, 14, 5), agora: agora),
      '06/10/2026 às 14:05 (há 2 h)',
    );
  });
}
