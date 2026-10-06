// Itens de mentira para ver e testar o feed sem depender do Firebase.
//
// Para ver o feed com eles, troque temporariamente a home do app por:
//
//   TelaFeed(itens: Stream.value(itensDeExemplo()))
//
// Não use em produção: quando o Firebase estiver ligado, o feed lê os itens
// de verdade sozinho.

import '../modelos/item.dart';

List<Item> itensDeExemplo({DateTime? agora}) {
  final hoje = agora ?? DateTime.now();

  Item exemplo(
    String id,
    String tipo,
    String titulo,
    String categoria,
    String local,
    Duration idade,
  ) {
    return Item(
      id: id,
      tipo: tipo,
      titulo: titulo,
      descricao: 'Item de exemplo para testar o feed.',
      categoria: categoria,
      local: local,
      fotoUrl: '',
      autorId: 'aluno-exemplo',
      autorNome: 'Aluno de exemplo',
      status: 'aberto',
      criadoEm: hoje.subtract(idade),
    );
  }

  return [
    exemplo(
      '1',
      'achado',
      'Fone de ouvido branco',
      'Eletrônicos',
      'Biblioteca',
      const Duration(minutes: 12),
    ),
    exemplo(
      '2',
      'perdido',
      'Chave com chaveiro do Flamengo',
      'Chaves',
      'Praça de alimentação/cantinas',
      const Duration(hours: 3),
    ),
    exemplo(
      '3',
      'achado',
      'Garrafa térmica azul',
      'Garrafa/Copo',
      'Ginásio',
      const Duration(days: 1),
    ),
    exemplo(
      '4',
      'perdido',
      'Carteira marrom',
      'Carteira/Dinheiro',
      'Estacionamento',
      const Duration(days: 4),
    ),
    exemplo(
      '5',
      'achado',
      'Caderno de Anatomia',
      'Material escolar',
      'Bloco de Medicina',
      const Duration(days: 9),
    ),
  ];
}
