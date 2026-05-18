import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';
import 'personalize_experience_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa correo y contraseña'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('**** ATTEMPTING SIGN IN WITH: $email ****');
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        debugPrint('**** SIGN IN SUCCESSFUL: ${response.user!.id} ****');
        // Agregamos una navegación de respaldo por si AuthGate tarda en reaccionar
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthGate()),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      debugPrint('**** AUTH ERROR: ${e.message} ****');
      if (mounted) {
        String message = 'Error de autenticación';
        if (e.message.contains('Invalid login credentials')) {
          message = 'Credenciales inválidas. Verifica tu correo y contraseña.';
        } else if (e.message.contains('Email not confirmed')) {
          message = 'Tu correo no ha sido confirmado aún.';
        } else {
          message = e.message;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Unexpected error during signIn: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2), // Fondo crema
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 1000),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  padding: EdgeInsets.all(isMobile ? 24 : 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Logo y Botón Registrarse
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school, color: Color(0xFF2E7DAB), size: 32),
                              const SizedBox(width: 8),
                              const Text(
                                'SkillSwap',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignUpPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A7C92),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Registrarse'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Título Centrado
                      Center(
                        child: Text(
                          'Iniciar Sesión en SkillSwap',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 26 : 38,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Georgia',
                            color: const Color(0xFF1E3A5F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Cuerpo: Formulario e Imagen lateral
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Formulario
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Correo Universitario',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  onSubmitted: (_) => signIn(),
                                  decoration: InputDecoration(
                                    hintText: 'nombre@universidad.edu',
                                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                                    filled: true,
                                    fillColor: const Color(0xFFF0F4F8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text('Contraseña',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  onSubmitted: (_) => signIn(),
                                  decoration: InputDecoration(
                                    hintText: 'Contraseña',
                                    filled: true,
                                    fillColor: const Color(0xFFF0F4F8),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                    );
                                  },
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: Color(0xFF1E3A5F),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : signIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4A7C92),
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Text('Entrar',
                                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('← Volver a la página principal',
                                        style: TextStyle(color: Color(0xFF1E3A5F))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Imagen (Solo en Desktop)
                          if (!isMobile) ...[
                            const SizedBox(width: 40),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  // Simulación de la ilustración de la imagen
                                  const Icon(Icons.people_alt, size: 250, color: Color(0xFFCFD8DC)),
                                  const SizedBox(height: 10),
                                  Container(height: 2, width: 200, color: Colors.grey.shade300),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: const Color(0xFF104655), // Color oscuro de la imagen
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 30,
              children: [
                _FooterLink(label: 'Sección de ayuda'),
                _FooterLink(label: 'Reporte de usuarios'),
                _FooterLink(label: 'Reglas de la comunidad'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        decoration: TextDecoration.underline,
      ),
    );
  }
}

