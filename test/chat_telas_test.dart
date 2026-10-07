// Testes das telas do chat (conversa, aba Mensagens e barra de abas), com
// duas pessoas de mentira usando o mesmo Firestore de mentira.

import 'package:achei_no_campus/modelos/item.dart';
import 'package:achei_no_campus/sessao.dart';
import 'package:achei_no_campus/telas/conversa.dart';
import 'package:achei_no_campus/telas/detalhe.dart';
import 'package:achei_no_campus/telas/inicio.dart';
import 'package:achei_no_campus/telas/mensagens.dart';
import 'package:achei_no_campus/telas/meus_itens.dart';
import 'package:achei_no_campus/tema.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late FakeFirebaseFirestore banco;
  late Sessao ana; // dona do fone
  late Sessao bruno; // achou que é dele
  late Item fone;

  Sessao sessaoDe(String uid) => Sessao(
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

  setUp(() async {
    banco = FakeFirebaseFirestore();
    ana = sessaoDe('ana');
    bruno = sessaoDe('bruno');
    await banco.doc('usuarios/ana').set({'nome': 'Ana'});
    await banco.doc('usuarios/bruno').set({'nome': 'Bruno'});
    final dados = {
      'tipo': 'perdido',
      'titulo': 'Fone de ouvido',
      'categoria': 'Eletrônicos',
      'local': 'Biblioteca',
      'autorId': 'ana',
      'autorNome': 'Ana',
      'status': 'aberto',
      'criadoEm': DateTime(2026, 10, 6, 9),
    };
    await banco.doc('itens/fone').set(dados);
    fone = Item.deMapa('fone', dados);
  });

  Future<void> abrir(WidgetTester tester, Widget tela) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // A key nova faz o app começar do zero a cada pessoa, sem herdar as
    // telas abertas pela pessoa anterior.
    await tester.pumpWidget(
      MaterialApp(key: UniqueKey(), theme: temaAchei(), home: tela),
    );
    await tester.pumpAndSettle();
  }

  Future<Map<String, dynamic>> naoLidas() async => Map<String, dynamic>.from(
    (await banco.doc('conversas/fone_bruno').get()).data()!['naoLidas'],
  );

  testWidgets(
    'critério de pronto: os dois conversam e o contador sobe e zera',
    (tester) async {
      // 1. O Bruno abre o detalhe do fone e toca em Conversar.
      await abrir(
        tester,
        TelaDetalhe(item: fone, sessao: bruno, uidDoUsuario: 'bruno'),
      );
      await tester.tap(find.text('Conversar'));
      await tester.pumpAndSettle();

      expect(find.byType(TelaConversa), findsOneWidget);
      expect(find.textContaining('Mande a primeira mensagem'), findsOneWidget);

      // 2. Ele escreve e envia.
      await tester.enterText(find.byType(TextField), 'Oi, acho que é meu!');
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pumpAndSettle();

      expect(find.text('Oi, acho que é meu!'), findsOneWidget);
      expect(await naoLidas(), {'ana': 1, 'bruno': 0});

      // 3. A Ana entra no app: a aba Mensagens mostra 1 não lida.
      await abrir(tester, TelaInicio(sessao: ana));
      final abaMensagens = find.ancestor(
        of: find.text('Mensagens'),
        matching: find.byType(NavigationDestination),
      );
      expect(
        find.descendant(of: abaMensagens, matching: find.text('1')),
        findsOneWidget,
      );

      // 4. Na aba, a conversa aparece com o item, o nome e a mensagem.
      await tester.tap(find.text('Mensagens'));
      await tester.pumpAndSettle();
      expect(find.text('Fone de ouvido'), findsOneWidget);
      expect(find.text('com Bruno · Oi, acho que é meu!'), findsOneWidget);

      // 5. Ela abre a conversa: o contador dela zera.
      await tester.tap(find.text('Fone de ouvido'));
      await tester.pumpAndSettle();
      expect(find.text('Oi, acho que é meu!'), findsOneWidget);
      expect(await naoLidas(), {'ana': 0, 'bruno': 0});

      // 6. Ela responde: agora o Bruno tem 1 para ler.
      await tester.enterText(find.byType(TextField), 'É seu sim! Passa aqui.');
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pumpAndSettle();
      expect(find.text('É seu sim! Passa aqui.'), findsOneWidget);
      expect(await naoLidas(), {'ana': 0, 'bruno': 1});

      // 7. De volta às abas, o número da Ana sumiu.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: abaMensagens, matching: find.text('1')),
        findsNothing,
      );
    },
  );

  testWidgets('Conversar no mesmo item abre a mesma conversa', (tester) async {
    await abrir(
      tester,
      TelaDetalhe(item: fone, sessao: bruno, uidDoUsuario: 'bruno'),
    );
    await tester.tap(find.text('Conversar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Primeira');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();

    // Volta e toca de novo em Conversar.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conversar'));
    await tester.pumpAndSettle();

    expect(find.text('Primeira'), findsOneWidget);
    expect((await banco.collection('conversas').get()).docs, hasLength(1));
  });

  testWidgets('mensagem em branco não é enviada', (tester) async {
    await abrir(
      tester,
      TelaDetalhe(item: fone, sessao: bruno, uidDoUsuario: 'bruno'),
    );
    await tester.tap(find.text('Conversar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '    ');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();

    expect((await banco.collection('conversas').get()).docs, isEmpty);
  });

  testWidgets('aba Mensagens vazia explica como começar', (tester) async {
    await abrir(tester, TelaMensagens(sessao: bruno));

    expect(find.textContaining('Nenhuma conversa ainda'), findsOneWidget);
  });

  testWidgets('as abas trocam entre Feed, Mensagens e Meus itens', (
    tester,
  ) async {
    await abrir(tester, TelaInicio(sessao: ana));
    expect(find.text('Achei no Campus'), findsOneWidget);

    await tester.tap(find.text('Meus itens'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(TelaMeusItens),
        matching: find.text('Fone de ouvido'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Mensagens'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nenhuma conversa ainda'), findsOneWidget);
  });

  test('hora curta da lista de conversas', () {
    final agora = DateTime(2026, 10, 6, 18);
    expect(horaCurta(DateTime(2026, 10, 6, 9, 5), agora: agora), '09:05');
    expect(horaCurta(DateTime(2026, 10, 5, 22), agora: agora), 'ontem');
    expect(horaCurta(DateTime(2026, 9, 30, 10), agora: agora), '30/09');
  });
}
