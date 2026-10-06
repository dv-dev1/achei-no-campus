import 'package:achei_no_campus/modelos/item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lê um documento completo do Firestore', () {
    final data = DateTime(2026, 10, 6, 10, 30);
    final item = Item.deMapa('abc', {
      'tipo': 'achado',
      'titulo': 'Fone',
      'descricao': 'Fone branco',
      'categoria': 'Eletrônicos',
      'local': 'Biblioteca',
      'fotoUrl': 'https://exemplo.com/foto.jpg',
      'autorId': 'u1',
      'autorNome': 'Ana',
      'status': 'aberto',
      'criadoEm': Timestamp.fromDate(data),
    });

    expect(item.id, 'abc');
    expect(item.achado, isTrue);
    expect(item.perdido, isFalse);
    expect(item.devolvido, isFalse);
    expect(item.temFoto, isTrue);
    expect(item.criadoEm, data);
  });

  test('documento incompleto não quebra', () {
    final item = Item.deMapa('x', {'titulo': 'Chave'});

    expect(item.titulo, 'Chave');
    expect(item.categoria, '');
    expect(item.status, 'aberto');
    expect(item.temFoto, isFalse);
  });

  test('ida e volta: paraMapa e deMapa dão o mesmo item', () {
    final original = Item.deMapa('y', {
      'tipo': 'perdido',
      'titulo': 'Carteira',
      'status': 'devolvido',
      'criadoEm': Timestamp.fromDate(DateTime(2026, 9, 1)),
    });
    final copia = Item.deMapa('y', original.paraMapa());

    expect(copia.tipo, 'perdido');
    expect(copia.devolvido, isTrue);
    expect(copia.criadoEm, original.criadoEm);
  });
}
