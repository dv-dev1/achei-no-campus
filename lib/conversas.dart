// Tudo o que o chat lê e grava no Firestore fica aqui, no mesmo estilo de
// `itens.dart`: as telas só chamam estes métodos.
//
// A ordem das gravações segue as regras do Firestore (firestore.rules).
// O guia docs/chat.md explica cada passo.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'modelos/conversa.dart';
import 'modelos/item.dart';
import 'sessao.dart';

/// Tamanho máximo de uma mensagem, o mesmo limite das regras.
const int limiteDaMensagem = 5000;

class Conversas {
  Conversas({Sessao? sessao}) : sessao = sessao ?? Sessao();
  final Sessao sessao;

  FirebaseFirestore get _banco => sessao.firestore;
  CollectionReference<Map<String, dynamic>> get _conversas =>
      _banco.collection('conversas');

  String get _uid {
    final usuario = sessao.usuario;
    if (usuario == null) throw StateError('Entre na sua conta para conversar.');
    return usuario.uid;
  }

  /// As conversas do usuário, em tempo real, as mais recentes primeiro.
  ///
  /// A consulta só filtra por participante e não ordena: assim o Firestore
  /// não pede índice composto. A ordem é feita aqui, no app.
  Stream<List<Conversa>> minhas() {
    return _conversas
        .where('participantes', arrayContains: _uid)
        .snapshots()
        .map((consulta) {
          final lista = consulta.docs
              .map((doc) => Conversa.deMapa(doc.id, doc.data()))
              .toList();
          lista.sort((a, b) => b.atualizadoEm.compareTo(a.atualizadoEm));
          return lista;
        });
  }

  /// Soma das não lidas de todas as conversas: o número da aba Mensagens.
  Stream<int> totalNaoLidas() {
    final uid = _uid;
    return minhas().map(
      (lista) => lista.fold(0, (soma, c) => soma + c.naoLidasDe(uid)),
    );
  }

  /// As mensagens de uma conversa, em tempo real, da mais antiga à mais nova.
  ///
  /// Só pode ser chamado depois que a conversa existe: as regras conferem
  /// os participantes da conversa antes de deixar ler as mensagens.
  Stream<List<Mensagem>> mensagens(String conversaId) {
    return _conversas
        .doc(conversaId)
        .collection('mensagens')
        .orderBy('criadoEm')
        .snapshots()
        .map(
          (consulta) => consulta.docs
              .map((doc) => Mensagem.deMapa(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Envia `texto` na conversa.
  ///
  /// `jaExiste` diz se a conversa já está gravada. Na primeira mensagem são
  /// dois passos, nesta ordem: criar a conversa e depois a mensagem, porque
  /// a regra da mensagem confere a conversa que já existe. Nas seguintes, as
  /// duas gravações vão juntas num lote (batch).
  Future<void> enviar(
    Conversa conversa,
    String texto, {
    required bool jaExiste,
  }) async {
    final uid = _uid;
    final limpo = texto.trim();
    if (limpo.isEmpty) throw ArgumentError('Escreva uma mensagem.');
    if (limpo.length > limiteDaMensagem) {
      throw ArgumentError(
        'A mensagem pode ter até $limiteDaMensagem caracteres.',
      );
    }

    final outro = conversa.outro(uid);
    final refConversa = _conversas.doc(conversa.id);
    final mensagem = {
      'autorId': uid,
      'texto': limpo,
      'criadoEm': FieldValue.serverTimestamp(),
    };

    if (!jaExiste) {
      await refConversa.set({
        'itemId': conversa.itemId,
        'participantes': conversa.participantes,
        'ultimaMensagem': limpo,
        'atualizadoEm': FieldValue.serverTimestamp(),
        // Quem envia já leu; o outro tem 1 para ler.
        'naoLidas': {uid: 0, outro: 1},
      });
      await refConversa.collection('mensagens').add(mensagem);
      return;
    }

    final lote = _banco.batch();
    lote.update(refConversa, {
      'ultimaMensagem': limpo,
      'atualizadoEm': FieldValue.serverTimestamp(),
      // Soma 1 no contador do outro, sem precisar ler o valor antes.
      'naoLidas.$outro': FieldValue.increment(1),
    });
    lote.set(refConversa.collection('mensagens').doc(), mensagem);
    await lote.commit();
  }

  /// Zera as não lidas do usuário nesta conversa. Chamado quando ele abre
  /// a conversa e sempre que chega mensagem com ela aberta.
  Future<void> marcarComoLida(Conversa conversa) async {
    final uid = _uid;
    if (conversa.naoLidasDe(uid) == 0) return; // nada a fazer
    await _conversas.doc(conversa.id).update({'naoLidas.$uid': 0});
  }

  // Guardados para não buscar de novo a cada redesenho da lista.
  final _itens = <String, Future<Item?>>{};
  final _nomes = <String, Future<String>>{};

  /// O item da conversa, para mostrar o título. Nulo se foi apagado.
  Future<Item?> item(String itemId) {
    return _itens.putIfAbsent(itemId, () async {
      final doc = await _banco.collection('itens').doc(itemId).get();
      final dados = doc.data();
      return dados == null ? null : Item.deMapa(doc.id, dados);
    });
  }

  /// O nome de alguém, do perfil em `usuarios/{uid}`.
  Future<String> nomeDe(String uid) {
    return _nomes.putIfAbsent(uid, () async {
      final doc = await _banco.collection('usuarios').doc(uid).get();
      final nome = doc.data()?['nome'];
      return nome is String && nome.trim().isNotEmpty ? nome : 'Alguém';
    });
  }
}
