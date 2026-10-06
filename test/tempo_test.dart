import 'package:achei_no_campus/util/tempo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final agora = DateTime(2026, 10, 6, 15, 0);

  String ha(Duration d) => tempoDesde(agora.subtract(d), agora: agora);

  test('menos de um minuto é "agora mesmo"', () {
    expect(ha(const Duration(seconds: 30)), 'agora mesmo');
  });

  test('minutos e horas', () {
    expect(ha(const Duration(minutes: 5)), 'há 5 min');
    expect(ha(const Duration(hours: 2, minutes: 40)), 'há 2 h');
  });

  test('ontem e dias', () {
    expect(ha(const Duration(days: 1, hours: 3)), 'ontem');
    expect(ha(const Duration(days: 3)), 'há 3 dias');
  });

  test('depois de 30 dias mostra a data', () {
    expect(ha(const Duration(days: 31)), '05/09/2026');
  });
}
