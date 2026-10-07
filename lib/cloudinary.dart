import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'config.dart';

Future<String> enviarFoto(
  XFile foto, {
  http.Client? client,
  String cloudName = cloudinaryCloudName,
  String uploadPreset = cloudinaryUploadPreset,
}) async {
  if (cloudName.isEmpty || uploadPreset.isEmpty) {
    throw StateError(
      'Fotos indisponíveis: configure o Cloudinary ou publique sem foto.',
    );
  }
  if (await foto.length() > limiteFotoBytes) {
    throw ArgumentError('A foto deve ter no máximo 2 MB.');
  }
  final bytes = await foto.readAsBytes();
  if (bytes.isEmpty || bytes.length > limiteFotoBytes) {
    throw ArgumentError('Escolha uma foto de até 2 MB.');
  }
  final cliente = client ?? http.Client();
  try {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.https('api.cloudinary.com', '/v1_1/$cloudName/image/upload'),
          )
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: foto.name),
          );
    final response = await http.Response.fromStream(
      await cliente.send(request).timeout(const Duration(seconds: 30)),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Não foi possível enviar a foto. Tente novamente ou publique sem foto.',
      );
    }
    final dados = jsonDecode(response.body);
    final url = dados is Map ? dados['secure_url'] : null;
    final uri = url is String ? Uri.tryParse(url) : null;
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError('O serviço de fotos não retornou uma URL válida.');
    }
    return url as String;
  } on Exception {
    throw StateError(
      'Não foi possível enviar a foto. Confira a conexão e tente novamente.',
    );
  } finally {
    if (client == null) cliente.close();
  }
}
