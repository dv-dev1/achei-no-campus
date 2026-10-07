import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../cloudinary.dart';
import '../config.dart';
import '../itens.dart';
import '../modelos/item.dart';
import '../sessao.dart';

class TelaPublicar extends StatefulWidget {
  const TelaPublicar({super.key, required this.sessao, this.item});
  final Sessao sessao;
  final Item? item;

  @override
  State<TelaPublicar> createState() => _TelaPublicarState();
}

class _TelaPublicarState extends State<TelaPublicar> {
  final _form = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.item?.titulo);
  late final _descricao = TextEditingController(text: widget.item?.descricao);
  late String _tipo = widget.item?.tipo ?? 'perdido';
  late String? _categoria = widget.item?.categoria;
  late String? _local = widget.item?.local;
  late String _fotoUrl = widget.item?.fotoUrl ?? '';
  XFile? _foto;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    try {
      final foto = await ImagePicker().pickImage(
        source: origem,
        maxWidth: 1280,
        imageQuality: 70,
      );
      if (foto == null || !mounted) return;
      if (await foto.length() > limiteFotoBytes) {
        throw ArgumentError('A foto deve ter no máximo 2 MB.');
      }
      if (mounted) {
        setState(() {
          _foto = foto;
          _erro = null;
        });
      }
    } catch (erro) {
      if (mounted) setState(() => _erro = mensagemDeErro(erro));
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      if (_foto != null) {
        _fotoUrl = await enviarFoto(_foto!);
        _foto = null;
      }
      await Itens(sessao: widget.sessao).salvar(
        item: widget.item,
        tipo: _tipo,
        titulo: _titulo.text,
        descricao: _descricao.text,
        categoria: _categoria!,
        local: _local!,
        fotoUrl: _fotoUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.item == null ? 'Item publicado.' : 'Item atualizado.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (erro) {
      if (mounted) setState(() => _erro = mensagemDeErro(erro));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.item == null ? 'Publicar item' : 'Editar item'),
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'perdido', child: Text('Perdido')),
                    DropdownMenuItem(value: 'achado', child: Text('Achado')),
                  ],
                  onChanged: _enviando
                      ? null
                      : (valor) => setState(() => _tipo = valor!),
                  validator: (valor) =>
                      valor == null ? 'Escolha o tipo.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('titulo'),
                  controller: _titulo,
                  enabled: !_enviando,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (valor) => valor == null || valor.trim().isEmpty
                      ? 'Informe o título.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricao,
                  enabled: !_enviando,
                  maxLength: 2000,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('categoria'),
                  initialValue: _categoria,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: categorias
                      .map(
                        (valor) =>
                            DropdownMenuItem(value: valor, child: Text(valor)),
                      )
                      .toList(),
                  onChanged: _enviando
                      ? null
                      : (valor) => setState(() => _categoria = valor),
                  validator: (valor) =>
                      valor == null ? 'Escolha a categoria.' : null,
                ),
                if (_categoria == 'Documentos')
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Cubra CPF/RG na foto antes de publicar.'),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('local'),
                  initialValue: _local,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Local'),
                  items: locais
                      .map(
                        (valor) => DropdownMenuItem(
                          value: valor,
                          child: Text(valor, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: _enviando
                      ? null
                      : (valor) => setState(() => _local = valor),
                  validator: (valor) =>
                      valor == null ? 'Escolha o local.' : null,
                ),
                const SizedBox(height: 24),
                Text(
                  _foto?.name ??
                      (_fotoUrl.isEmpty
                          ? 'Foto opcional · até 2 MB'
                          : 'Foto atual preservada.'),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _enviando
                          ? null
                          : () => _escolherFoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galeria'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _enviando
                          ? null
                          : () => _escolherFoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Câmera'),
                    ),
                    if (_foto != null || _fotoUrl.isNotEmpty)
                      TextButton(
                        onPressed: _enviando
                            ? null
                            : () => setState(() {
                                _foto = null;
                                _fotoUrl = '';
                              }),
                        child: const Text('Remover foto'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_erro != null) ...[
                  Text(
                    _erro!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: _enviando ? null : _salvar,
                  child: Text(
                    _enviando
                        ? 'Salvando…'
                        : widget.item == null
                        ? 'Publicar item'
                        : 'Salvar alterações',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
