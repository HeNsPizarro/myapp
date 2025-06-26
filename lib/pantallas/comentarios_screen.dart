import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComentariosScreen extends StatefulWidget {
  const ComentariosScreen({super.key, required Map<String, dynamic> evento});

  @override
  State<ComentariosScreen> createState() => _ComentariosScreenState();
}

class _ComentariosScreenState extends State<ComentariosScreen> {
  final TextEditingController _comentarioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late String _eventoId;
  late Map<String, dynamic> _eventoData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _eventoId = args['eventoId'];
    _eventoData = args['eventoData'];
  }

  Future<void> _agregarComentario() async {
    if (_formKey.currentState!.validate() && _comentarioController.text.isNotEmpty) {
      try {
        final user = _auth.currentUser;
        if (user == null) return;

        final eventoDoc = await _firestore.collection('eventos').doc(_eventoId).get();
        if (!eventoDoc.exists) {
          throw Exception('El evento no existe');
        }

        final userDoc = await _firestore.collection('usuarios').doc(user.uid).get();
        final userData = userDoc.data() ?? {};
        
        await _firestore.collection('eventos')
            .doc(_eventoId)
            .collection('comentarios')
            .add({
              'texto': _comentarioController.text,
              'fecha': FieldValue.serverTimestamp(),
              'nombreUsuario': user.displayName ?? userData['nombre'] ?? 'Usuario',
              'usuarioId': user.uid,
              'fotoUrl': user.photoURL ?? userData['fotoUrl'] ?? 'https://via.placeholder.com/150',
              'eventoOwnerId': _eventoData['creadorId'],
            });

        await _firestore.runTransaction((transaction) async {
          final doc = await transaction.get(_firestore.collection('eventos').doc(_eventoId));
          if (!doc.exists) throw Exception("Documento no encontrado");
          
          final nuevosComentarios = (doc['comentarios'] ?? 0) + 1;
          transaction.update(doc.reference, {'comentarios': nuevosComentarios});
        });

        _comentarioController.clear();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: Text(
          'Comentarios: ${_eventoData['nombre'] ?? 'Evento'}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('eventos')
                  .doc(_eventoId)
                  .collection('comentarios')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay comentarios aún',
                      style: TextStyle(color: Colors.deepPurple[800]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final comentario = doc.data() as Map<String, dynamic>;
                    return _buildComentarioCard(comentario);
                  },
                );
              },
            ),
          ),
          _buildInputComentario(),
        ],
      ),
    );
  }

  Widget _buildComentarioCard(Map<String, dynamic> comentario) {
    final fecha = (comentario['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.deepPurple, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.deepPurple[50],
                backgroundImage: NetworkImage(
                  comentario['fotoUrl'] ?? 'https://via.placeholder.com/150',
                ),
                child: comentario['fotoUrl'] == null
                    ? const Icon(Icons.person, size: 20, color: Colors.deepPurple)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        comentario['nombreUsuario'] ?? 'Anónimo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yy HH:mm').format(fecha),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEADDFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      comentario['texto'] ?? '',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputComentario() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.deepPurple.withOpacity(0.2)),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _comentarioController,
                decoration: InputDecoration(
                  hintText: 'Escribe un comentario...',
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _agregarComentario(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _agregarComentario,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }
}