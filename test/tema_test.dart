import 'package:achei_no_campus/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Nos testes não há internet: a fonte cai para a padrão, e tudo bem,
  // porque aqui só conferimos o nome da família, não o desenho das letras.
  GoogleFonts.config.allowRuntimeFetching = false;

  late ThemeData tema;
  setUpAll(() => tema = temaAchei());

  test('usa as cores da identidade visual', () {
    expect(tema.colorScheme.primary, CoresAchei.azul);
    expect(tema.colorScheme.secondary, CoresAchei.amarelo);
    expect(tema.colorScheme.onSurface, CoresAchei.texto);
    expect(tema.scaffoldBackgroundColor, CoresAchei.fundo);
  });

  test('usa a fonte Work Sans', () {
    expect(tema.textTheme.bodyMedium?.fontFamily, startsWith('WorkSans'));
    expect(tema.textTheme.titleLarge?.fontFamily, startsWith('WorkSans'));
  });

  test('card tem raio 12', () {
    final formato = tema.cardTheme.shape as RoundedRectangleBorder;
    expect(formato.borderRadius, BorderRadius.circular(12));
  });

  test('botões e chips são pílulas', () {
    OutlinedBorder? formatoDe(ButtonStyle? estilo) =>
        estilo?.shape?.resolve({});

    expect(formatoDe(tema.filledButtonTheme.style), isA<StadiumBorder>());
    expect(formatoDe(tema.elevatedButtonTheme.style), isA<StadiumBorder>());
    expect(formatoDe(tema.outlinedButtonTheme.style), isA<StadiumBorder>());
    expect(formatoDe(tema.textButtonTheme.style), isA<StadiumBorder>());
    expect(tema.chipTheme.shape, isA<StadiumBorder>());
  });

  testWidgets('uma tela sem cor fixa herda o tema', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tema,
        home: Scaffold(
          appBar: AppBar(title: const Text('Achei no Campus')),
          body: FilledButton(onPressed: () {}, child: const Text('Publicar')),
        ),
      ),
    );

    final fundo = tester.widget<Material>(
      find.descendant(of: find.byType(Scaffold), matching: find.byType(Material)).first,
    );
    expect(fundo.color, CoresAchei.fundo);

    final barra = tester.widget<Material>(
      find.descendant(of: find.byType(AppBar), matching: find.byType(Material)).first,
    );
    expect(barra.color, CoresAchei.azul);
  });
}
