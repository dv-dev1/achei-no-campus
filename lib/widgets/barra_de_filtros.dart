// Barra no topo do feed: campo de busca e, embaixo, os chips de filtro
// (todos/perdidos/achados, categoria e local), que podem ser combinados.
//
// A barra não guarda estado: ela altera o `filtro` que recebe e avisa o feed
// por `aoMudar`, e o feed redesenha a lista.

import 'package:flutter/material.dart';

import '../util/filtro.dart';

class BarraDeFiltros extends StatelessWidget {
  const BarraDeFiltros({
    super.key,
    required this.filtro,
    required this.busca,
    required this.categorias,
    required this.locais,
    required this.aoMudar,
    required this.aoLimpar,
  });

  final Filtro filtro;

  /// Controla o texto do campo de busca. Fica no feed para o "Limpar"
  /// conseguir apagar o que foi digitado.
  final TextEditingController busca;

  /// Opções dos chips de categoria e de local.
  final List<String> categorias;
  final List<String> locais;

  final VoidCallback aoMudar;
  final VoidCallback aoLimpar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: busca,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por título ou descrição',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: busca.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Apagar busca',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        busca.clear();
                        filtro.busca = '';
                        aoMudar();
                      },
                    ),
            ),
            onChanged: (texto) {
              filtro.busca = texto;
              aoMudar();
            },
          ),
          const SizedBox(height: 8),
          // Rola para o lado quando os chips não cabem na tela.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chipDeTipo(null, 'Todos'),
                _chipDeTipo('perdido', 'Perdidos'),
                _chipDeTipo('achado', 'Achados'),
                const SizedBox(width: 8),
                _ChipDeLista(
                  titulo: 'Categoria',
                  tituloDoTodos: 'Todas as categorias',
                  valor: filtro.categoria,
                  opcoes: categorias,
                  aoEscolher: (escolha) {
                    filtro.categoria = escolha;
                    aoMudar();
                  },
                ),
                const SizedBox(width: 8),
                _ChipDeLista(
                  titulo: 'Local',
                  tituloDoTodos: 'Todos os locais',
                  valor: filtro.local,
                  opcoes: locais,
                  aoEscolher: (escolha) {
                    filtro.local = escolha;
                    aoMudar();
                  },
                ),
                if (filtro.ativo) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: aoLimpar,
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Limpar'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Chip de escolha única: só um entre Todos, Perdidos e Achados.
  Widget _chipDeTipo(String? tipo, String rotulo) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(rotulo),
        selected: filtro.tipo == tipo,
        onSelected: (_) {
          filtro.tipo = tipo;
          aoMudar();
        },
      ),
    );
  }
}

/// Chip que abre uma lista de opções embaixo da tela (categoria ou local).
/// Com uma opção escolhida, o chip fica marcado e mostra o nome dela.
class _ChipDeLista extends StatelessWidget {
  const _ChipDeLista({
    required this.titulo,
    required this.tituloDoTodos,
    required this.valor,
    required this.opcoes,
    required this.aoEscolher,
  });

  final String titulo;
  final String tituloDoTodos;
  final String? valor;
  final List<String> opcoes;

  /// Recebe a opção escolhida, ou nulo para "todas".
  final ValueChanged<String?> aoEscolher;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(valor ?? titulo),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
      selected: valor != null,
      showCheckmark: false,
      onSelected: (_) => _abrirLista(context),
    );
  }

  Future<void> _abrirLista(BuildContext context) async {
    // Texto vazio quer dizer "todas"; nulo quer dizer que a pessoa fechou
    // a lista sem escolher nada, e aí nada muda.
    final escolha = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(tituloDoTodos),
              trailing: valor == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final opcao in opcoes)
              ListTile(
                title: Text(opcao),
                trailing: opcao == valor ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, opcao),
              ),
          ],
        ),
      ),
    );

    if (escolha == null) return;
    aoEscolher(escolha.isEmpty ? null : escolha);
  }
}
