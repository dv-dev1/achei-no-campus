// Tela "Meus itens": tudo o que o usuário publicou, abertos e devolvidos.
// Daqui ele marca um item como devolvido ou abre a edição.
//
// Abre pelo ícone na barra do topo do feed.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../modelos/item.dart';
import '../widgets/aviso.dart';
import '../widgets/card_item.dart';
import '../widgets/devolver.dart';
import 'detalhe.dart';

/// Itens publicados por `uid`, em tempo real.
///
/// A consulta só filtra por autor e não ordena: assim o Firestore não pede
/// índice composto. A ordem é feita no app, por `ordenarMeusItens`, o que
/// sai barato porque cada pessoa publica poucos itens.
Stream<List<Item>> meusItensDoFirestore(String uid) {
  return FirebaseFirestore.instance
      .collection('itens')
      .where('autorId', isEqualTo: uid)
      .snapshots()
      .map(
        (consulta) => consulta.docs
            .map((documento) => Item.deMapa(documento.id, documento.data()))
            .toList(),
      );
}

/// Abertos primeiro (é com eles que ainda há o que fazer), depois os
/// devolvidos. Dentro de cada grupo, os mais recentes primeiro.
List<Item> ordenarMeusItens(List<Item> itens) {
  return List.of(itens)..sort((a, b) {
    if (a.devolvido != b.devolvido) return a.devolvido ? 1 : -1;
    return b.criadoEm.compareTo(a.criadoEm);
  });
}

class TelaMeusItens extends StatefulWidget {
  const TelaMeusItens({
    super.key,
    this.uidDoUsuario,
    this.itens,
    this.devolver,
  });

  /// Quem está usando o app. Se ficar nulo, pergunta ao Firebase Auth.
  final String? uidDoUsuario;

  /// De onde vêm os itens. Se ficar nulo, usa o Firestore.
  /// Este e o `devolver` só existem para os testes.
  final Stream<List<Item>>? itens;
  final Future<void> Function(String itemId)? devolver;

  @override
  State<TelaMeusItens> createState() => _TelaMeusItensState();
}

class _TelaMeusItensState extends State<TelaMeusItens> {
  late final String? _uid =
      widget.uidDoUsuario ?? FirebaseAuth.instance.currentUser?.uid;

  // Criado uma vez só, como no feed.
  late final Stream<List<Item>>? _itens =
      widget.itens ?? (_uid == null ? null : meusItensDoFirestore(_uid));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus itens')),
      body: _itens == null
          // Não deve acontecer: o portão do login só deixa chegar aqui logado.
          ? const Aviso(
              icone: Icons.lock_outline,
              texto: 'Entre na sua conta para ver seus itens.',
            )
          : StreamBuilder<List<Item>>(
              stream: _itens,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Aviso(
                    icone: Icons.cloud_off,
                    texto:
                        'Não foi possível carregar seus itens.\n'
                        'Confira sua conexão e tente de novo.',
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // A consulta já traz só os itens do usuário. O filtro aqui
                // é uma segunda garantia, para nunca mostrar item de outro.
                final meus = ordenarMeusItens(
                  snapshot.data!.where((item) => item.autorId == _uid).toList(),
                );

                if (meus.isEmpty) {
                  return const Aviso(
                    icone: Icons.inventory_2_outlined,
                    texto:
                        'Você ainda não publicou nenhum item.\n'
                        'O que você publicar aparece aqui.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: meus.length,
                  itemBuilder: (context, i) => _cardDe(meus[i]),
                );
              },
            ),
    );
  }

  Widget _cardDe(Item item) {
    return CardItem(
      item: item,
      mostrarStatus: true,
      aoTocar: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TelaDetalhe(
            item: item,
            uidDoUsuario: _uid,
            devolver: widget.devolver,
          ),
        ),
      ),
      botoes: [
        TextButton.icon(
          onPressed: () => _editar(item),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar'),
        ),
        // Item devolvido não volta a ser devolvido.
        if (!item.devolvido)
          TextButton.icon(
            onPressed: () =>
                confirmarEDevolver(context, item, devolver: widget.devolver),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Marcar devolvido'),
          ),
      ],
    );
  }

  void _editar(Item item) {
    // TODO(Daniel): abrir a tela de edição do item.
    // Até ela existir, o botão só avisa, para não quebrar o app.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A edição ainda está sendo feita.')),
    );
  }
}
