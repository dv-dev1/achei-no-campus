// Modelos do chat: a conversa sobre um item e cada mensagem dela.
//
// Os campos são exatamente os da spec, e as regras do Firestore não aceitam
// nenhum campo a mais:
//
//   conversas/{itemId}_{interessadoUid}
//     itemId, participantes: [donoUid, interessadoUid]
//     ultimaMensagem, atualizadoEm, naoLidas: { <uid>: n }
//
//   conversas/{id}/mensagens/{id}
//     autorId, texto, criadoEm

import 'package:cloud_firestore/cloud_firestore.dart';

import 'item.dart';

class Conversa {
  const Conversa({
    required this.id,
    required this.itemId,
    required this.participantes,
    required this.ultimaMensagem,
    required this.atualizadoEm,
    required this.naoLidas,
  });

  final String id;
  final String itemId;

  /// Sempre dois: primeiro o dono do item, depois quem se interessou.
  final List<String> participantes;
  final String ultimaMensagem;
  final DateTime atualizadoEm;

  /// Quantas mensagens cada participante ainda não leu.
  final Map<String, int> naoLidas;

  String get dono => participantes[0];
  String get interessado => participantes[1];

  /// O outro participante, visto por `uid`.
  String outro(String uid) => uid == dono ? interessado : dono;

  int naoLidasDe(String uid) => naoLidas[uid] ?? 0;

  /// O ID é fixo: item + interessado. Assim, se a mesma pessoa tocar em
  /// Conversar duas vezes no mesmo item, cai sempre na mesma conversa.
  static String idPara(String itemId, String interessadoUid) =>
      '${itemId}_$interessadoUid';

  /// Conversa que ainda não existe no Firestore: nasce quando `interessado`
  /// toca em Conversar no detalhe do item. Só é gravada na primeira mensagem.
  factory Conversa.nova(Item item, String interessadoUid) {
    return Conversa(
      id: idPara(item.id, interessadoUid),
      itemId: item.id,
      participantes: [item.autorId, interessadoUid],
      ultimaMensagem: '',
      atualizadoEm: DateTime.now(),
      naoLidas: {item.autorId: 0, interessadoUid: 0},
    );
  }

  factory Conversa.deMapa(String id, Map<String, dynamic> dados) {
    final contagem = dados['naoLidas'];
    return Conversa(
      id: id,
      itemId: dados['itemId'] as String? ?? '',
      participantes: List<String>.from(dados['participantes'] as List? ?? []),
      ultimaMensagem: dados['ultimaMensagem'] as String? ?? '',
      atualizadoEm: _paraData(dados['atualizadoEm']),
      naoLidas: contagem is Map
          ? contagem.map((uid, n) => MapEntry('$uid', (n as num).toInt()))
          : {},
    );
  }
}

class Mensagem {
  const Mensagem({
    required this.id,
    required this.autorId,
    required this.texto,
    required this.criadoEm,
  });

  final String id;
  final String autorId;
  final String texto;
  final DateTime criadoEm;

  factory Mensagem.deMapa(String id, Map<String, dynamic> dados) {
    return Mensagem(
      id: id,
      autorId: dados['autorId'] as String? ?? '',
      texto: dados['texto'] as String? ?? '',
      criadoEm: _paraData(dados['criadoEm']),
    );
  }
}

// Logo depois de enviar, a data do servidor ainda não chegou e o campo vem
// nulo por um instante: nesse caso vale "agora".
DateTime _paraData(Object? valor) {
  if (valor is Timestamp) return valor.toDate();
  if (valor is DateTime) return valor;
  return DateTime.now();
}
