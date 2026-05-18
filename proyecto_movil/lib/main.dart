import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_page.dart';
import 'login_page.dart';
import 'landing_page.dart';
import 'reset_password_page.dart';
import 'personalize_experience_page.dart';
import 'dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kfkdkvjjmwpvhnwtbfcs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtma2RrdmpqbXdwdmhud3RiZmNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM5ODI3ODMsImV4cCI6MjA4OTU1ODc4M30.YwVL0FrcAeoborQb-iZTyIWgYw-rd83F0wb3vqah1Y8',
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
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Primero, intentar procesar tokens de recuperación en la URL
    await _handlePasswordRecoveryToken();
    
    // Luego, escuchar cambios de autenticación
    if (mounted) {
      supabase.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        final event = data.event;
        final uri = Uri.base;

        print('**** EVENT DETECTED: $event');
        print('**** FULL URI: ${uri.toString()}');
        print('**** QUERY PARAMS: ${uri.queryParameters}');
        print('**** FRAGMENT: ${uri.fragment}');

        if (mounted) {
          bool isPasswordRecovery = 
            event == AuthChangeEvent.passwordRecovery ||
            uri.toString().contains('type=recovery') ||
            uri.queryParameters.containsKey('code') ||
            uri.fragment.contains('type=recovery');

          if (isPasswordRecovery) {
            print('**** REDIRECTING TO RESET PASSWORD PAGE ****');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
              (route) => false,
            );
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
    final fragment = uri.fragment;
    final code = uri.queryParameters['code'];

    print('**** CHECKING FOR RECOVERY TOKEN ****');
    print('**** FRAGMENT: $fragment');
    print('**** CODE PARAM: $code');

    // Si hay un código en los query parameters (método más común de Supabase)
    if (code != null) {
      try {
        print('**** FOUND CODE PARAMETER: $code ****');
        // Supabase procesa automáticamente el código cuando está en los parámetros
        // La sesión se establece automáticamente
        print('**** SESSION SHOULD BE ESTABLISHED FROM CODE ****');
      } catch (e) {
        print('**** ERROR HANDLING CODE: $e ****');
      }
    }

    // Si hay tokens en el fragmento (method=2 de Supabase)
    if (fragment.isNotEmpty && fragment.contains('access_token')) {
      try {
        print('**** FOUND ACCESS TOKEN IN FRAGMENT ****');
        final params = Uri.splitQueryString(fragment);
        final accessToken = params['access_token'];
        final refreshToken = params['refresh_token'];

        if (accessToken != null) {
          // Establecer sesión con los tokens
          final session = await supabase.auth.setSession(accessToken);
          print('**** SESSION ESTABLISHED: ${session?.user?.email} ****');
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
            MaterialPageRoute(builder: (context) => const PersonalizeExperiencePage()),
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
          print('**** NAVIGATING TO PERSONALIZE PAGE (is_complete: $isComplete) ****');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const PersonalizeExperiencePage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('Error checking profile completion: $e');
      // En caso de error (ej. perfil no existe aún), enviamos a completar perfil
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PersonalizeExperiencePage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga inicial mientras se verifica la sesión
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
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
