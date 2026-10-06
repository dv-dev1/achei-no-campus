// Marcar um item como devolvido: pergunta antes, grava no Firestore e avisa
// como foi.
//
// Usado no detalhe e em "Meus itens". Fica separado para os dois lugares
// fazerem exatamente a mesma coisa.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../modelos/item.dart';

/// Grava `status: "devolvido"` no item. As regras do Firestore só deixam o
/// dono do item fazer isso.
///
/// Não precisa avisar o feed: ele só lista itens com `status == "aberto"`,
/// então o item some sozinho da tela de todo mundo.
Future<void> marcarComoDevolvido(String itemId) {
  return FirebaseFirestore.instance.collection('itens').doc(itemId).update({
    'status': 'devolvido',
  });
}

/// Mostra a confirmação e, se a pessoa confirmar, marca o item.
///
/// Devolve `true` se o item foi marcado. Devolve `false` se a pessoa
/// desistiu ou se deu erro (nesse caso, já mostra o aviso de erro).
///
/// `devolver` só existe para os testes trocarem o Firestore por outra coisa.
Future<bool> confirmarEDevolver(
  BuildContext context,
  Item item, {
  Future<void> Function(String itemId)? devolver,
}) async {
  // Pega o mensageiro antes de qualquer espera: se a tela fechar no meio,
  // o aviso ainda consegue aparecer.
  final mensageiro = ScaffoldMessenger.of(context);

  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Marcar como devolvido?'),
      content: Text(
        '"${item.titulo}" vai sair do feed para todo mundo. '
        'Confirme só quando o objeto já estiver com o dono.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Marcar como devolvido'),
        ),
      ],
    ),
  );

  // Fechar a janela tocando fora dela também conta como desistir.
  if (confirmou != true) return false;

  try {
    await (devolver ?? marcarComoDevolvido)(item.id);
  } catch (_) {
    mensageiro.showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível marcar. Confira a conexão e tente de novo.',
        ),
      ),
    );
    return false;
  }

  mensageiro.showSnackBar(
    const SnackBar(content: Text('Item marcado como devolvido.')),
  );
  return true;
}
