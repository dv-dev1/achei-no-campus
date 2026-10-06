// Tela de detalhe: tudo sobre um item, com a foto grande e o botão
// Conversar, para falar com quem publicou.
//
// Abre ao tocar num card do feed.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../modelos/item.dart';
import '../util/tempo.dart';
import '../widgets/card_item.dart';

class TelaDetalhe extends StatelessWidget {
  const TelaDetalhe({super.key, required this.item, this.uidDoUsuario});

  final Item item;

  /// Quem está usando o app. Se ficar nulo, pergunta ao Firebase Auth.
  /// Os testes passam um valor aqui para não depender do Firebase.
  final String? uidDoUsuario;

  @override
  Widget build(BuildContext context) {
    final uid = uidDoUsuario ?? FirebaseAuth.instance.currentUser?.uid;
    // Ninguém conversa consigo mesmo: o autor não vê o botão.
    final souOAutor = uid == item.autorId;

    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.perdido ? 'Item perdido' : 'Item achado'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _FotoGrande(item: item),
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
      bottomNavigationBar: souOAutor
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: () => _conversar(context),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Conversar'),
                ),
              ),
            ),
    );
  }

  void _conversar(BuildContext context) {
    // TODO(task 8): abrir a tela da conversa sobre este item.
    // Até o chat ficar pronto, o botão só avisa, para não quebrar o app.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('O chat ainda está sendo feito.')),
    );
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
