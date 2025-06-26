import 'package:flutter/material.dart';

class NotificacionesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _notificaciones = [
    {
      'titulo': 'Nuevo like',
      'mensaje': 'A 5 personas les gustó tu evento "Fiesta de Fin de Año"',
      'hora': 'Hace 2 horas',
      'leida': false,
    },
    {
      'titulo': 'Comentario nuevo',
      'mensaje': 'Carlos comentó: "¡Qué buen evento!"',
      'hora': 'Hace 1 día',
      'leida': true,
    },
  ];

  NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _notificaciones.length,
        itemBuilder: (context, index) {
          final notif = _notificaciones[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: notif['leida'] ? Colors.white : Colors.blue.shade50,
            child: ListTile(
              title: Text(notif['titulo'], style: TextStyle(
                fontWeight: notif['leida'] ? FontWeight.normal : FontWeight.bold,
              )),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif['mensaje']),
                  Text(notif['hora'], style: const TextStyle(fontSize: 12)),
                ],
              ),
              trailing: notif['leida'] 
                  ? null 
                  : const Icon(Icons.circle, color: Colors.blue, size: 12),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.compare_arrows), label: 'Modo'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notificaciones'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        onTap: (index) {
          if (index == 2) return; // Ya estamos en notificaciones
          switch (index) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              break;
            case 1:
              Navigator.pushNamed(context, '/elegir-modo');
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