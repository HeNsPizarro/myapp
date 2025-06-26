import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class InicioBuscadorScreen extends StatefulWidget {
  const InicioBuscadorScreen({super.key});

  @override
  State<InicioBuscadorScreen> createState() => _InicioBuscadorScreenState();
}

class _InicioBuscadorScreenState extends State<InicioBuscadorScreen> {
  DateTime? _fechaSeleccionada;
  String _tagSeleccionado = 'Todos';
  final TextEditingController _busquedaController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _tags = [
    'Todos',
    'Música',
    'Deportes',
    'Comida',
    'Familiar',
    'Chill',
    'Exposición',
    'Festival'
  ];

  Stream<QuerySnapshot> _getEventos() {
    try {
      Query query = _firestore.collection('eventos');

      if (_busquedaController.text.isNotEmpty) {
        final searchTerm = _busquedaController.text.toLowerCase();
        query = query
            .where('nombreLower', isGreaterThanOrEqualTo: searchTerm)
            .where('nombreLower', isLessThan: '$searchTerm\uf8ff')
            .orderBy('nombreLower');
      } else {
        query = query.orderBy('fecha', descending: true);
      }

      if (_tagSeleccionado != 'Todos') {
        query = query.where('tags', arrayContains: _tagSeleccionado);
      }

      if (_fechaSeleccionada != null) {
        final startDate = DateTime(_fechaSeleccionada!.year, _fechaSeleccionada!.month, _fechaSeleccionada!.day);
        final endDate = DateTime(_fechaSeleccionada!.year, _fechaSeleccionada!.month, _fechaSeleccionada!.day + 1);
        query = query
            .where('fecha', isGreaterThanOrEqualTo: startDate)
            .where('fecha', isLessThan: endDate);
      }

      return query.snapshots();
    } catch (e) {
      debugPrint('Error en _getEventos: $e');
      return Stream.error('Error al cargar eventos. Por favor, intenta nuevamente.');
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  void _navegarAPerfil() {
    final user = _auth.currentUser;
    if (user != null) {
      Navigator.pushNamed(context, '/perfil');
    } else {
      Navigator.pushNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text(
          'Busca tu evento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Selector de fecha
                OutlinedButton(
                  onPressed: () {
                    if (_fechaSeleccionada != null) {
                      setState(() {
                        _fechaSeleccionada = null;
                      });
                    } else {
                      _seleccionarFecha();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _fechaSeleccionada == null
                            ? 'Seleccionar fecha'
                            : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}',
                        style: const TextStyle(color: Colors.deepPurple),
                      ),
                      if (_fechaSeleccionada != null) 
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.deepPurple),
                          onPressed: () {
                            setState(() {
                              _fechaSeleccionada = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Selector de tags
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tags.map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(
                            tag,
                            style: TextStyle(
                              color: _tagSeleccionado == tag 
                                  ? Colors.white 
                                  : Colors.deepPurple,
                            ),
                          ),
                          selected: _tagSeleccionado == tag,
                          onSelected: (selected) {
                            setState(() {
                              _tagSeleccionado = tag;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.deepPurple,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: _tagSeleccionado == tag
                                  ? Colors.deepPurple
                                  : Colors.deepPurple.withOpacity(0.5),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Barra de búsqueda
                TextField(
                  controller: _busquedaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre...',
                    prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                    suffixIcon: _busquedaController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.deepPurple),
                            onPressed: () {
                              _busquedaController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          
          // Lista de eventos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getEventos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Error al cargar eventos'),
                        Text(
                          snapshot.error.toString(), 
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron eventos',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final evento = snapshot.data!.docs[index];
                    final data = evento.data() as Map<String, dynamic>;
                    
                    return EventoItem(
                      eventoId: evento.id,
                      nombre: data['nombre'] ?? 'Evento sin nombre',
                      meGustas: data['meGustas'] ?? 0,
                      comentarios: data['comentarios'] ?? 0,
                      imagenUrl: data['imagenUrl'],
                      fecha: _formatFecha(data['fecha']),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/detalles-evento',
                          arguments: {...data, 'id': evento.id},
                        );
                      },
                      dioLike: data['likesUsers']?.contains(_auth.currentUser?.uid) ?? false,
                      creadorId: data['creadorId'],
                      eventoData: data,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color.fromARGB(255, 161, 60, 161),
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
              Navigator.pushNamed(context, '/buscar-eventos');
              break;
            case 1:
              Navigator.pushNamed(context, '/elegir-modo');
              break;
            case 2:
              Navigator.pushNamed(context, '/notificaciones');
              break;
            case 3:
              _navegarAPerfil();
              break;
          }
        },
      ),
    );
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return 'Fecha no disponible';
    try {
      if (fecha is Timestamp) {
        return DateFormat('dd/MM/yyyy HH:mm').format(fecha.toDate());
      }
      return fecha.toString();
    } catch (e) {
      return 'Fecha inválida';
    }
  }
}

class EventoItem extends StatefulWidget {
  final String eventoId;
  final String nombre;
  final int meGustas;
  final int comentarios;
  final String? imagenUrl;
  final String fecha;
  final VoidCallback onTap;
  final bool dioLike;
  final String creadorId;
  final Map<String, dynamic> eventoData;

  const EventoItem({
    super.key,
    required this.eventoId,
    required this.nombre,
    required this.meGustas,
    required this.comentarios,
    this.imagenUrl,
    required this.fecha,
    required this.onTap,
    this.dioLike = false,
    required this.creadorId,
    required this.eventoData,
  });

  @override
  State<EventoItem> createState() => _EventoItemState();
}

class _EventoItemState extends State<EventoItem> {
  late bool _dioLike;
  late int _likesCount;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _dioLike = widget.dioLike;
    _likesCount = widget.meGustas;
  }

  Future<void> _toggleLike() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final eventoRef = _firestore.collection('eventos').doc(widget.eventoId);

    if (_dioLike) {
      await eventoRef.update({
        'meGustas': FieldValue.increment(-1),
        'likesUsers': FieldValue.arrayRemove([user.uid]),
      });
      setState(() {
        _dioLike = false;
        _likesCount--;
      });
    } else {
      await eventoRef.update({
        'meGustas': FieldValue.increment(1),
        'likesUsers': FieldValue.arrayUnion([user.uid]),
      });
      setState(() {
        _dioLike = true;
        _likesCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEADDFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.deepPurple,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Imagen del evento
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: widget.imagenUrl ?? 'https://via.placeholder.com/400',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 50, color: Colors.deepPurple),
                      Text('Imagen no disponible', style: TextStyle(color: Colors.deepPurple)),
                    ],
                  ),
                ),
              ),
            ),
            
            // Detalles del evento
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y fecha
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        widget.fecha,
                        style: TextStyle(
                          color: Colors.deepPurple[800],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Likes y comentarios
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Botón de like
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _dioLike ? Icons.favorite : Icons.favorite_border,
                              color: _dioLike ? const Color.fromARGB(255, 98, 18, 105) : Colors.deepPurple,
                            ),
                            onPressed: _toggleLike,
                          ),
                          Text('$_likesCount', style: const TextStyle(color: Colors.black)),
                        ],
                      ),
                      
                      // Botón de comentarios
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.comment, color: Colors.deepPurple),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/comentarios',
                                arguments: {
                                  'eventoId': widget.eventoId,
                                  'eventoData': widget.eventoData,
                                },
                              );
                            },
                          ),
                          Text('${widget.comentarios}', style: const TextStyle(color: Colors.black)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}