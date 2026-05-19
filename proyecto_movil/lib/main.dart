import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'signup_page.dart';
import 'landing_page.dart';
import 'reset_password_page.dart';
import 'personalize_experience_page.dart';
import 'dashboard_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kfkdkvjjmwpvhnwtbfcs.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtma2RrdmpqbXdwdmhud3RiZmNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM5ODI3ODMsImV4cCI6MjA4OTU1ODc4M30.YwVL0FrcAeoborQb-iZTyIWgYw-rd83F0wb3vqah1Y8',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isHandlingRecoveryFlow = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _initializeAuth();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Capturar enlace si la app estaba cerrada
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }

    // Escuchar enlaces mientras la app está abierta o en segundo plano
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        print('**** APP LINK RECEIVED: $uri ****');
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('**** APP LINK ERROR: $err ****');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    print('**** PROCESSING DEEP LINK: $uri ****');
    if (_isRecoveryUri(uri)) {
      print('**** NAVIGATING TO RESET PASSWORD PAGE FROM DEEP LINK ****');
      _isHandlingRecoveryFlow = true;

      _establishRecoverySessionFromUri(uri);

      // Esperar para evitar el error de renderizado en Android al reanudar
      Future.delayed(const Duration(milliseconds: 800), () {
        if (navigatorKey.currentState != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('Enlace detectado, redirigiendo...'),
              duration: Duration(seconds: 2),
            ),
          );
          navigatorKey.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) =>
                  const ResetPasswordPage(requireOtpVerification: false),
            ),
            (route) => false,
          );
        }
      });
    }
  }

  Future<void> _initializeAuth() async {
    // Primero, intentar procesar tokens de recuperación en la URL
    await _handlePasswordRecoveryToken();

    // Luego, escuchar cambios de autenticación
    if (mounted) {
      _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        final event = data.event;
        final uri = Uri.base;

        print('**** EVENT DETECTED: $event');
        print('**** FULL URI: ${uri.toString()}');
        print('**** QUERY PARAMS: ${uri.queryParameters}');
        print('**** FRAGMENT: ${uri.fragment}');

        if (mounted) {
          final bool isPasswordRecovery =
              event == AuthChangeEvent.passwordRecovery || _isRecoveryUri(uri);

          if (isPasswordRecovery) {
            _isHandlingRecoveryFlow = true;
            print('**** REDIRECTING TO RESET PASSWORD PAGE ****');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) =>
                    const ResetPasswordPage(requireOtpVerification: false),
              ),
              (route) => false,
            );
          } else if (_isHandlingRecoveryFlow) {
            return;
          } else if (session != null) {
            _checkProfileAndNavigate(session.user.id);
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LandingPage()),
              (route) => false,
            );
          }
        }
      });
    }
  }

  Future<void> _handlePasswordRecoveryToken() async {
    final uri = Uri.base;

    print('**** CHECKING FOR RECOVERY TOKEN ****');
    print('**** FULL URI: ${uri.toString()}');

    if (_isRecoveryUri(uri)) {
      _isHandlingRecoveryFlow = true;
      await _establishRecoverySessionFromUri(uri);
    }
  }

  bool _isRecoveryUri(Uri uri) {
    return uri.toString().contains('type=recovery') ||
        uri.fragment.contains('type=recovery') ||
        uri.queryParameters.containsKey('code') ||
        uri.fragment.contains('access_token') ||
        uri.fragment.contains('refresh_token');
  }

  Future<void> _establishRecoverySessionFromUri(Uri uri) async {
    final code = uri.queryParameters['code'];

    if (code != null && code.isNotEmpty) {
      try {
        await supabase.auth.exchangeCodeForSession(code);
        print('**** RECOVERY SESSION ESTABLISHED FROM CODE ****');
      } catch (e) {
        print('**** ERROR EXCHANGING CODE FOR SESSION: $e ****');
      }
      return;
    }

    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      try {
        final params = Uri.splitQueryString(fragment);
        final refreshToken = params['refresh_token'];
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await supabase.auth.setSession(refreshToken);
          print('**** RECOVERY SESSION ESTABLISHED FROM FRAGMENT ****');
        }
      } catch (e) {
        print('**** ERROR SETTING SESSION FROM FRAGMENT: $e ****');
      }
    }
  }

  Future<void> _checkProfileAndNavigate(String userId) async {
    try {
      final data = await supabase
          .from('profiles')
          .select('is_complete')
          .eq('id', userId)
          .maybeSingle(); // Usar maybeSingle por seguridad

      if (data == null) {
        // Si el perfil no existe, el usuario debe crearlo/completarlo
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const PersonalizeExperiencePage(),
            ),
            (route) => false,
          );
        }
        return;
      }

      final bool isComplete = data['is_complete'] ?? false;

      if (mounted) {
        if (isComplete) {
          // Si está completo, vamos al Dashboard
          print('**** NAVIGATING TO DASHBOARD ****');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardPage()),
            (route) => false,
          );
        } else {
          // Si no está completo, vamos a la página de personalización
          print(
            '**** NAVIGATING TO PERSONALIZE PAGE (is_complete: $isComplete) ****',
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const PersonalizeExperiencePage(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('Error checking profile completion: $e');
      // En caso de error (ej. perfil no existe aún), enviamos a completar perfil
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const PersonalizeExperiencePage(),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga inicial mientras se verifica la sesión
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignUpPage()),
          );
        },
        tooltip: 'Registro',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
