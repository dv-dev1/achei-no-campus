import 'dart:convert';
import 'dart:typed_data';

import 'package:achei_no_campus/cloudinary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  XFile foto([int tamanho = 4]) => XFile.fromData(
    Uint8List(tamanho),
    name: 'foto.png',
    path: 'foto.png',
    mimeType: 'image/png',
  );

  test('sem configuração impede upload com erro compreensível', () async {
    await expectLater(enviarFoto(foto()), throwsA(isA<StateError>()));
  });

  test('envia bytes e preset, devolve URL HTTPS', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        'https://api.cloudinary.com/v1_1/campus/image/upload',
      );
      expect(request.headers['content-type'], contains('multipart/form-data'));
      expect(request.body, contains('preset-teste'));
      expect(request.body, contains('filename="foto.png"'));
      return http.Response(
        jsonEncode({
          'secure_url': 'https://res.cloudinary.com/campus/foto.png',
        }),
        200,
      );
    });
    expect(
      await enviarFoto(
        foto(),
        client: client,
        cloudName: 'campus',
        uploadPreset: 'preset-teste',
      ),
      'https://res.cloudinary.com/campus/foto.png',
    );
  });

  test('recusa mais de 2 MB antes de chamar a rede', () async {
    final client = MockClient((_) async => fail('Não deveria enviar'));
    await expectLater(
      enviarFoto(
        foto(2 * 1024 * 1024 + 1),
        client: client,
        cloudName: 'campus',
        uploadPreset: 'teste',
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('aceita o limite de 2 MB', () async {
    final client = MockClient(
      (_) async =>
          http.Response('{"secure_url":"https://example.com/foto.png"}', 200),
    );
    expect(
      await enviarFoto(
        foto(2 * 1024 * 1024),
        client: client,
        cloudName: 'campus',
        uploadPreset: 'teste',
      ),
      'https://example.com/foto.png',
    );
  });

  test('recusa erro HTTP, JSON inválido e URL ausente ou insegura', () async {
    for (final response in [
      http.Response('{"error": {"message": "falha"}}', 400),
      http.Response('inválido', 200),
      http.Response('{}', 200),
      http.Response('{"secure_url":"http://example.com/foto.png"}', 200),
    ]) {
      await expectLater(
        enviarFoto(
          foto(),
          client: MockClient((_) async => response),
          cloudName: 'campus',
          uploadPreset: 'teste',
        ),
        throwsA(isA<StateError>()),
      );
    }
  });
}
