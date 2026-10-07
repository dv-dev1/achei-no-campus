# Tema visual

Este guia explica como o visual do app funciona e como usar nas suas telas. Se você vai criar ou mexer em alguma tela, leia antes: são cinco minutos e evitam retrabalho.

## A ideia em uma frase

**Nenhuma tela escolhe cor nem fonte.** Tudo isso fica em `lib/tema.dart`, e as telas só herdam. Se amanhã o azul mudar, muda num lugar só e o app inteiro acompanha.

## As cores

Tiradas do site da UNIPÊ, como diz a spec:

| Nome no código | Cor | Onde aparece |
| --- | --- | --- |
| `CoresAchei.azul` | `#003B71` | Barra do topo, botões principais, links, ícones |
| `CoresAchei.amarelo` | `#FED400` | Destaques: botão de publicar, chip selecionado, contador de não lidas |
| `CoresAchei.fundo` | `#F7F7F7` | Fundo de todas as telas |
| `CoresAchei.texto` | `#222222` | Todo texto comum |

A fonte é a **Work Sans**, carregada pelo pacote `google_fonts`.

## Como ligar o tema (uma vez só)

No `main.dart`, o `MaterialApp` recebe o tema:

```dart
import 'tema.dart';

MaterialApp(
  title: 'Achei no Campus',
  theme: temaAchei(),
  home: ...,
);
```

O projeto precisa do pacote da fonte no `pubspec.yaml`:

```bash
flutter pub add "google_fonts:^8.2.1"
```

**Por que a versão 8 e não a 9?** A 9.0 (setembro de 2026) passou a usar o pacote `material_ui`, a nova casa do Material fora do Flutter. Só que o `flutter create` ainda gera o app com `import 'package:flutter/material.dart'`, e os dois `TextTheme` não se misturam: com a 9, o `tema.dart` nem compila. Quando o grupo decidir migrar o app inteiro para o `material_ui`, dá para subir para a 9 junto.

Pronto. Daí em diante, toda tela já nasce com as cores e a fonte certas.

## Como usar nas telas

### O jeito certo: usar os componentes normais

Use os widgets do Flutter sem passar cor, fonte nem formato. O tema já cuida disso:

| Você escreve | O tema entrega |
| --- | --- |
| `AppBar(title: Text('Feed'))` | Barra azul com título branco |
| `FilledButton(onPressed: ..., child: Text('Publicar'))` | Botão azul em pílula |
| `OutlinedButton(...)` | Botão com contorno azul em pílula, para ações secundárias como "Cancelar" |
| `FloatingActionButton(child: Icon(Icons.add))` | Botão redondo amarelo com ícone azul |
| `Card(child: ...)` | Card branco com canto arredondado (raio 12), e a foto respeita o canto |
| `FilterChip(label: Text('Achado'), selected: ..., onSelected: ...)` | Chip em pílula, amarelo quando selecionado |
| `TextField(decoration: InputDecoration(labelText: 'Buscar'))` | Campo branco com borda arredondada, azul quando em foco |
| `NavigationBar(...)` | Barra de abas branca, aba ativa marcada em amarelo |
| `Badge(label: Text('3'), child: Icon(Icons.chat))` | Contador amarelo com número azul |
| `SnackBar(content: Text('Item devolvido'))` | Aviso azul flutuante |
| `Divider()` | Linha cinza clara, que separa sem pesar |

### Quando precisar de uma cor específica

Às vezes uma tela precisa da cor de propósito, por exemplo para pintar a etiqueta "Perdido" ou "Achado". Peça ao tema, não escreva o código da cor:

```dart
final cores = Theme.of(context).colorScheme;
final textos = Theme.of(context).textTheme;

Text('Achado', style: textos.labelLarge?.copyWith(color: cores.primary));
Container(color: cores.secondary); // amarelo
```

Equivalências do `colorScheme`: `primary` é o azul, `secondary` é o amarelo, `onSurface` é a cor do texto.

As constantes `CoresAchei` existem para quando não há `context` à mão, como no splash ou nos testes.

### O que não fazer

```dart
// Não: cor e fonte escritas na tela
Text('Feed', style: TextStyle(color: Color(0xFF003B71), fontFamily: 'Arial'));
ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), ...);

// Sim: deixa o tema decidir
Text('Feed', style: Theme.of(context).textTheme.titleLarge);
ElevatedButton(...);
```

Uma busca rápida ajuda a revisar uma tela antes de subir. Se aparecer algo em `lib/telas/`, provavelmente dá para trocar pelo tema:

```bash
grep -rnE "Color\(0x|Colors\.|fontFamily" lib/telas/
```

## Testes

`test/tema_test.dart` confere as cores, a fonte, o raio do card, o formato de pílula e se uma tela sem cor fixa herda o tema. Rode com:

```bash
flutter test test/tema_test.dart
```

Os testes rodam sem internet. Por isso a fonte não é baixada de verdade, e tudo bem: o teste só confere se o nome pedido é Work Sans. Você vai ver no meio da saída um aviso `google_fonts was unable to load font WorkSans-Regular`. É esperado e não quebra nada; o que vale é a última linha, `All tests passed!`.

## Quer mudar algo no visual?

Mude em `lib/tema.dart`, rode os testes e avise o grupo, porque a mudança aparece em todas as telas de uma vez. Se for uma cor nova da identidade, atualize também a tabela deste guia e a seção "Identidade visual" da spec.
