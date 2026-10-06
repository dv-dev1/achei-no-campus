// Card de um item no feed: foto, etiqueta perdido/achado, título,
// categoria, local e há quanto tempo foi publicado.
//
// O visual (cor, fonte, canto arredondado) vem todo do tema.

import 'package:flutter/material.dart';

import '../modelos/item.dart';
import '../util/tempo.dart';

class CardItem extends StatelessWidget {
  const CardItem({super.key, required this.item, this.aoTocar});

  final Item item;

  /// O que fazer ao tocar no card. No feed, abre o detalhe.
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: aoTocar,
        // IntrinsicHeight + stretch: a foto acompanha a altura do texto,
        // sem sobrar faixa branca embaixo dela.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Foto(item: item),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EtiquetaTipo(tipo: item.tipo),
                      const SizedBox(height: 6),
                      Text(
                        item.titulo,
                        style: textos.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.categoria} · ${item.local}',
                        style: textos.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(tempoDesde(item.criadoEm), style: textos.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta "Perdido" (amarela) ou "Achado" (azul).
///
/// Fica separada do card porque o detalhe e "Meus itens" também usam.
class EtiquetaTipo extends StatelessWidget {
  const EtiquetaTipo({super.key, required this.tipo});

  final String tipo;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final perdido = tipo == 'perdido';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: perdido ? cores.secondary : cores.primary,
        borderRadius: BorderRadius.circular(100), // pílula
      ),
      child: Text(
        perdido ? 'Perdido' : 'Achado',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: perdido ? cores.onSecondary : cores.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Foto à esquerda do card, com a altura do card. Sem foto, ou se o link falhar,
/// mostra um ícone no lugar.
class _Foto extends StatelessWidget {
  const _Foto({required this.item});

  final Item item;

  static const double _lado = 110; // largura

  @override
  Widget build(BuildContext context) {
    final semFoto = Container(
      width: _lado,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      child: Icon(
        Icons.image_outlined,
        size: 36,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    if (!item.temFoto) return semFoto;

    return Image.network(
      item.fotoUrl,
      width: _lado,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => semFoto,
    );
  }
}
