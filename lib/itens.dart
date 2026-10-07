import 'package:cloud_firestore/cloud_firestore.dart';

import 'config.dart';
import 'modelos/item.dart';
import 'sessao.dart';

class Itens {
  Itens({Sessao? sessao}) : sessao = sessao ?? Sessao();
  final Sessao sessao;

  Future<String> salvar({
    Item? item,
    required String tipo,
    required String titulo,
    required String descricao,
    required String categoria,
    required String local,
    required String fotoUrl,
  }) async {
    final uid = _uidVerificado();
    if (!['perdido', 'achado'].contains(tipo) ||
        titulo.trim().isEmpty ||
        titulo.trim().length > 120 ||
        descricao.trim().length > 2000 ||
        !categorias.contains(categoria) ||
        !locais.contains(local)) {
      throw ArgumentError('Informe título, tipo, categoria e local válidos.');
    }
    final uri = Uri.tryParse(fotoUrl);
    if (fotoUrl.length > 2048 ||
        (fotoUrl.isNotEmpty &&
            (uri == null || uri.scheme != 'https' || uri.host.isEmpty))) {
      throw ArgumentError('A foto precisa de uma URL HTTPS válida.');
    }
    final conteudo = {
      'tipo': tipo,
      'titulo': titulo.trim(),
      'descricao': descricao.trim(),
      'categoria': categoria,
      'local': local,
      'fotoUrl': fotoUrl,
    };
    final colecao = sessao.firestore.collection('itens');
    if (item != null) {
      await _conferirDono(item.id, uid);
      await colecao.doc(item.id).update(conteudo);
      return item.id;
    }
    final perfil = await sessao.firestore.collection('usuarios').doc(uid).get();
    final nome = perfil.data()?['nome'];
    if (nome is! String || nome.trim().isEmpty) {
      throw StateError('Preencha seu nome no perfil antes de publicar.');
    }
    final ref = await colecao.add({
      ...conteudo,
      'autorId': uid,
      'autorNome': nome,
      'status': 'aberto',
      'criadoEm': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> devolver(String id) async {
    await _conferirDono(id, _uidVerificado());
    await sessao.firestore.collection('itens').doc(id).update({
      'status': 'devolvido',
    });
  }

  Future<void> apagar(String id) async {
    await _conferirDono(id, _uidVerificado());
    await sessao.firestore.collection('itens').doc(id).delete();
  }

  String _uidVerificado() {
    final user = sessao.usuario;
    if (user == null ||
        !user.emailVerified ||
        !emailPermitido(user.email ?? '')) {
      throw StateError('Entre com um e-mail acadêmico verificado.');
    }
    return user.uid;
  }

  Future<void> _conferirDono(String id, String uid) async {
    final dados = await sessao.firestore.collection('itens').doc(id).get();
    if (!dados.exists || dados.data()?['autorId'] != uid) {
      throw StateError('Você só pode alterar seus próprios itens.');
    }
  }
}
