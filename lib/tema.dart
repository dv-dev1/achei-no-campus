// Tema visual do Achei no Campus.
//
// Tudo o que é cor, fonte e formato de componente mora aqui. As telas não
// devem escrever cor nem fonte na mão: elas herdam do tema que o MaterialApp
// recebe em `main.dart`:
//
//   MaterialApp(theme: temaAchei(), ...)
//
// Quando uma tela precisar de uma cor específica, ela pede ao tema:
//
//   final cores = Theme.of(context).colorScheme;
//   Text('Achado', style: TextStyle(color: cores.primary));
//
// O guia completo, com exemplos, está em docs/tema.md.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cores da identidade visual, tiradas do site da UNIPÊ (ver a spec).
///
/// Nas telas, prefira `Theme.of(context).colorScheme`. Use estas constantes só
/// quando não houver um `context` à mão, como no splash ou nos testes.
abstract final class CoresAchei {
  static const azul = Color(0xFF003B71);
  static const amarelo = Color(0xFFFED400);
  static const fundo = Color(0xFFF7F7F7);
  static const texto = Color(0xFF222222);
  static const branco = Color(0xFFFFFFFF);
}

/// Raio do card, definido na spec.
const double raioCard = 12;

/// Formato de pílula usado em todos os botões e chips.
const OutlinedBorder formatoPilula = StadiumBorder();

/// Monta o tema do app. Chame uma vez, no `MaterialApp`.
ThemeData temaAchei() {
  const cores = ColorScheme(
    brightness: Brightness.light,
    primary: CoresAchei.azul,
    onPrimary: CoresAchei.branco,
    secondary: CoresAchei.amarelo,
    onSecondary: CoresAchei.azul,
    error: Color(0xFFB3261E),
    onError: CoresAchei.branco,
    surface: CoresAchei.branco,
    onSurface: CoresAchei.texto,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: cores);

  // Work Sans em todos os textos, já na cor de texto da identidade.
  final textos = GoogleFonts.workSansTextTheme(base.textTheme).apply(
    bodyColor: CoresAchei.texto,
    displayColor: CoresAchei.texto,
  );

  // Padding comum aos botões, para todos terem a mesma altura.
  const paddingBotao = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
  final textoBotao = textos.labelLarge?.copyWith(fontWeight: FontWeight.w600);

  return base.copyWith(
    scaffoldBackgroundColor: CoresAchei.fundo,
    textTheme: textos,

    // Barra do topo azul, com título e ícones brancos.
    appBarTheme: AppBarTheme(
      backgroundColor: CoresAchei.azul,
      foregroundColor: CoresAchei.branco,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: textos.titleLarge?.copyWith(
        color: CoresAchei.branco,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Cards do feed, do detalhe e de "Meus itens".
    cardTheme: CardThemeData(
      color: CoresAchei.branco,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias, // a foto respeita o canto arredondado
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(raioCard),
      ),
    ),

    // Botão principal (ex.: "Publicar", "Entrar").
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CoresAchei.azul,
        foregroundColor: CoresAchei.branco,
        shape: formatoPilula,
        padding: paddingBotao,
        textStyle: textoBotao,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CoresAchei.azul,
        foregroundColor: CoresAchei.branco,
        shape: formatoPilula,
        padding: paddingBotao,
        textStyle: textoBotao,
      ),
    ),

    // Botão secundário (ex.: "Cancelar", "Limpar filtros").
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CoresAchei.azul,
        side: const BorderSide(color: CoresAchei.azul),
        shape: formatoPilula,
        padding: paddingBotao,
        textStyle: textoBotao,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CoresAchei.azul,
        shape: formatoPilula,
        textStyle: textoBotao,
      ),
    ),

    // Botão flutuante de publicar: amarelo de destaque com ícone azul.
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: CoresAchei.amarelo,
      foregroundColor: CoresAchei.azul,
      shape: formatoPilula,
    ),

    // Chips dos filtros (perdido/achado, categoria, local).
    // Selecionado fica amarelo, para destacar o que está filtrando.
    chipTheme: ChipThemeData(
      shape: formatoPilula,
      backgroundColor: CoresAchei.branco,
      selectedColor: CoresAchei.amarelo,
      checkmarkColor: CoresAchei.azul,
      side: const BorderSide(color: CoresAchei.azul),
      labelStyle: textos.labelLarge?.copyWith(color: CoresAchei.azul),
    ),

    // Campos de texto (busca, login, publicar, chat).
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CoresAchei.branco,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(raioCard),
        borderSide: BorderSide(color: CoresAchei.texto.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(raioCard),
        borderSide: BorderSide(color: CoresAchei.texto.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(raioCard),
        borderSide: const BorderSide(color: CoresAchei.azul, width: 2),
      ),
    ),

    // Barra de abas de baixo (Feed, Mensagens, Meus itens).
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CoresAchei.branco,
      indicatorColor: CoresAchei.amarelo,
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: CoresAchei.azul),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        textos.labelMedium?.copyWith(color: CoresAchei.azul),
      ),
    ),

    // Contador de não lidas na aba Mensagens.
    badgeTheme: const BadgeThemeData(
      backgroundColor: CoresAchei.amarelo,
      textColor: CoresAchei.azul,
    ),

    // Avisos rápidos (ex.: "Item marcado como devolvido").
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CoresAchei.azul,
      contentTextStyle: textos.bodyMedium?.copyWith(color: CoresAchei.branco),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(raioCard),
      ),
    ),

    // Janela de confirmação (ex.: "Marcar como devolvido?").
    dialogTheme: DialogThemeData(
      backgroundColor: CoresAchei.branco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(raioCard),
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: CoresAchei.azul,
    ),
  );
}
