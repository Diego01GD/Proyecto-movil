import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? presetEmail;
  final bool requireOtpVerification;

  const ResetPasswordPage({
    super.key,
    this.presetEmail,
    this.requireOtpVerification = true,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isOtpValid = false;
  bool _isSessionReady = false;

  // Real-time validation
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.presetEmail ?? '';
    _isSessionReady = !widget.requireOtpVerification;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateOtp(String value) {
    setState(() {
      _isOtpValid = RegExp(r'^\d{8}$').hasMatch(value.trim());
    });
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (email.isEmpty || !_isOtpValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa correo y un OTP de 8 dígitos válido'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.recovery,
        email: email,
        token: otp,
      );

      if (mounted) {
        setState(() => _isSessionReady = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código verificado. Ahora crea tu nueva contraseña.'),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar OTP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _validatePassword(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      print('**** PASSWORD VALIDATION ****');
      print('**** Min Length (8+): $_hasMinLength (${value.length})');
      print('**** Uppercase: $_hasUppercase');
      print('**** Number: $_hasNumber');
      print('**** Special Char: $_hasSpecialChar');
      print(
        '**** All Valid: ${_hasMinLength && _hasUppercase && _hasNumber && _hasSpecialChar}',
      );
    });
  }

  Future<void> _updatePassword() async {
    if (!_isSessionReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero verifica el OTP de 8 dígitos.')),
      );
      return;
    }

    if (!_hasMinLength || !_hasUppercase || !_hasNumber || !_hasSpecialChar)
      return;

    setState(() => _isLoading = true);
    try {
      final session = Supabase.instance.client.auth.currentSession;
      print('**** RESET PASSWORD: SESSION EXISTS: ${session != null}');
      print('**** RESET PASSWORD: USER EMAIL: ${session?.user.email}');

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada con éxito')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
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
    final isMobile = size.width < 600;
    final allValid =
        _hasMinLength && _hasUppercase && _hasNumber && _hasSpecialChar;

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
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.school,
                    size: 40,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'SkillSwap',
                  style: TextStyle(
                    fontSize: 20,
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: isMobile ? double.infinity : 550,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Restablecer contraseña',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia',
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Ingresa tu nueva contraseña. Recuerda que debe cumplir con todos los requisitos de seguridad.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF555555),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),

                    if (widget.requireOtpVerification && !_isSessionReady) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CORREO *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A5F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'nombre@universidad.edu',
                          filled: true,
                          fillColor: const Color(0xFFEDF4FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CÓDIGO OTP (8 DÍGITOS) *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A5F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        onChanged: _validateOtp,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '12345678',
                          filled: true,
                          fillColor: const Color(0xFFEDF4FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A5F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Verificar código'),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'NUEVA CONTRASEÑA *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A5F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: _validatePassword,
                      decoration: InputDecoration(
                        hintText: 'Ingresa tu nueva contraseña',
                        filled: true,
                        fillColor: const Color(0xFFEDF4FB),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                            color: Color(0xFF1E3A5F),
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Password Requirements Box
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REQUISITOS DE SEGURIDAD:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildRequirement(
                            'Mínimo 8 caracteres',
                            _hasMinLength,
                          ),
                          _buildRequirement(
                            'Una letra mayúscula',
                            _hasUppercase,
                          ),
                          _buildRequirement('Un número', _hasNumber),
                          _buildRequirement(
                            'Un carácter especial (!@#\$%^&*)',
                            _hasSpecialChar,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_isSessionReady || !allValid)
                            ? null
                            : _updatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (allValid && _isSessionReady)
                              ? const Color(0xFF508298)
                              : const Color(0xFFE0E0E0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Actualizar contraseña',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      ),
                      child: const Text(
                        'Volver a inicio de sesión',
                        style: TextStyle(
                          color: Color(0xFF1E3A5F),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isValid
                  ? const Color(0xFF00ACC1).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
            child: Icon(
              isValid ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: isValid ? const Color(0xFF00ACC1) : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isValid ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
