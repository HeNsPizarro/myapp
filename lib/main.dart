import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mendo_eventos/firebase_options.dart';
import 'package:mendo_eventos/pantallas/comentarios_screen.dart';
import 'package:mendo_eventos/pantallas/crear_evento.dart';
import 'package:mendo_eventos/pantallas/detalles_eventos.dart';
import 'package:mendo_eventos/pantallas/home_screen.dart';
import 'package:mendo_eventos/pantallas/inicio_buscador.dart';
import 'package:mendo_eventos/pantallas/inicio_creador.dart';
import 'package:mendo_eventos/pantallas/modificar_user.dart';
import 'package:mendo_eventos/pantallas/notificaciones_screen.dart';
import 'package:mendo_eventos/pantallas/perfil_usuario.dart';
import 'package:mendo_eventos/pantallas/autenticacion_screen.dart';
import 'package:mendo_eventos/pantallas/login_screen.dart';
import 'package:mendo_eventos/pantallas/registro_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configuración de persistencia de sesión
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  
  // Verificación inicial de autenticación
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) {
    await auth.currentUser!.reload(); // Actualiza el estado del usuario
  }

  runApp(const MendoEventosApp());
}

class MendoEventosApp extends StatelessWidget {
  const MendoEventosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MendoEventos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Mientras verifica el estado de autenticación
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Usuario autenticado
          if (snapshot.hasData && snapshot.data != null) {
            // Verificar si el email está verificado (opcional)
            if (!snapshot.data!.emailVerified) {
              // Puedes redirigir a pantalla de verificación si lo necesitas
            }
            return const HomeScreen();
          }
          
          // Usuario no autenticado
          return const AutenticacionScreen();
        },
      ),
      routes: {
        '/elegir-modo': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/feed-creador': (context) => const FeedCreatorScreen(),
        '/crear-evento': (context) => const CrearEventoScreen(),
        '/buscar-eventos': (context) => const InicioBuscadorScreen(),
        '/perfil': (context) => const PerfilUsuarioScreen(),
        '/modificar-usuario': (context) => const ModificarUsuarioScreen(usuario: {},),
        '/notificaciones': (context) => NotificacionesScreen(),
        '/comentarios': (context) {
          final evento = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ComentariosScreen(evento: evento);
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/detalles-evento') {
          final evento = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => DetallesEventoScreen(evento: evento),
          );
        }
        return MaterialPageRoute(
          builder: (context) =>
              const Scaffold(body: Center(child: Text('Ruta no encontrada'))),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}