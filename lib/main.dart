import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'config.dart';
import 'firebase_local.dart';
import 'sessao.dart';
import 'telas/entrar.dart';
import 'telas/inicio.dart';
import 'telas/perfil.dart';
import 'telas/publicar.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await inicializarFirebaseLocal();
    runApp(const AppAchei());
  } catch (_) {
    runApp(
      MaterialApp(
        theme: temaAchei(),
        home: const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Não foi possível iniciar o app. Inicie os emuladores de Auth e Firestore e tente novamente.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppAchei extends StatefulWidget {
  const AppAchei({super.key, this.sessao});
  final Sessao? sessao;

  @override
  State<AppAchei> createState() => _AppAcheiState();
}

class _AppAcheiState extends State<AppAchei> {
  late final _sessao = widget.sessao ?? Sessao();
  late final _usuarios = _sessao.auth.authStateChanges();
  late final _tema = temaAchei();

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: _usuarios,
    initialData: _sessao.usuario,
    builder: (context, snapshot) => MaterialApp(
      // Trocar de conta também precisa descartar as rotas da sessão anterior.
      key: ValueKey(snapshot.data?.uid),
      title: 'Achei no Campus',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: _tema,
      debugShowCheckedModeBanner: false,
      home: snapshot.data == null
          ? TelaEntrar(sessao: _sessao)
          : _Portao(sessao: _sessao),
      onGenerateRoute: (settings) {
        final destino = switch (settings.name) {
          '/publicar' => () => TelaPublicar(sessao: _sessao),
          '/perfil' => () => TelaPerfil(sessao: _sessao),
          _ => null,
        };
        if (destino == null) return null;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => _Portao(sessao: _sessao, destino: destino),
        );
      },
    ),
  );
}

class _Portao extends StatefulWidget {
  const _Portao({required this.sessao, this.destino});
  final Sessao sessao;
  final Widget Function()? destino;

  @override
  State<_Portao> createState() => _PortaoState();
}

class _PortaoState extends State<_Portao> {
  late Future<bool> _acesso = widget.sessao.prepararAcesso();

  void _verificar() => setState(() => _acesso = widget.sessao.prepararAcesso());

  @override
  Widget build(BuildContext context) {
    final user = widget.sessao.usuario;
    if (user == null) return TelaEntrar(sessao: widget.sessao);
    if (!emailPermitido(user.email ?? '')) {
      return Scaffold(
        appBar: AppBar(title: const Text('E-mail não permitido')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Use seu e-mail @cs.unipe.edu.br.'),
              TextButton(
                onPressed: widget.sessao.sair,
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      );
    }
    return FutureBuilder<bool>(
      future: _acesso,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Não foi possível carregar')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mensagemDeErro(snapshot.error!)),
                    FilledButton(
                      onPressed: _verificar,
                      child: const Text('Tentar novamente'),
                    ),
                    TextButton(
                      onPressed: widget.sessao.sair,
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.data != true) {
          return TelaVerificar(sessao: widget.sessao, aoVerificar: _verificar);
        }
        // Logado e verificado: abre as abas (Feed, Mensagens, Meus itens).
        return widget.destino?.call() ?? TelaInicio(sessao: widget.sessao);
      },
    );
  }
}
