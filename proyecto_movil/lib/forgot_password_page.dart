import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa tu correo institucional')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        // Navegar a la pantalla de éxito (Primera imagen solicitada)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessMailPage(email: email),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0), // Fondo crema claro
      body: Stack(
        children: [
          Positioned(
            top: 40,
            left: 40,
            child: Row(
              children: [
                Image.network(
                  'https://rfsfghshshshshs.supabase.co/storage/v1/object/public/imagenes/logo%20SkillSwap.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 40, color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(width: 15),
                const Text(
                  'SkillSwap',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Georgia',
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: isMobile ? double.infinity : 450,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '¿Olvidaste tu contraseña?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Georgia',
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Introduce tu correo institucional para recibir un enlace de recuperación.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF555555),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 45),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            'Correo Universitario',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'nombre@merida.tecnm.mx',
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1E3A5F)),
                            filled: true,
                            fillColor: const Color(0xFFEDF4FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                          ),
                        ),
                        const SizedBox(height: 35),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF508298),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Enviar enlace',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF1E3A5F)),
                          label: const Text(
                            'Volver al inicio de sesión',
                            style: TextStyle(
                              color: Color(0xFF1E3A5F),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de Éxito (Primera imagen solicitada)
class SuccessMailPage extends StatelessWidget {
  final String email;
  const SuccessMailPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: Stack(
        children: [
          Positioned(
            top: 40,
            left: 40,
            child: Row(
              children: [
                Image.network(
                  'https://rfsfghshshshshs.supabase.co/storage/v1/object/public/imagenes/logo%20SkillSwap.png',
                  height: 50,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 30, color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'SkillSwap',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Georgia', color: Color(0xFF1E3A5F)),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: isMobile ? double.infinity : 500,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(50),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00ACC1).withOpacity(0.1),
                    ),
                    child: const Icon(Icons.check_circle_outline, size: 60, color: Color(0xFF00ACC1)),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Revisa tu correo',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Georgia', color: Color(0xFF1E3A5F)),
                  ),
                  const SizedBox(height: 15),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, color: Color(0xFF555555), height: 1.5),
                      children: [
                        const TextSpan(text: 'Hemos enviado las instrucciones para restablecer tu contraseña a '),
                        TextSpan(text: email, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A4D5D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Volver al inicio de sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
