// Tela inicial: lista dos itens abertos, mais recentes primeiro, atualizando
// em tempo real. Quando alguém publica, o item aparece aqui sozinho, sem
// recarregar. No topo ficam a busca e os filtros (ver docs/filtros.md).
//
// Por padrão lê do Firestore. Nos testes, ou enquanto o Firebase não está
// ligado, dá para passar os itens prontos:
//
//   TelaFeed(itens: Stream.value(itensDeExemplo()))

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../modelos/item.dart';
import '../sessao.dart';
import '../util/filtro.dart';
import '../widgets/aviso.dart';
import '../widgets/barra_de_filtros.dart';
import '../widgets/card_item.dart';
import 'detalhe.dart';

/// Quantos itens o feed carrega no máximo (definido na spec).
const int limiteDoFeed = 200;

/// Consulta do feed: itens abertos, mais recentes primeiro, até 200.
///
/// Atenção: filtrar por `status` e ordenar por `criadoEm` exige um índice
/// composto no Firestore. Ver docs/feed.md.
Stream<List<Item>> itensAbertosDoFirestore({FirebaseFirestore? firestore}) {
  return (firestore ?? FirebaseFirestore.instance)
      .collection('itens')
      .where('status', isEqualTo: 'aberto')
      .orderBy('criadoEm', descending: true)
      .limit(limiteDoFeed)
      .snapshots()
      .map(
        (consulta) => consulta.docs
            .map((documento) => Item.deMapa(documento.id, documento.data()))
            .toList(),
      );
}

class TelaFeed extends StatefulWidget {
  const TelaFeed({
    super.key,
    this.itens,
    this.uidDoUsuario,
    this.devolver,
    this.sessao,
  });

  final Sessao? sessao;

  /// De onde vêm os itens. Se ficar nulo, usa o Firestore.
  final Stream<List<Item>>? itens;

  /// Quem está usando o app, repassado ao detalhe. Se ficar nulo, o
  /// detalhe pergunta ao Firebase Auth. Serve para os testes.
  final String? uidDoUsuario;

  /// Repassado ao detalhe, para os testes não gravarem no Firestore.
  final Future<void> Function(String itemId)? devolver;

  @override
  State<TelaFeed> createState() => _TelaFeedState();
}

class _TelaFeedState extends State<TelaFeed> {
  // Criado uma vez só. Se fosse criado dentro do build, cada redesenho
  // abriria uma nova conexão com o Firestore.
  late final Stream<List<Item>> _itens =
      widget.itens ?? itensAbertosDoFirestore();

  // O que está filtrado e buscado agora. Fica aqui, e não na lista, para
  // continuar valendo quando o Firestore manda itens novos.
  final _filtro = Filtro();
  final _busca = TextEditingController();

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  void _abrirDetalhe(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaDetalhe(
          item: item,
          uidDoUsuario: widget.uidDoUsuario,
          devolver: widget.devolver,
          sessao: widget.sessao,
        ),
      ),
    );
  }

  void _limparFiltros() {
    setState(() {
      _filtro.limpar();
      _busca.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achei no Campus'),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // A rota '/publicar' é registrada no main.dart, apontando para a
        // tela de publicar do Daniel.
        onPressed: () => Navigator.pushNamed(context, '/publicar'),
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
      body: StreamBuilder<List<Item>>(
        stream: _itens,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Aviso(
              icone: Icons.cloud_off,
              texto:
                  'Não foi possível carregar os itens.\n'
                  'Confira sua conexão e tente de novo.',
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final itens = snapshot.data!;
          if (itens.isEmpty) {
            return const Aviso(
              icone: Icons.search,
              texto:
                  'Nenhum item ainda.\n'
                  'Perdeu ou achou algo? Toque em Publicar.',
            );
          }

          final visiveis = _filtro.aplicar(itens);

          return Column(
            children: [
              BarraDeFiltros(
                filtro: _filtro,
                busca: _busca,
                categorias: opcoesDe(itens, (item) => item.categoria),
                locais: opcoesDe(itens, (item) => item.local),
                aoMudar: () => setState(() {}),
                aoLimpar: _limparFiltros,
              ),
              Expanded(
                child: visiveis.isEmpty
                    ? Aviso(
                        icone: Icons.filter_alt_off,
                        texto: 'Nenhum item com esses filtros.',
                        acao: OutlinedButton(
                          onPressed: _limparFiltros,
                          child: const Text('Limpar filtros'),
                        ),
                      )
                    : ListView.builder(
                        // Espaço no fim para o último card não ficar atrás
                        // do botão de publicar.
                        padding: const EdgeInsets.only(top: 4, bottom: 96),
                        itemCount: visiveis.length,
                        itemBuilder: (context, i) => CardItem(
                          item: visiveis[i],
                          aoTocar: () => _abrirDetalhe(visiveis[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
