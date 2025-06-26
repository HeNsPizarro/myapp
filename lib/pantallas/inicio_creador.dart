import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedCreatorScreen extends StatefulWidget {
  const FeedCreatorScreen({super.key});

  @override
  State<FeedCreatorScreen> createState() => _FeedCreatorScreenState();
}

class _FeedCreatorScreenState extends State<FeedCreatorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text(
          'MendoEventos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              TimeOfDay.now().format(context),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('eventos')
            .where('creadorId', isEqualTo: _currentUser?.uid)
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar eventos'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.docs.isEmpty ?? true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No has creado eventos aún',
                    style: TextStyle(fontSize: 16),),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/crear-evento'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      '+ Crear Evento',
                      
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final evento = snapshot.data!.docs[index];
              final data = evento.data() as Map<String, dynamic>;
              final fecha = data['fecha'] is Timestamp 
                  ? (data['fecha'] as Timestamp).toDate() 
                  : DateTime.now();
              
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    '/detalles-evento',
                    arguments: {
                      'id': evento.id,
                      'nombre': data['nombre'],
                      'descripcion': data['descripcion'],
                      'fecha': fecha,
                      'lugar': data['lugar'],
                      'imagenUrl': data['imagenUrl'],
                      'meGustas': data['meGustas'],
                      'comentarios': data['comentarios'],
                    },
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFEADDFF),
                    border: Border.all(
                    color: Colors.deepPurple, // Elegí el color del borde
                    width: 1,),     // Grosor del borde
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                        child: Image.network(
                          data['imagenUrl'] ?? 'https://via.placeholder.com/400x200',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 150,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['nombre'] ?? 'Nombre de Evento',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.favorite, color: Colors.red, size: 20),
                                    const SizedBox(width: 4),
                                    Text('${data['meGustas'] ?? 0}'),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.comment, color: Colors.blue, size: 20),
                                    const SizedBox(width: 4),
                                    Text('${data['comentarios'] ?? 0}'),
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
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/crear-evento'),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }
}