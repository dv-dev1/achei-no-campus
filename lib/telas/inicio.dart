// Tela de início: a barra de abas de baixo, com Feed, Mensagens e
// Meus itens. É a primeira tela depois do login.
//
// As três abas ficam vivas ao mesmo tempo (IndexedStack): trocar de aba não
// perde a rolagem, os filtros do feed nem o que estava carregado.

import 'package:flutter/material.dart';

import '../conversas.dart';
import '../sessao.dart';
import 'feed.dart';
import 'mensagens.dart';
import 'meus_itens.dart';

class TelaInicio extends StatefulWidget {
  const TelaInicio({super.key, required this.sessao});

  final Sessao sessao;

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  int _aba = 0;

  // Criados uma vez só, como as consultas das outras telas.
  late final String _uid = widget.sessao.usuario!.uid;
  late final Stream<int> _naoLidas = Conversas(sessao: widget.sessao)
      .totalNaoLidas();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _aba,
        children: [
          TelaFeed(
            sessao: widget.sessao,
            uidDoUsuario: _uid,
            itens: itensAbertosDoFirestore(firestore: widget.sessao.firestore),
          ),
          TelaMensagens(sessao: widget.sessao),
          TelaMeusItens(sessao: widget.sessao, uidDoUsuario: _uid),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (aba) => setState(() => _aba = aba),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: _ComContador(
              naoLidas: _naoLidas,
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: _ComContador(
              naoLidas: _naoLidas,
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Mensagens',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Meus itens',
          ),
        ],
      ),
    );
  }
}

/// Ícone com o número de mensagens não lidas em cima, quando há alguma.
class _ComContador extends StatelessWidget {
  const _ComContador({required this.naoLidas, required this.child});

  final Stream<int> naoLidas;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: naoLidas,
      builder: (context, snapshot) {
        final total = snapshot.data ?? 0;
        final cores = Theme.of(context).colorScheme;
        return Badge(
          isLabelVisible: total > 0,
          // Azul, e não o amarelo padrão do tema: com a aba selecionada, o
          // fundo dela já é amarelo e o número sumiria.
          backgroundColor: cores.primary,
          textColor: cores.onPrimary,
          // Mais de 99 vira "99+", para o número caber.
          label: Text(total > 99 ? '99+' : '$total'),
          child: child,
        );
      },
    );
  }
}
