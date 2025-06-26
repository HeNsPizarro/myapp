import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CrearEventoScreen extends StatefulWidget {
  const CrearEventoScreen({super.key});

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _imagenUrlController = TextEditingController();
  
  String _tipoEvento = 'Música';
  DateTime? _fechaSeleccionada;
  
  final List<String> _tiposEvento = [
    'Música',
    'Deportes',
    'Comida',
    'Familiar',
    'Chill',
    'Exposición',
    'Festival'
  ];

  // Lista de imágenes predefinidas para eventos
  final List<String> _imagenesEventos = [
    'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=500',
    'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500',
    'https://images.unsplash.com/photo-1511578314322-379afb476865?w=500',
    'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=500',
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=500',
    'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?w=500',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _fechaController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _precioController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null) {
        final DateTime fechaCompleta = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        
        setState(() {
          _fechaSeleccionada = fechaCompleta;
          _fechaController.text = DateFormat('dd/MM/yyyy HH:mm').format(fechaCompleta);
        });
      }
    }
  }

  Future<void> _subirEvento() async {
    if (_formKey.currentState!.validate() && _fechaSeleccionada != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Debes iniciar sesión para crear eventos')),
            );
          }
          return;
        }

        // Crear el objeto evento
        final nuevoEvento = {
          'nombre': _nombreController.text,
          'nombreLower': _nombreController.text.toLowerCase(),
          'descripcion': _descripcionController.text,
          'fecha': Timestamp.fromDate(_fechaSeleccionada!),
          'ubicacion': _ubicacionController.text,
          'imagenUrl': _imagenUrlController.text.isNotEmpty 
              ? _imagenUrlController.text 
              : 'https://via.placeholder.com/400',
          'meGustas': 0,
          'comentarios': 0,
          'precio': _precioController.text.isNotEmpty 
              ? double.parse(_precioController.text) 
              : 0,
          'tags': [_tipoEvento],
          'likesUsers': [],
          'creadorId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Subir a Firestore
        await FirebaseFirestore.instance.collection('eventos').add(nuevoEvento);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evento creado exitosamente')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear evento: ${e.toString()}')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor completa todos los campos')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text('Creación de evento'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo: Nombre del evento
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del evento',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo: Fecha del evento
              TextFormField(
                controller: _fechaController,
                decoration: InputDecoration(
                  labelText: 'Fecha del evento',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _seleccionarFecha,
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona una fecha';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo: Descripción del evento
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del evento',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo: Precio
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio (opcional)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Selector de imagen
              const Text(
                'Selecciona una imagen para el evento:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Galería de imágenes predefinidas
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagenesEventos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _imagenUrlController.text = _imagenesEventos[index];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _imagenUrlController.text == _imagenesEventos[index]
                                ? Colors.deepPurple
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Image.network(
                          _imagenesEventos[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              
              // Campo para URL personalizada
              TextFormField(
                controller: _imagenUrlController,
                decoration: const InputDecoration(
                  labelText: 'O ingresa una URL de imagen',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),

              // Vista previa de la imagen seleccionada
              if (_imagenUrlController.text.isNotEmpty)
                Container(
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(_imagenUrlController.text),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Campo: Ubicación
              TextFormField(
                controller: _ubicacionController,
                decoration: const InputDecoration(
                  labelText: 'Agregar ubicación',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Agrega una ubicación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Selector: Tipo de evento
// Selector: Tipo de evento
const Text(
  'Tipo de evento:',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),
Wrap(
  spacing: 8, // Espacio HORIZONTAL entre tags (se mantiene igual)
  runSpacing: 12, // Espacio VERTICAL entre líneas de tags (nuevo)
  children: _tiposEvento.map((tipo) {
    return ChoiceChip(
      label: Text(
        tipo,
        style: TextStyle(
          color: _tipoEvento == tipo ? Colors.white : Colors.deepPurple,
        ),
      ),
      selected: _tipoEvento == tipo,
      onSelected: (selected) {
        setState(() {
          _tipoEvento = tipo;
        });
      },
      backgroundColor: Colors.deepPurple[50],
      selectedColor: const Color.fromARGB(255, 143, 111, 199),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _tipoEvento == tipo 
              ? Colors.deepPurple 
              : Colors.deepPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      elevation: 2,
      pressElevation: 5,
    );
  }).toList(),
),
const SizedBox(height: 32),
              
              // Botón: Publicar evento
             ElevatedButton(
  onPressed: _subirEvento,
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFEADDFF), // Color de fondo
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(
        color: Colors.deepPurple, // Color del borde
        width: 1,                 // Grosor del borde
      ),
    ),
  ),
                child: const Text(
                  'PUBLICAR EVENTO',
                  style: TextStyle(fontSize: 18,color: Colors.deepPurple)
                  
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 0,
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
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/feed-creador');
            break;
          case 1:
            Navigator.pushNamed(context, '/elegir-modo');
            break;
          case 2:
            Navigator.pushNamed(context, '/notificaciones');
            break;
          case 3:
            Navigator.pushNamed(context, '/perfil');
            break;
        }
      },
    );
  }
}