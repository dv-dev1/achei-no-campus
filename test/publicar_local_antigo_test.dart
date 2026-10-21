import 'package:achei_no_campus/config.dart';
import 'package:achei_no_campus/modelos/item.dart';
import 'package:achei_no_campus/sessao.dart';
import 'package:achei_no_campus/telas/publicar.dart';
import 'package:achei_no_campus/tema.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// CT-44 (issue #10): conferir a lista de locais no campus pode renomear ou
// remover um nome de `locais`. Item publicado antes da mudança continua no
// Firestore com o nome antigo, que a tela de editar precisa aguentar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  const localAntigo = 'Bloco de Fisioterapia';

  // `skip` é o `todo` do flutter_test: o caso reproduz a issue #15, já
  // registrada, então ele fica fora do vermelho do CI de propósito. Quando a
  // correção chegar, tirar o `skip` e rodar `flutter test`: é esse o reteste.
  testWidgets('editar item cujo local saiu da lista abre a tela', (
    tester,
  ) async {
    expect(
      locais,
      isNot(contains(localAntigo)),
      reason: 'o caso só existe enquanto $localAntigo não está em locais',
    );

    final item = Item.deMapa('i1', {
      'tipo': 'achado',
      'titulo': 'Garrafa azul',
      'descricao': 'Perto da quadra',
      'categoria': 'Garrafa/Copo',
      'local': localAntigo,
      'autorId': 'ana',
      'autorNome': 'Ana',
      'status': 'aberto',
      'criadoEm': DateTime.now(),
    });

    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: temaAchei(),
        home: TelaPublicar(
          sessao: Sessao(
            auth: MockFirebaseAuth(
              mockUser: MockUser(
                uid: 'ana',
                email: 'ana@cs.unipe.edu.br',
                isEmailVerified: true,
                displayName: 'Ana',
              ),
              signedIn: true,
            ),
            firestore: FakeFirebaseFirestore(),
          ),
          item: item,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('local')), findsOneWidget);
  }, skip: true); // defeito aberto: issue #15
}
