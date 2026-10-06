/// Texto curto de "há quanto tempo", usado nos cards do feed.
///
/// Exemplos: "agora mesmo", "há 5 min", "há 2 h", "ontem", "há 3 dias".
/// Depois de 30 dias mostra a data (ex.: "05/09/2026").
///
/// `agora` só existe para os testes poderem fixar o relógio.
String tempoDesde(DateTime data, {DateTime? agora}) {
  final diferenca = (agora ?? DateTime.now()).difference(data);

  if (diferenca.inMinutes < 1) return 'agora mesmo';
  if (diferenca.inHours < 1) return 'há ${diferenca.inMinutes} min';
  if (diferenca.inDays < 1) return 'há ${diferenca.inHours} h';
  if (diferenca.inDays == 1) return 'ontem';
  if (diferenca.inDays <= 30) return 'há ${diferenca.inDays} dias';

  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year}';
}
