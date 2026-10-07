import 'package:flutter/material.dart';

import '../sessao.dart';

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key, required this.sessao});
  final Sessao sessao;

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _curso = TextEditingController();
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final perfil = await widget.sessao.firestore
          .collection('usuarios')
          .doc(widget.sessao.usuario!.uid)
          .get();
      if (!mounted) return;
      _nome.text = perfil.data()?['nome'] as String? ?? '';
      _curso.text = perfil.data()?['curso'] as String? ?? '';
    } catch (erro) {
      if (mounted) setState(() => _erro = mensagemDeErro(erro));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.sessao.salvarPerfil(_nome.text, _curso.text);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
      }
    } catch (erro) {
      if (mounted) setState(() => _erro = mensagemDeErro(erro));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _curso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil')),
    body: _carregando
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(widget.sessao.usuario?.email ?? ''),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const Key('nome'),
                        controller: _nome,
                        maxLength: 80,
                        enabled: !_salvando,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (valor) =>
                            valor == null || valor.trim().isEmpty
                            ? 'Informe seu nome.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('curso'),
                        controller: _curso,
                        maxLength: 120,
                        enabled: !_salvando,
                        decoration: const InputDecoration(
                          labelText: 'Curso (opcional)',
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_erro != null) ...[
                        Text(
                          _erro!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        TextButton(
                          onPressed: _carregar,
                          child: const Text('Carregar novamente'),
                        ),
                      ],
                      FilledButton(
                        onPressed: _salvando ? null : _salvar,
                        child: Text(_salvando ? 'Salvando…' : 'Salvar perfil'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _salvando ? null : widget.sessao.sair,
                        child: const Text('Sair'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
  );
}
