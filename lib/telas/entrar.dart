import 'package:flutter/material.dart';

import '../config.dart';
import '../sessao.dart';

class TelaEntrar extends StatefulWidget {
  const TelaEntrar({super.key, required this.sessao});
  final Sessao sessao;

  @override
  State<TelaEntrar> createState() => _TelaEntrarState();
}

class _TelaEntrarState extends State<TelaEntrar> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _cadastro = false;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      if (_cadastro) {
        await widget.sessao.cadastrar(_nome.text, _email.text, _senha.text);
      } else {
        await widget.sessao.entrar(_email.text, _senha.text);
      }
    } catch (erro) {
      if (mounted) setState(() => _erro = mensagemDeErro(erro));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_cadastro ? 'Criar conta' : 'Entrar')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Achei no Campus',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Achados e perdidos da UNIPÊ. $avisoDominio'),
                    const SizedBox(height: 24),
                    if (_cadastro) ...[
                      TextFormField(
                        key: const Key('nome'),
                        controller: _nome,
                        enabled: !_enviando,
                        maxLength: 80,
                        autofillHints: const [AutofillHints.name],
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (valor) =>
                            valor == null || valor.trim().isEmpty
                            ? 'Informe seu nome.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      key: const Key('email'),
                      controller: _email,
                      enabled: !_enviando,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'E-mail acadêmico',
                      ),
                      validator: (valor) =>
                          emailPermitido(valor ?? '') ? null : avisoDominio,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('senha'),
                      controller: _senha,
                      enabled: !_enviando,
                      obscureText: true,
                      autofillHints: [
                        _cadastro
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: const InputDecoration(labelText: 'Senha'),
                      validator: (valor) => (valor ?? '').length < 6
                          ? 'Use pelo menos 6 caracteres.'
                          : null,
                      onFieldSubmitted: (_) {
                        if (!_enviando) _enviar();
                      },
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
                      onPressed: _enviando ? null : _enviar,
                      child: Text(
                        _enviando
                            ? 'Aguarde…'
                            : _cadastro
                            ? 'Criar conta'
                            : 'Entrar',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _enviando
                          ? null
                          : () => setState(() {
                              _cadastro = !_cadastro;
                              _erro = null;
                              _form.currentState?.reset();
                            }),
                      child: Text(
                        _cadastro ? 'Já tenho conta' : 'Criar uma conta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
