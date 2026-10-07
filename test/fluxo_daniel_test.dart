import 'package:achei_no_campus/main.dart';
import 'package:achei_no_campus/sessao.dart';
import 'package:achei_no_campus/telas/publicar.dart';
import 'package:achei_no_campus/telas/detalhe.dart';
import 'package:achei_no_campus/modelos/item.dart';
import 'package:achei_no_campus/tema.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  late Sessao sessao;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      mockUser: MockUser(
        uid: 'ana',
        email: 'ana@cs.unipe.edu.br',
        isEmailVerified: true,
        displayName: 'Ana',
      ),
      signedIn: true,
    );
    sessao = Sessao(auth: auth, firestore: firestore);
  });

  Future<void> abrir(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  testWidgets('sessão não verificada não chega ao feed nem cria perfil', (
    tester,
  ) async {
    final naoVerificado = Sessao(
      auth: MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'bruno',
          email: 'bruno@cs.unipe.edu.br',
          isEmailVerified: false,
        ),
        signedIn: true,
      ),
      firestore: firestore,
    );
    await abrir(tester, AppAchei(sessao: naoVerificado));
    expect(find.text('Verifique seu e-mail'), findsOneWidget);
    expect(find.text('Reenviar verificação'), findsOneWidget);
    expect(find.text('Achei no Campus'), findsNothing);
    expect((await firestore.collection('usuarios').get()).docs, isEmpty);
  });

  testWidgets('login recusa domínio externo sem autenticar', (tester) async {
    await sessao.sair();
    await abrir(tester, AppAchei(sessao: sessao));
    await tester.enterText(find.byKey(const Key('email')), 'ana@gmail.com');
    await tester.enterText(find.byKey(const Key('senha')), 'senha123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('@cs.unipe.edu.br'), findsWidgets);
    expect(sessao.usuario, isNull);
  });

  testWidgets('navegação nativa usa português brasileiro', (tester) async {
    await abrir(tester, AppAchei(sessao: sessao));
    await tester.tap(find.byTooltip('Perfil'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Voltar'), findsOneWidget);
  });

  testWidgets('outro usuário não vê edição nem exclusão', (tester) async {
    final item = Item.deMapa('alheio', {
      'autorId': 'bruno',
      'autorNome': 'Bruno',
      'titulo': 'Chave',
      'tipo': 'achado',
      'categoria': 'Chaves',
      'local': 'Biblioteca',
    });
    await abrir(
      tester,
      MaterialApp(
        theme: temaAchei(),
        home: TelaDetalhe(item: item, uidDoUsuario: 'ana', sessao: sessao),
      ),
    );
    expect(find.byTooltip('Editar item'), findsNothing);
    expect(find.byTooltip('Apagar item'), findsNothing);
  });

  testWidgets('formulário valida obrigatórios sem gravar', (tester) async {
    await sessao.prepararAcesso();
    await abrir(
      tester,
      MaterialApp(
        theme: temaAchei(),
        home: TelaPublicar(sessao: sessao),
      ),
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Publicar item'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Publicar item'));
    await tester.pumpAndSettle();
    expect((await firestore.collection('itens').get()).docs, isEmpty);
    expect(find.text('Informe o título.'), findsOneWidget);
    expect(find.text('Escolha a categoria.'), findsOneWidget);
    expect(find.text('Escolha o local.'), findsOneWidget);
  });

  testWidgets('publica, edita, cancela exclusão, apaga e sai pelo app', (
    tester,
  ) async {
    await abrir(tester, AppAchei(sessao: sessao));
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('titulo')), 'Garrafa azul');
    await tester.tap(find.byKey(const Key('categoria')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Garrafa/Copo').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('local')));
    await tester.tap(find.byKey(const Key('local')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biblioteca').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Publicar item'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Publicar item'));
    await tester.pumpAndSettle();
    expect(find.text('Garrafa azul'), findsOneWidget);
    await tester.tap(find.text('Garrafa azul'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('titulo')), 'Garrafa verde');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Salvar alterações'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pumpAndSettle();
    expect(find.text('Garrafa verde'), findsOneWidget);
    await tester.tap(find.text('Garrafa verde'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Apagar item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect((await firestore.collection('itens').get()).docs, hasLength(1));
    await tester.tap(find.byTooltip('Apagar item'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apagar'));
    await tester.pumpAndSettle();
    expect((await firestore.collection('itens').get()).docs, isEmpty);
    await tester.tap(find.byTooltip('Perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('nome')), 'Ana Nova');
    await tester.enterText(find.byKey(const Key('curso')), 'Computação');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar perfil'));
    await tester.pumpAndSettle();
    expect(
      (await firestore.collection('usuarios').doc('ana').get()).data()!['nome'],
      'Ana Nova',
    );
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
    expect(find.byTooltip('Perfil'), findsNothing);
  });
}
