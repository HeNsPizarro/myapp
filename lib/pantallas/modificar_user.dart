import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ModificarUsuarioScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const ModificarUsuarioScreen({super.key, required this.usuario});

  @override
  State<ModificarUsuarioScreen> createState() => _ModificarUsuarioScreenState();
}

class _ModificarUsuarioScreenState extends State<ModificarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _imagenUrlController;
  bool _isLoading = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Lista de imágenes predefinidas para perfil
  final List<String> _fotosPerfil = [
    'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?w=500',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500',
    'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=500',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500',
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.usuario['nombre']);
    _emailController = TextEditingController(text: widget.usuario['email']);
    _imagenUrlController = TextEditingController(text: widget.usuario['fotoUrl'] ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  Future<void> _mostrarSelectorImagen() async {
    final seleccion = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          height: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecciona una foto de perfil:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[800],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _fotosPerfil.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context, _fotosPerfil[index]);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.deepPurple[50],
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

    if (seleccion != null) {
      setState(() {
        _imagenUrlController.text = seleccion;
      });
    }
  }

  Future<void> _actualizarEmail(String nuevoEmail) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != nuevoEmail) {
        await user.verifyBeforeUpdateEmail(nuevoEmail);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Se ha enviado un enlace de verificación a tu nuevo email'),
            backgroundColor: Colors.green[400],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar email: ${e.toString()}'),
          backgroundColor: Colors.red[400],
        ),
      );
      rethrow;
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (_emailController.text.trim() != user.email) {
        await _actualizarEmail(_emailController.text.trim());
      }

      await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .update({
            'nombre': _nombreController.text.trim(),
            'email': _emailController.text.trim(),
            'fotoUrl': _imagenUrlController.text.isNotEmpty 
                ? _imagenUrlController.text 
                : 'https://via.placeholder.com/150',
          });

      if (mounted) {
        Navigator.pop(context, {
          'nombre': _nombreController.text.trim(),
          'email': _emailController.text.trim(),
          'fotoUrl': _imagenUrlController.text,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text(
          'Editar perfil',
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            color: Colors.deepPurple,
            onPressed: _isLoading ? null : _guardarCambios,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Selector de foto de perfil
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.deepPurple,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.deepPurple[50],
                      backgroundImage: _imagenUrlController.text.isNotEmpty
                          ? CachedNetworkImageProvider(_imagenUrlController.text)
                          : const CachedNetworkImageProvider('https://via.placeholder.com/150'),
                      child: _imagenUrlController.text.isEmpty
                          ? const Icon(Icons.person, size: 50, color: Colors.deepPurple)
                          : null,
                    ),
                  ),
                  FloatingActionButton.small(
                    onPressed: _isLoading ? null : _mostrarSelectorImagen,
                    backgroundColor: Colors.deepPurple,
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Campo para URL personalizada
              TextFormField(
                controller: _imagenUrlController,
                decoration: InputDecoration(
                  labelText: 'URL de la imagen',
                  labelStyle: TextStyle(color: Colors.deepPurple[800]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.deepPurple),
                    onPressed: () {
                      setState(() {
                        _imagenUrlController.clear();
                      });
                    },
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                'O selecciona una de nuestras imágenes',
                style: TextStyle(color: Colors.deepPurple[600], fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              
              // Campo: Nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: TextStyle(color: Colors.deepPurple[800]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Campo: Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.deepPurple[800]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Ingresa un email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              
              // Botón Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarCambios,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    shadowColor: Colors.deepPurple.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'GUARDAR CAMBIOS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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