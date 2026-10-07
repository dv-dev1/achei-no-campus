import 'package:achei_no_campus/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aceita somente o domínio acadêmico exato', () {
    for (final email in ['ana@cs.unipe.edu.br', ' ANA@CS.UNIPE.EDU.BR ']) {
      expect(emailPermitido(email), isTrue, reason: email);
    }
    for (final email in [
      'ana@gmail.com',
      'ana@cs.unipe.edu.br.evil.com',
      'ana@evilcs.unipe.edu.br',
      '@cs.unipe.edu.br',
      'ana@@cs.unipe.edu.br',
      'ana bruno@cs.unipe.edu.br',
      'cs.unipe.edu.br',
      '',
    ]) {
      expect(emailPermitido(email), isFalse, reason: email);
    }
  });
}
