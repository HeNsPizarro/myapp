import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Mismo fondo que las demás pantallas
      appBar: AppBar(
        title: const Text(
          'MendoEventos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black, // Texto en negro
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, // AppBar transparente
        elevation: 0, // Sin sombra
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Logo/Texto (reemplaza con tu imagen si es necesario)
            Image.asset(
                'assets/imagenes/mendoeventos.png',
                height: 250, // Ajusta según tu diseño
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 60),

            // Botón "Organizador"
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/feed-creador'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEADDFF),// Ajusta el color
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide( color: Color(0xFF800080)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Crear Eventos',
                    style: TextStyle(
                      fontSize: 16,
                      color:  Color(0xFF800080),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 19),
              

            // Botón "Buscar eventos"
            SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/buscar-eventos'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide( color: Color(0xFF800080)),
                    backgroundColor: const Color(0xFFEADDFF),// Ajusta el color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Buscar Eventos',
                    style: TextStyle(
                      fontSize: 16,
                      color:  Color(0xFF800080),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}