// Tela de detalhe: tudo sobre um item, com a foto grande e um botão no
// rodapé, que muda conforme quem está vendo:
//
//   - outra pessoa: Conversar, para falar com quem publicou;
//   - o dono: Marcar como devolvido (e, no topo, Editar e Apagar);
//   - item já devolvido: nenhum botão, só o aviso.
//
// Abre ao tocar num card do feed ou de "Meus itens".

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../modelos/conversa.dart';
import '../modelos/item.dart';
import '../itens.dart';
import '../sessao.dart';
import 'conversa.dart';
import 'publicar.dart';
import '../util/tempo.dart';
import '../widgets/card_item.dart';
import '../widgets/devolver.dart';

class TelaDetalhe extends StatelessWidget {
  const TelaDetalhe({
    super.key,
    required this.item,
    this.uidDoUsuario,
    this.devolver,
    this.sessao,
  });

  final Item item;
  final Sessao? sessao;

  /// Quem está usando o app. Se ficar nulo, pergunta ao Firebase Auth.
  /// Os testes passam um valor aqui para não depender do Firebase.
  final String? uidDoUsuario;

  /// Como marcar o item como devolvido. Se ficar nulo, grava no Firestore.
  /// Só os testes passam outra coisa aqui.
  final Future<void> Function(String itemId)? devolver;

  @override
  Widget build(BuildContext context) {
    final uid =
        uidDoUsuario ??
        sessao?.usuario?.uid ??
        FirebaseAuth.instance.currentUser?.uid;
    final souOAutor = uid == item.autorId;

    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.perdido ? 'Item perdido' : 'Item achado'),
        actions: souOAutor
            ? [
                IconButton(
                  tooltip: 'Editar item',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editar(context),
                ),
                IconButton(
                  tooltip: 'Apagar item',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _apagar(context),
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _FotoGrande(item: item),
          if (item.devolvido) const _AvisoDevolvido(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EtiquetaTipo(tipo: item.tipo),
                const SizedBox(height: 8),
                Text(
                  item.titulo,
                  style: textos.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.descricao.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(item.descricao, style: textos.bodyLarge),
                ],
                const SizedBox(height: 16),
                const Divider(),
                _Informacao(
                  icone: Icons.sell_outlined,
                  rotulo: 'Categoria',
                  valor: item.categoria,
                ),
                _Informacao(
                  icone: Icons.place_outlined,
                  rotulo: item.perdido ? 'Perdido em' : 'Achado em',
                  valor: item.local,
                ),
                _Informacao(
                  icone: Icons.schedule,
                  rotulo: 'Publicado',
                  valor: dataEHora(item.criadoEm),
                ),
                _Informacao(
                  icone: Icons.person_outline,
                  rotulo: 'Publicado por',
                  valor: souOAutor
                      ? '${item.autorNome} (você)'
                      : item.autorNome,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _botaoDoRodape(context, souOAutor, uid),
    );
  }

  Widget? _botaoDoRodape(BuildContext context, bool souOAutor, String? uid) {
    // Item devolvido já foi resolvido: não há mais o que fazer com ele.
    if (item.devolvido) return null;

    final botao = souOAutor
        // Ninguém conversa consigo mesmo: o dono vê o botão de devolvido.
        ? FilledButton.icon(
            onPressed: () => _marcarComoDevolvido(context),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Marcar como devolvido'),
          )
        : FilledButton.icon(
            onPressed: uid == null ? null : () => _conversar(context, uid),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Conversar'),
          );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: botao,
      ),
    );
  }

  Future<void> _marcarComoDevolvido(BuildContext context) async {
    final marcou = await confirmarEDevolver(
      context,
      item,
      sessao: sessao,
      devolver: devolver,
    );
    // Deu certo: volta ao feed, onde o item já sumiu.
    if (marcou && context.mounted) Navigator.pop(context);
  }

  void _conversar(BuildContext context, String uid) {
    // A conversa pode ainda não existir: ela nasce na primeira mensagem.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaConversa(
          conversa: Conversa.nova(item, uid),
          tituloDoItem: item.titulo,
          sessao: sessao,
        ),
      ),
    );
  }

  Future<void> _editar(BuildContext context) async {
    final mudou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TelaPublicar(sessao: sessao ?? Sessao(), item: item),
      ),
    );
    if (mudou == true && context.mounted) Navigator.pop(context);
  }

  Future<void> _apagar(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar item?'),
        content: Text(
          '"${item.titulo}" será removido. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    try {
      await Itens(sessao: sessao).apagar(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Item apagado.')));
        Navigator.pop(context);
      }
    } catch (erro) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensagemDeErro(erro))));
      }
    }
  }
}

/// "06/10/2026 às 14:30 (há 2 h)".
String dataEHora(DateTime data, {DateTime? agora}) {
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  final dia =
      '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year}';
  final hora = '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
  return '$dia às $hora (${tempoDesde(data, agora: agora)})';
}

/// Faixa logo abaixo da foto avisando que o item já foi devolvido.
class _AvisoDevolvido extends StatelessWidget {
  const _AvisoDevolvido();

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: cores.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: cores.onSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Este item já foi devolvido.',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cores.onSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Foto ocupando a largura da tela. Sem foto, ou se o link falhar, mostra
/// um ícone grande no lugar.
class _FotoGrande extends StatelessWidget {
  const _FotoGrande({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    final semFoto = Container(
      color: cores.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(Icons.image_outlined, size: 72, color: cores.primary),
      ),
    );

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: item.temFoto
          ? Image.network(
              item.fotoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => semFoto,
            )
          : semFoto,
    );
  }
}

/// Uma linha de informação: ícone, rótulo pequeno e o valor embaixo.
class _Informacao extends StatelessWidget {
  const _Informacao({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icone, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo, style: textos.labelMedium),
                Text(valor.isEmpty ? '—' : valor, style: textos.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
