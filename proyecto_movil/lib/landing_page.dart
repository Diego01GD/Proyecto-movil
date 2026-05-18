import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 8, // Reduce el espacio lateral
        title: Row(
          mainAxisSize: MainAxisSize.min, // Hace que la fila ocupe el mínimo espacio
          children: [
            const Icon(Icons.school, color: Color(0xFF2E7DAB), size: 28),
            if (!isMobile) ...[
              const SizedBox(width: 8),
              const Flexible( // Evita el overflow si el texto es largo
                child: Text(
                  'SkillSwap',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF1E3A5F),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Login', // Texto más corto para móviles
              style: TextStyle(color: const Color(0xFF1E3A5F), fontSize: isMobile ? 12 : 14)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8, vertical: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7DAB),
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isMobile ? 'Unirse' : 'Registrarse', style: TextStyle(fontSize: isMobile ? 12 : 14)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10), // Espacio mínimo arriba
            // --- Hero Section ---
            Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 1000), // Evita que se vea gigante en PC
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 10),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: isMobile ? 40 : 80),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Intercambia conocimientos,\npotencia tu carrera',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 28 : 46,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia', // Fuente con serifa para imitar la imagen
                        color: const Color(0xFF222222),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'La plataforma exclusiva para estudiantes donde enseñas lo que amas y aprendes\nlo que necesitas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 19,
                        fontFamily: 'Georgia',
                        color: const Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: isMobile ? double.infinity : null,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7DAB),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Unete con tu correo universitario', 
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16, 
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          )
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Menos espacio entre secciones

            // --- ¿Cómo funciona? ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                '¿Cómo funciona SkillSwap?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A5F)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: const [
                  _StepWidget(number: '1', title: 'Crea tu Perfil', sub: 'Registrate con tu correo institucional y define tus intereses'),
                  _StepWidget(number: '2', title: 'Publica y busca', sub: 'Di que habilidades ofrece(s)\nQue quieres aprender'),
                  _StepWidget(number: '3', title: 'Haz Match', sub: 'El sistema encontrara a alguien con disponibilidad horaria compatible'),
                ],
              ),
            ),

            // --- Categorías ---
            Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 20),
              child: Text(
                'Categorías destacadas',
                style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A5F)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth < 450 ? 1 : (constraints.maxWidth < 900 ? 2 : 4);
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: constraints.maxWidth < 450 ? 2.5 : 1.0,
                    children: const [
                      _CategoryCard(icon: Icons.computer, label: 'Programación', desc: 'Aprende los lenguajes que mueven el mundo digital'),
                      _CategoryCard(icon: Icons.language, label: 'Idiomas', desc: 'Conecta con otras culturas y expande tus horizontes'),
                      _CategoryCard(icon: Icons.music_note, label: 'Música', desc: 'Descubre tu talento y expresa tu pasión musical'),
                      _CategoryCard(icon: Icons.calculate, label: 'Matemáticas', desc: 'Resuelve problemas complejos con lógica y precisión'),
                    ],
                  );
                },
              ),
            ),

            // --- Footer ---
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Text('Comunidad 100% segura y verificada.', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('Solo para la comunidad universitaria. Acceso valido por matricula', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 20),
                  const Text('© 2024 SKILLSWAP. TODOS LOS DERECHOS RESERVADOS.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepWidget extends StatelessWidget {
  final String number, title, sub;
  const _StepWidget({required this.number, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Text(number, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF2E7DAB))),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  const _CategoryCard({required this.icon, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE3F2FD),
            child: Icon(icon, color: const Color(0xFF2E7DAB)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
