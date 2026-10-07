// Aba Mensagens: todas as conversas do usuário, a mais recente primeiro.
// Cada linha mostra o item, com quem é a conversa, a última mensagem, a hora
// e quantas mensagens ainda não foram lidas.

import 'package:flutter/material.dart';

import '../conversas.dart';
import '../modelos/conversa.dart';
import '../modelos/item.dart';
import '../sessao.dart';
import '../widgets/aviso.dart';
import 'conversa.dart';

class TelaMensagens extends StatefulWidget {
  const TelaMensagens({super.key, this.sessao});

  final Sessao? sessao;

  @override
  State<TelaMensagens> createState() => _TelaMensagensState();
}

class _TelaMensagensState extends State<TelaMensagens> {
  late final _conversas = Conversas(sessao: widget.sessao);
  late final String _uid = _conversas.sessao.usuario!.uid;
  late final Stream<List<Conversa>> _minhas = _conversas.minhas();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
      body: StreamBuilder<List<Conversa>>(
        stream: _minhas,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Aviso(
              icone: Icons.cloud_off,
              texto:
                  'Não foi possível carregar as conversas.\n'
                  'Confira sua conexão e tente de novo.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversas = snapshot.data!;
          if (conversas.isEmpty) {
            return const Aviso(
              icone: Icons.forum_outlined,
              texto:
                  'Nenhuma conversa ainda.\n'
                  'Para falar com quem publicou um item, '
                  'toque em Conversar no detalhe dele.',
            );
          }

          return ListView.separated(
            itemCount: conversas.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _LinhaDaConversa(
              conversa: conversas[i],
              uid: _uid,
              conversas: _conversas,
            ),
          );
        },
      ),
    );
  }
}

class _LinhaDaConversa extends StatelessWidget {
  const _LinhaDaConversa({
    required this.conversa,
    required this.uid,
    required this.conversas,
  });

  final Conversa conversa;
  final String uid;
  final Conversas conversas;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cores = Theme.of(context).colorScheme;
    final naoLidas = conversa.naoLidasDe(uid);
    final temNovidade = naoLidas > 0;

    // Título do item e nome do outro vêm de outros documentos; enquanto
    // não chegam, aparece "...". Os Futures ficam guardados no serviço,
    // então a linha não pisca a cada redesenho.
    return FutureBuilder<Item?>(
      future: conversas.item(conversa.itemId),
      builder: (context, item) => FutureBuilder<String>(
        future: conversas.nomeDe(conversa.outro(uid)),
        builder: (context, nomeDoOutro) {
          final titulo = item.connectionState != ConnectionState.done
              ? '...'
              : item.data?.titulo ?? 'Item removido';
          final nome = nomeDoOutro.data ?? '...';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: cores.primary,
              foregroundColor: cores.onPrimary,
              child: Text(nome == '...' ? '?' : nome[0].toUpperCase()),
            ),
            title: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: temNovidade ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'com $nome · ${conversa.ultimaMensagem}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  horaCurta(conversa.atualizadoEm),
                  style: textos.labelSmall,
                ),
                const SizedBox(height: 4),
                if (temNovidade) Badge(label: Text('$naoLidas')),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TelaConversa(
                  conversa: conversa,
                  tituloDoItem: titulo,
                  sessao: conversas.sessao,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Hora da última mensagem: "14:30" se foi hoje, "ontem", ou "05/10".
String horaCurta(DateTime data, {DateTime? agora}) {
  final hoje = agora ?? DateTime.now();
  String doisDigitos(int n) => n.toString().padLeft(2, '0');

  final mesmoDia =
      data.year == hoje.year &&
      data.month == hoje.month &&
      data.day == hoje.day;
  if (mesmoDia) return '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';

  final ontem = hoje.subtract(const Duration(days: 1));
  if (data.year == ontem.year &&
      data.month == ontem.month &&
      data.day == ontem.day) {
    return 'ontem';
  }
  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}';
}
