import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mendo_eventos/pantallas/modificar_user.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, dynamic> _usuario;
  bool _isLoading = true;
  String? _errorMessage;
  final List<String> _fotosPerfil = [
    'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?w=500',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500',
    'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=500',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final User? user = _auth.currentUser;
      
      if (user == null) {
        _redirigirALogin();
        return;
      }

      final DocumentSnapshot doc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        await _crearDocumentoUsuario(user);
        await _cargarDatosUsuario();
        return;
      }

      setState(() {
        _usuario = {
          'nombre': doc['nombre'] ?? user.email?.split('@')[0] ?? 'Usuario',
          'email': doc['email'] ?? user.email ?? 'No especificado',
          'fotoUrl': doc['fotoUrl'] ?? user.photoURL ?? 'https://via.placeholder.com/150',
          'uid': user.uid,
        };
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos del usuario: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _crearDocumentoUsuario(User user) async {
    try {
      await _firestore.collection('usuarios').doc(user.uid).set({
        'email': user.email,
        'nombre': user.displayName ?? user.email?.split('@')[0] ?? 'Usuario',
        'fotoUrl': user.photoURL,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'rol': 'usuario',
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al crear perfil: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _redirigirALogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/login', 
        (route) => false
      );
    });
  }

  Future<void> _cerrarSesion() async {
    try {
      await _auth.signOut();
      _redirigirALogin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F0FF),
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _cargarDatosUsuario,
                child: const Text('Reintentar'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _cerrarSesion,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Foto de perfil
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _usuario['fotoUrl'],
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        size: 50,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Indicador para cambiar foto
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 154, 54, 194),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: _mostrarSelectorImagen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Nombre y email
            Text(
              _usuario['nombre'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _usuario['email'],
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            
            // Estadísticas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(0, 227, 185, 252),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    'Eventos',
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('eventos')
                          .where('creadorId', isEqualTo: _usuario['uid'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Text('0');
                        return Text(
                          '${snapshot.data!.docs.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 47, 33, 243),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildStatCard(
                    'Likes',
                    StreamBuilder<int>(
                      stream: _calcularTotalLikes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Text('0');
                        return Text(
                          '${snapshot.data}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                  _buildStatCard(
                    'Comentarios',
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collectionGroup('comentarios')
                          .where('eventoOwnerId', isEqualTo: _usuario['uid'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Text('0');
                        return Text(
                          '${snapshot.data!.docs.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 175, 76, 76),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Botones de acción
            Column(
              children: [
                ElevatedButton(
  onPressed: () async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModificarUsuarioScreen(usuario: _usuario),
      ),
    );
    
    if (updatedUser != null && mounted) {
      setState(() {
        _usuario['nombre'] = updatedUser['nombre'];
        if (updatedUser['fotoUrl'] != null) {
          _usuario['fotoUrl'] = updatedUser['fotoUrl'];
        }
      });
    }
  },
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 50),
    backgroundColor: const Color(0xFFEADDFF),
    side: const BorderSide(
      color: Colors.deepPurple, // Color del borde
      width: 1.5, // Grosor del borde
    ),
  ),
  child: const Text(
    'Editar perfil',
    style: TextStyle(fontSize: 16),
  ),
),
                const SizedBox(height: 16),
                OutlinedButton(
  onPressed: _cerrarSesion,
  style: OutlinedButton.styleFrom(
    backgroundColor: Colors.white, // Fondo blanco
    foregroundColor: Colors.red, // Color del texto
    side: const BorderSide(
      color: Colors.red, // Color del borde
      width: 1.5, // Grosor del borde
    ),
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8), // Bordes redondeados
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24), // Espaciado interno
    elevation: 0, // Sin sombra
  ),
  child: const Text(
    'Cerrar sesión',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600, // Texto semibold
    ),
  ),
),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
      unselectedItemColor:  Color.fromARGB(255, 161, 60, 161),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: 'Modo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        onTap: (index) {
          if (index == 3) return;
          
          switch (index) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/buscar-eventos', 
                (route) => false
              );
              break;
            case 1:
              Navigator.pushNamed(context, '/elegir-modo');
              break;
            case 2:
              Navigator.pushNamed(context, '/notificaciones');
              break;
          }
        },
      ),
    );
  }

  Widget _buildStatCard(String title, Widget valueWidget) {
    return Column(
      children: [
        valueWidget,
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Stream<int> _calcularTotalLikes() async* {
    final user = _auth.currentUser;
    if (user == null) yield 0;

    final query = _firestore
        .collection('eventos')
        .where('creadorId', isEqualTo: user!.uid);

    await for (final snapshot in query.snapshots()) {
      int total = 0;
      for (final doc in snapshot.docs) {
        total += (doc['meGustas'] as int? ?? 0);
      }
      yield total;
    }
  }

  void _mostrarSelectorImagen() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona una foto de perfil:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fotosPerfil.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _actualizarFotoPerfil(_fotosPerfil[index]);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(_fotosPerfil[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _actualizarFotoPerfil(String nuevaUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('usuarios').doc(user.uid).update({
        'fotoUrl': nuevaUrl,
      });

      setState(() {
        _usuario['fotoUrl'] = nuevaUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar foto: ${e.toString()}')),
        );
      }
    }
  }
}