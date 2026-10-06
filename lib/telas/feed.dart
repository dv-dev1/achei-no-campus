// Tela inicial: lista dos itens abertos, mais recentes primeiro, atualizando
// em tempo real. Quando alguém publica, o item aparece aqui sozinho, sem
// recarregar.
//
// Por padrão lê do Firestore. Nos testes, ou enquanto o Firebase não está
// ligado, dá para passar os itens prontos:
//
//   TelaFeed(itens: Stream.value(itensDeExemplo()))

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../modelos/item.dart';
import '../widgets/card_item.dart';

/// Quantos itens o feed carrega no máximo (definido na spec).
const int limiteDoFeed = 200;

/// Consulta do feed: itens abertos, mais recentes primeiro, até 200.
///
/// Atenção: filtrar por `status` e ordenar por `criadoEm` exige um índice
/// composto no Firestore. Ver docs/feed.md.
Stream<List<Item>> itensAbertosDoFirestore() {
  return FirebaseFirestore.instance
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
  const TelaFeed({super.key, this.itens});

  /// De onde vêm os itens. Se ficar nulo, usa o Firestore.
  final Stream<List<Item>>? itens;

  @override
  State<TelaFeed> createState() => _TelaFeedState();
}

class _TelaFeedState extends State<TelaFeed> {
  // Criado uma vez só. Se fosse criado dentro do build, cada redesenho
  // abriria uma nova conexão com o Firestore.
  late final Stream<List<Item>> _itens =
      widget.itens ?? itensAbertosDoFirestore();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achei no Campus')),
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
            return const _Aviso(
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
            return const _Aviso(
              icone: Icons.search,
              texto:
                  'Nenhum item ainda.\n'
                  'Perdeu ou achou algo? Toque em Publicar.',
            );
          }

          return ListView.builder(
            // Espaço no fim para o último card não ficar atrás do botão.
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: itens.length,
            itemBuilder: (context, i) => CardItem(item: itens[i]),
          );
        },
      ),
    );
  }
}

/// Mensagem centralizada com ícone, para os estados de vazio e de erro.
class _Aviso extends StatelessWidget {
  const _Aviso({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: cores.primary),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
