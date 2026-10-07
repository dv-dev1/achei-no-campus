// Tela da conversa sobre um item: as mensagens em tempo real e, embaixo,
// o campo para escrever.
//
// Abre de dois jeitos:
//   - pelo botão Conversar, no detalhe do item (a conversa pode ainda não
//     existir; ela nasce na primeira mensagem);
//   - pela aba Mensagens (a conversa já existe).

import 'dart:async';

import 'package:flutter/material.dart';

import '../conversas.dart';
import '../modelos/conversa.dart';
import '../sessao.dart';
import '../widgets/aviso.dart';

class TelaConversa extends StatefulWidget {
  const TelaConversa({
    super.key,
    required this.conversa,
    required this.tituloDoItem,
    this.sessao,
  });

  /// A conversa, existente ou nova (`Conversa.nova`).
  final Conversa conversa;
  final String tituloDoItem;
  final Sessao? sessao;

  @override
  State<TelaConversa> createState() => _TelaConversaState();
}

class _TelaConversaState extends State<TelaConversa> {
  late final _conversas = Conversas(sessao: widget.sessao);
  late final String _uid = _conversas.sessao.usuario!.uid;

  // Não dá para ler uma conversa que ainda não existe (as regras negam).
  // Por isso a tela escuta a lista de conversas do usuário, que é permitida,
  // e procura esta nela. Quando aparece, a conversa existe.
  late final Stream<List<Conversa>> _minhas = _conversas.minhas();
  Stream<List<Mensagem>>? _mensagens;

  final _texto = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tituloDoItem)),
      body: StreamBuilder<List<Conversa>>(
        stream: _minhas,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Aviso(
              icone: Icons.cloud_off,
              texto: 'Não foi possível carregar a conversa.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final atual = _procurar(snapshot.data!);
          return Column(
            children: [
              Expanded(child: _listaDeMensagens(atual)),
              _CampoDeTexto(
                controle: _texto,
                enviando: _enviando,
                aoEnviar: () => _enviar(jaExiste: atual != null),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Esta conversa na lista do usuário, ou nulo se ainda não existe.
  Conversa? _procurar(List<Conversa> lista) {
    for (final conversa in lista) {
      if (conversa.id == widget.conversa.id) {
        // Chegou mensagem com a conversa aberta: já está lida.
        if (conversa.naoLidasDe(_uid) > 0) {
          unawaited(_conversas.marcarComoLida(conversa));
        }
        return conversa;
      }
    }
    return null;
  }

  Widget _listaDeMensagens(Conversa? atual) {
    if (atual == null) {
      return Aviso(
        icone: Icons.chat_bubble_outline,
        texto:
            'Mande a primeira mensagem sobre\n"${widget.tituloDoItem}".\n'
            'Combine onde e quando devolver.',
      );
    }

    // As mensagens só podem ser lidas depois que a conversa existe.
    _mensagens ??= _conversas.mensagens(atual.id);

    return StreamBuilder<List<Mensagem>>(
      stream: _mensagens,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final mensagens = snapshot.data!;

        // `reverse` deixa a lista grudada embaixo, na mensagem mais nova,
        // como em todo app de conversa.
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemCount: mensagens.length,
          itemBuilder: (context, i) {
            final mensagem = mensagens[mensagens.length - 1 - i];
            return _Balao(mensagem: mensagem, minha: mensagem.autorId == _uid);
          },
        );
      },
    );
  }

  Future<void> _enviar({required bool jaExiste}) async {
    final texto = _texto.text;
    if (texto.trim().isEmpty || _enviando) return;

    setState(() => _enviando = true);
    try {
      await _conversas.enviar(widget.conversa, texto, jaExiste: jaExiste);
      _texto.clear();
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensagemDeErro(erro))));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}

/// Um balão de mensagem: as minhas à direita, em azul; as do outro à
/// esquerda, em branco.
class _Balao extends StatelessWidget {
  const _Balao({required this.mensagem, required this.minha});

  final Mensagem mensagem;
  final bool minha;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final corDoTexto = minha ? cores.onPrimary : cores.onSurface;

    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    final hora =
        '${doisDigitos(mensagem.criadoEm.hour)}:'
        '${doisDigitos(mensagem.criadoEm.minute)}';

    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        // O balão ocupa no máximo 75% da largura, para dar o lado.
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          decoration: BoxDecoration(
            color: minha ? cores.primary : cores.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              // O canto "da ponta" fica reto, do lado de quem falou.
              bottomLeft: Radius.circular(minha ? 16 : 4),
              bottomRight: Radius.circular(minha ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mensagem.texto,
                style: textos.bodyLarge?.copyWith(color: corDoTexto),
              ),
              const SizedBox(height: 2),
              Text(
                hora,
                style: textos.labelSmall?.copyWith(
                  color: corDoTexto.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de texto e botão de enviar, presos embaixo da tela.
class _CampoDeTexto extends StatelessWidget {
  const _CampoDeTexto({
    required this.controle,
    required this.enviando,
    required this.aoEnviar,
  });

  final TextEditingController controle;
  final bool enviando;
  final VoidCallback aoEnviar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controle,
                minLines: 1,
                maxLines: 4,
                maxLength: limiteDaMensagem,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Escreva uma mensagem',
                  counterText: '', // esconde o "0/5000"
                ),
                onSubmitted: (_) => aoEnviar(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Enviar',
              onPressed: enviando ? null : aoEnviar,
              icon: enviando
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
