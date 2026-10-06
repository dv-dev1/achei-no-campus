// Filtros e busca do feed.
//
// Tudo roda no próprio app, sobre os itens que o feed já carregou (até 200):
// o Firestore não faz busca por texto, então não adianta pedir a ele.

import '../modelos/item.dart';

class Filtro {
  /// "perdido", "achado" ou nulo (todos).
  String? tipo;

  /// Categoria escolhida, ou nulo (todas).
  String? categoria;

  /// Local escolhido, ou nulo (todos).
  String? local;

  /// Texto digitado na busca.
  String busca = '';

  /// Se há algum filtro ou busca ligado (para mostrar o "Limpar").
  bool get ativo =>
      tipo != null ||
      categoria != null ||
      local != null ||
      busca.trim().isNotEmpty;

  void limpar() {
    tipo = null;
    categoria = null;
    local = null;
    busca = '';
  }

  /// Se o item passa em todos os filtros ao mesmo tempo.
  bool aceita(Item item) {
    if (tipo != null && item.tipo != tipo) return false;
    if (categoria != null && item.categoria != categoria) return false;
    if (local != null && item.local != local) return false;

    final termo = normalizar(busca.trim());
    if (termo.isEmpty) return true;
    return normalizar(item.titulo).contains(termo) ||
        normalizar(item.descricao).contains(termo);
  }

  List<Item> aplicar(List<Item> itens) => itens.where(aceita).toList();
}

/// As opções que existem nos itens, sem repetir, em ordem alfabética.
///
/// Usado para montar os chips de categoria e de local:
///   opcoesDe(itens, (item) => item.local)
List<String> opcoesDe(List<Item> itens, String Function(Item) campo) {
  final opcoes = itens.map(campo).where((valor) => valor.isNotEmpty).toSet();
  return opcoes.toList()
    ..sort((a, b) => normalizar(a).compareTo(normalizar(b)));
}

/// Deixa o texto em minúsculas e sem acentos, para "Fone", "fone" e "FÔNE"
/// serem encontrados do mesmo jeito.
String normalizar(String texto) {
  const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const semAcento = 'aaaaaeeeeiiiiooooouuuucn';

  final minusculo = texto.toLowerCase();
  final resultado = StringBuffer();
  for (final letra in minusculo.split('')) {
    final posicao = comAcento.indexOf(letra);
    resultado.write(posicao == -1 ? letra : semAcento[posicao]);
  }
  return resultado.toString();
}
