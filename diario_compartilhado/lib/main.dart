import 'package:flutter/material.dart';
import 'local_auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import './navbar/Navbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MaterialApp(
      home: FutureBuilder(
        // Verifica se a inicialização do Firebase foi concluída
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Se a inicialização foi concluída, exibe o aplicativo
            return const LocalAuthApp();
          }

          // Enquanto a inicialização está em andamento, pode mostrar um indicador de carregamento
          return const CircularProgressIndicator();
        },
      ),
    ),
  );
}

class LocalAuthApp extends StatefulWidget {
  const LocalAuthApp({super.key});

  @override
  State<LocalAuthApp> createState() => _LocalAuthAppState();
}

class _LocalAuthAppState extends State<LocalAuthApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diario Compartilhados',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
      routes: {'NavBar': (context) => HomePage()},
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void onAuthenticate() async {
    try {
      if (!await LocalAuthService.hasSupport(biometricOnly: true)) {
        showMessage('O dispositivo não possui suporte a biometria');
        return;
      }

      if (!await LocalAuthService.authenticate(biometricOnly: true)) {
        showMessage('Autenticação não reconhecida');
        //Navigator.push(context, MaterialPageRoute(builder: (_) => HomePage()));
        return;
      }

      showMessage('Usuário autenticado');
      Navigator.push(context, MaterialPageRoute(builder: (_) => HomePage()));
      //Restante do código
    } catch (_) {
      showMessage('Erro ao realizar autenticação');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diario Compartilhado'),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: onAuthenticate,
          child: const Text('Entrar no Diario'),
        ),
      ),
    );
  }
}
