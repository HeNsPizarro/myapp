import 'package:flutter/material.dart';

class AutenticacionScreen extends StatelessWidget {
  const AutenticacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Color de fondo #F5EBD9

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagen del logo
              Image.asset(
                'assets/imagenes/mendoeventos.png',
                height: 250, // Ajusta según tu diseño
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 80),
              
              // Botón "Iniciar Sesión"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEADDFF),// Ajusta el color
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide( color: Color(0xFF800080)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 16,
                      color:  Color(0xFF800080),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botón "Registrarse"
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/registro'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide( color: Color(0xFF800080)),
                    backgroundColor: const Color(0xFFEADDFF),// Ajusta el color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Registrarse',
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
      ),
    );
  }
}