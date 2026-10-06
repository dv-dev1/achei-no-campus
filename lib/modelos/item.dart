// Modelo de um item perdido ou achado.
//
// Os campos seguem a spec (seção "Modelo de dados"), um para um com o
// documento `itens/{id}` do Firestore. Quem lê o Firestore converte o
// documento com `Item.deMapa`; quem grava usa `paraMapa`.

import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  const Item({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.local,
    required this.fotoUrl,
    required this.autorId,
    required this.autorNome,
    required this.status,
    required this.criadoEm,
  });

  final String id;

  /// "perdido" ou "achado".
  final String tipo;
  final String titulo;
  final String descricao;
  final String categoria;
  final String local;

  /// Link da foto no Cloudinary. Vazio quando o item foi publicado sem foto.
  final String fotoUrl;
  final String autorId;
  final String autorNome;

  /// "aberto" ou "devolvido".
  final String status;
  final DateTime criadoEm;

  bool get perdido => tipo == 'perdido';
  bool get achado => tipo == 'achado';
  bool get devolvido => status == 'devolvido';
  bool get temFoto => fotoUrl.isNotEmpty;

  /// Monta o item a partir de um documento do Firestore.
  ///
  /// Campo que faltar vira texto vazio, para um documento incompleto não
  /// derrubar o feed inteiro.
  factory Item.deMapa(String id, Map<String, dynamic> dados) {
    return Item(
      id: id,
      tipo: dados['tipo'] as String? ?? '',
      titulo: dados['titulo'] as String? ?? '',
      descricao: dados['descricao'] as String? ?? '',
      categoria: dados['categoria'] as String? ?? '',
      local: dados['local'] as String? ?? '',
      fotoUrl: dados['fotoUrl'] as String? ?? '',
      autorId: dados['autorId'] as String? ?? '',
      autorNome: dados['autorNome'] as String? ?? '',
      status: dados['status'] as String? ?? 'aberto',
      criadoEm: _paraData(dados['criadoEm']),
    );
  }

  Map<String, dynamic> paraMapa() => {
    'tipo': tipo,
    'titulo': titulo,
    'descricao': descricao,
    'categoria': categoria,
    'local': local,
    'fotoUrl': fotoUrl,
    'autorId': autorId,
    'autorNome': autorNome,
    'status': status,
    'criadoEm': Timestamp.fromDate(criadoEm),
  };

  // O Firestore devolve data como Timestamp. Logo depois de publicar, com
  // FieldValue.serverTimestamp(), o campo chega nulo por um instante: nesse
  // caso usamos "agora", e o item aparece no topo do feed como deve.
  static DateTime _paraData(Object? valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return DateTime.now();
  }
}
