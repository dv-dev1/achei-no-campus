// Tela "Meus itens": tudo o que o usuário publicou, abertos e devolvidos.
// Daqui ele marca um item como devolvido ou abre a edição.
//
// É a terceira aba da tela de início (lib/telas/inicio.dart).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../modelos/item.dart';
import '../sessao.dart';
import '../widgets/aviso.dart';
import '../widgets/card_item.dart';
import '../widgets/devolver.dart';
import 'detalhe.dart';
import 'publicar.dart';

/// Itens publicados por `uid`, em tempo real.
///
/// A consulta só filtra por autor e não ordena: assim o Firestore não pede
/// índice composto. A ordem é feita no app, por `ordenarMeusItens`, o que
/// sai barato porque cada pessoa publica poucos itens.
Stream<List<Item>> meusItensDoFirestore(
  String uid, {
  FirebaseFirestore? firestore,
}) {
  return (firestore ?? FirebaseFirestore.instance)
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
    this.sessao,
    this.uidDoUsuario,
    this.itens,
    this.devolver,
  });

  /// Quem está usando o app. Se ficar nulo, pergunta ao Firebase Auth.
  final String? uidDoUsuario;

  /// A sessão do app (Firebase e usuário). Se ficar nula, usa o padrão.
  final Sessao? sessao;

  /// De onde vêm os itens. Se ficar nulo, usa o Firestore.
  /// Este e o `devolver` só existem para os testes.
  final Stream<List<Item>>? itens;
  final Future<void> Function(String itemId)? devolver;

  @override
  State<TelaMeusItens> createState() => _TelaMeusItensState();
}

class _TelaMeusItensState extends State<TelaMeusItens> {
  late final String? _uid =
      widget.uidDoUsuario ??
      widget.sessao?.usuario?.uid ??
      FirebaseAuth.instance.currentUser?.uid;

  // Criado uma vez só, como no feed.
  late final Stream<List<Item>>? _itens =
      widget.itens ??
      (_uid == null
          ? null
          : meusItensDoFirestore(_uid, firestore: widget.sessao?.firestore));

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
            sessao: widget.sessao,
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
            onPressed: () => confirmarEDevolver(
              context,
              item,
              sessao: widget.sessao,
              devolver: widget.devolver,
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Marcar devolvido'),
          ),
      ],
    );
  }

  // A mesma tela de publicar, já preenchida (a do Daniel, igual ao Editar
  // do detalhe). Salvou, a lista se atualiza sozinha pelo Firestore.
  void _editar(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TelaPublicar(sessao: widget.sessao ?? Sessao(), item: item),
      ),
    );
  }
}
