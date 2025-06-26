import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetallesEventoScreen extends StatefulWidget {
  final Map<String, dynamic> evento;
  const DetallesEventoScreen({super.key, required this.evento});

  @override
  State<DetallesEventoScreen> createState() => _DetallesEventoScreenState();
}

class _DetallesEventoScreenState extends State<DetallesEventoScreen> {
  late DateTime _fechaEvento;
  late bool _dioLike;
  int _meGustasCount = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fechaEvento = _parseFecha(widget.evento['fecha']);
    _dioLike = widget.evento['likesUsers']?.contains(_auth.currentUser?.uid) ?? false;
    _meGustasCount = widget.evento['meGustas'] ?? 0;
  }

  DateTime _parseFecha(dynamic fecha) {
    if (fecha is Timestamp) {
      return fecha.toDate();
    }
    return DateTime.now();
  }

  Future<void> _compartirEvento() async {
    try {
      final url = 'https://mendoeventos.com/eventos/${widget.evento['id']}';
      await Share.share(
        '¡Te invito a "${widget.evento['nombre']}"!\n'
        'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaEvento)}\n'
        'Ubicación: ${widget.evento['ubicacion'] ?? 'Por confirmar'}\n'
        'Descripción: ${widget.evento['descripcion']?.substring(0, 50)}...\n'
        'Más info: $url',
        subject: 'Evento: ${widget.evento['nombre']}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al compartir'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final nuevoEstado = !_dioLike;
      final nuevoContador = nuevoEstado ? _meGustasCount + 1 : _meGustasCount - 1;

      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('eventos').doc(widget.evento['id']);
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) throw Exception("Documento no encontrado");
        
        if (nuevoEstado) {
          transaction.update(docRef, {
            'meGustas': nuevoContador,
            'likesUsers': FieldValue.arrayUnion([user.uid]),
          });
        } else {
          transaction.update(docRef, {
            'meGustas': nuevoContador,
            'likesUsers': FieldValue.arrayRemove([user.uid]),
          });
        }
      });

      setState(() {
        _dioLike = nuevoEstado;
        _meGustasCount = nuevoContador;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text(
          'Detalles del Evento',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.deepPurple),
            onPressed: _compartirEvento,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del evento
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(
                    widget.evento['imagenUrl'] ?? 'https://via.placeholder.com/400',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Nombre y fecha
            Text(
              widget.evento['nombre'] ?? 'Evento sin nombre',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE dd MMMM y - hh:mm a').format(_fechaEvento),
                  style: TextStyle(color: Colors.deepPurple[800]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ubicación
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  widget.evento['ubicacion'] ?? 'Ubicación no especificada',
                  style: TextStyle(color: Colors.deepPurple[800]),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Descripción
            const Text(
              'Descripción:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEADDFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              ),
              child: Text(
                widget.evento['descripcion'] ?? 'No hay descripción disponible',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Info adicional
            if (widget.evento['precio'] != null && widget.evento['precio'] > 0)
              _buildInfoRow('Precio:',
                  '\$${widget.evento['precio'].toStringAsFixed(2)}'),

            if (widget.evento['capacidad'] != null)
              _buildInfoRow('Capacidad:',
                  '${widget.evento['capacidad']} personas'),

            // Tags
            if (widget.evento['tags'] != null && widget.evento['tags'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Etiquetas:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (widget.evento['tags'] as List<dynamic>)
                        .map((tag) => Chip(
                              label: Text(
                                tag.toString(),
                                style: TextStyle(color: Colors.deepPurple[800]),
                              ),
                              backgroundColor: const Color(0xFFEADDFF),
                              side: BorderSide(color: Colors.deepPurple.withOpacity(0.3)),
                            ))
                        .toList(),
                  ),
                ],
              ),

            // Botones de interacción
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: _dioLike ? Colors.red : Colors.deepPurple,
                          size: 30,
                        ),
                        onPressed: _toggleLike,
                      ),
                      Text(
                        '$_meGustasCount me gusta',
                        style: TextStyle(color: Colors.deepPurple[800]),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.comment, size: 30, color: Colors.deepPurple),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/comentarios',
                            arguments: {
                              'eventoId': widget.evento['id'],
                              'eventoData': widget.evento,
                            },
                          );
                        },
                      ),
                      Text(
                        '${widget.evento['comentarios'] ?? 0} comentarios',
                        style: TextStyle(color: Colors.deepPurple[800]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
              Navigator.pushNamed(context, '/');
              break;
            case 2:
              Navigator.pushNamed(context, '/notificaciones');
              break;
            case 3:
              Navigator.pushNamed(context, '/perfil');
              break;
          }
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.deepPurple[800],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.deepPurple[800],
            ),
          ),
        ],
      ),
    );
  }
}