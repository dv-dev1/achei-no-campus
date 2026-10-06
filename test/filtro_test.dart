import 'package:achei_no_campus/modelos/item.dart';
import 'package:achei_no_campus/util/filtro.dart';
import 'package:flutter_test/flutter_test.dart';

Item item(
  String id,
  String tipo,
  String titulo,
  String categoria,
  String local, {
  String descricao = '',
}) {
  return Item.deMapa(id, {
    'tipo': tipo,
    'titulo': titulo,
    'descricao': descricao,
    'categoria': categoria,
    'local': local,
  });
}

void main() {
  final itens = [
    item('1', 'achado', 'Fone de ouvido', 'Eletrônicos', 'Biblioteca'),
    item('2', 'perdido', 'Fone JBL', 'Eletrônicos', 'Biblioteca'),
    item('3', 'achado', 'Fone azul', 'Eletrônicos', 'Ginásio'),
    item(
      '4',
      'achado',
      'Carregador',
      'Eletrônicos',
      'Biblioteca',
      descricao: 'Veio junto com um FÔNE',
    ),
    item('5', 'achado', 'Fone rosa', 'Roupa/Acessório', 'Biblioteca'),
    item('6', 'achado', 'Garrafa', 'Garrafa/Copo', 'Biblioteca'),
  ];

  List<String> ids(List<Item> lista) => lista.map((i) => i.id).toList();

  test('critério de pronto: achado + Eletrônicos + Biblioteca + "fone"', () {
    final filtro = Filtro()
      ..tipo = 'achado'
      ..categoria = 'Eletrônicos'
      ..local = 'Biblioteca'
      ..busca = 'fone';

    // 1: casa em tudo. 4: casa pela descrição ("FÔNE", com acento).
    // 2 é perdido, 3 é do Ginásio, 5 é outra categoria, 6 não tem "fone".
    expect(ids(filtro.aplicar(itens)), ['1', '4']);
  });

  test('sem filtro mostra tudo', () {
    final filtro = Filtro();

    expect(filtro.ativo, isFalse);
    expect(filtro.aplicar(itens), hasLength(itens.length));
  });

  test('busca ignora maiúsculas, acentos e espaços nas pontas', () {
    expect(ids((Filtro()..busca = '  FONE ').aplicar(itens)), [
      '1',
      '2',
      '3',
      '4',
      '5',
    ]);
    expect(ids((Filtro()..busca = 'carregador').aplicar(itens)), ['4']);
  });

  test('cada filtro sozinho', () {
    expect(ids((Filtro()..tipo = 'perdido').aplicar(itens)), ['2']);
    expect(ids((Filtro()..local = 'Ginásio').aplicar(itens)), ['3']);
    expect(ids((Filtro()..categoria = 'Garrafa/Copo').aplicar(itens)), ['6']);
  });

  test('limpar desliga tudo', () {
    final filtro = Filtro()
      ..tipo = 'achado'
      ..local = 'Biblioteca'
      ..busca = 'fone';
    expect(filtro.ativo, isTrue);

    filtro.limpar();

    expect(filtro.ativo, isFalse);
    expect(filtro.aplicar(itens), hasLength(itens.length));
  });

  test('opções dos chips: sem repetir e em ordem alfabética', () {
    expect(opcoesDe(itens, (i) => i.local), ['Biblioteca', 'Ginásio']);
    expect(opcoesDe(itens, (i) => i.categoria), [
      'Eletrônicos',
      'Garrafa/Copo',
      'Roupa/Acessório',
    ]);
  });

  test('normalizar tira acento e deixa minúsculo', () {
    expect(normalizar('Ginásio Público ÇÃO'), 'ginasio publico cao');
  });
}
