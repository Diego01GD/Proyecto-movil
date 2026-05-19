import 'package:flutter/material.dart';
import 'main.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _careerController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedSemester;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Variables para validación de contraseña en tiempo real
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  void _validatePassword(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  final List<String> _semesters = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10+',
  ];
  final List<String> _interests = [
    'Programación',
    'Idiomas',
    'Diseño',
    'Música',
    'Matemáticas',
    'Comunicación',
    'Deportes',
    'Herramientas digitales',
  ];
  final List<String> _selectedInterests = [];

  Future<void> signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_hasMinLength || !_hasUppercase || !_hasNumber || !_hasSpecialChar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña no cumple con los requisitos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('No se pudo crear el usuario en auth.users');
      }

      await supabase.from('profiles').upsert({
        'id': userId,
        'full_name': _nameController.text.trim(),
        'career': _careerController.text.trim(),
        'student_id': _idController.text.trim(),
        'semester': _selectedSemester,
        'interests': _selectedInterests.isEmpty ? null : _selectedInterests,
        'is_complete': false,
      });

      if (mounted && response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso. Revisa tu correo.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Registrar nueva cuenta',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Georgia',
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                              const SizedBox(height: 30),

                              _buildResponsiveRow(isMobile, [
                                _buildField(
                                  'NOMBRE COMPLETO *',
                                  _nameController,
                                  hint: 'Tu nombre',
                                ),
                                _buildField(
                                  'CARRERA *',
                                  _careerController,
                                  hint: 'Tu carrera',
                                ),
                              ]),

                              _buildResponsiveRow(isMobile, [
                                _buildField(
                                  'MATRÍCULA *',
                                  _idController,
                                  hint: 'Tu matrícula',
                                ),
                                _buildDropdownField('SEMESTRE ACTUAL *'),
                              ]),

                              _buildField(
                                'CORREO INSTITUCIONAL *',
                                _emailController,
                                hint: 'nombre@universidad.edu',
                              ),

                              _buildField(
                                'CONTRASEÑA *',
                                _passwordController,
                                isPassword: true,
                                obscureText: _obscurePassword,
                                onToggle: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),

                              _buildPasswordStrengthIndicator(),

                              _buildField(
                                'CONFIRMAR CONTRASEÑA *',
                                _confirmPasswordController,
                                isPassword: true,
                                obscureText: _obscureConfirmPassword,
                                onToggle: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),

                              const SizedBox(height: 30),
                              const Text(
                                'INTERESES ACADEMICOS O PERSONALES',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7DAB),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Wrap(
                                spacing: 20,
                                runSpacing: 10,
                                children: _interests
                                    .map(
                                      (interest) => SizedBox(
                                        width: isMobile
                                            ? size.width * 0.35
                                            : 180,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Checkbox(
                                              value: _selectedInterests
                                                  .contains(interest),
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val!)
                                                    _selectedInterests.add(
                                                      interest,
                                                    );
                                                  else
                                                    _selectedInterests.remove(
                                                      interest,
                                                    );
                                                });
                                              },
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                interest,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),

                              const SizedBox(height: 40),

                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 300,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : signUp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFF0F4F8,
                                        ).withOpacity(0.8),
                                        foregroundColor: const Color(
                                          0xFF1E3A5F,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Registrar cuenta',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Ya tengo cuenta - ',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  InkWell(
                                    onTap: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginPage(),
                                      ),
                                    ),
                                    child: const Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF2E7DAB),
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children) {
    if (isMobile) return Column(children: children);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map(
            (c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: c,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword ? (obscureText ?? true) : false,
            onChanged:
                label.contains('CONTRASEÑA') && !label.contains('CONFIRMAR')
                ? _validatePassword
                : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFDDE7EE).withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText! ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: onToggle,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFDDE7EE).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSemester,
                hint: const Text(
                  'Selecciona semestre',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                isExpanded: true,
                items: _semesters
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedSemester = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    int strengthCount =
        (_hasMinLength ? 1 : 0) +
        (_hasUppercase ? 1 : 0) +
        (_hasNumber ? 1 : 0) +
        (_hasSpecialChar ? 1 : 0);
    String strengthText = 'DÉBIL';
    Color strengthColor = Colors.red;

    if (strengthCount == 4) {
      strengthText = 'FUERTE';
      strengthColor = Colors.green;
    } else if (strengthCount >= 2) {
      strengthText = 'MEDIO';
      strengthColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fuerza:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 4.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildCriteriaItem('Mínimo 8 caracteres', _hasMinLength),
              _buildCriteriaItem('Una mayúscula', _hasUppercase),
              _buildCriteriaItem('Un número', _hasNumber),
              _buildCriteriaItem('Un carácter especial', _hasSpecialChar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem(String text, bool isValid) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid ? Icons.check : Icons.close,
          size: 14,
          color: isValid ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isValid ? Colors.black87 : Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
