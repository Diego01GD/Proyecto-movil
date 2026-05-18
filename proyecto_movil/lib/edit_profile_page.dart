import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'landing_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final supabase = Supabase.instance.client;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network(
            'https://api.dicebear.com/7.x/identicon/svg?seed=SkillSwap', // Placeholder logo
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, color: Color(0xFF1E56A0)),
          ),
        ),
        title: const Text(
          'SkillSwap',
          style: TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () async {
                await supabase.auth.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LandingPage()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0097B2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Volver al perfil'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1E56A0),
                    textStyle: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 16),
                
                // CARD 1: EDITAR HABILIDADES Y HORARIOS
                _buildMainCard(isMobile),
                
                const SizedBox(height: 24),
                
                // CARD 2: CAMBIAR CONTRASEÑA
                _buildPasswordCard(isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editar Habilidades y Horarios',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Actualiza lo que enseñas, lo que quieres aprender y tu disponibilidad',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkillsSection(isMobile),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                _buildAvailabilitySection(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna Izquierda: Habilidades
                Expanded(flex: 3, child: _buildSkillsSection(isMobile)),
                
                // Divisor Vertical
                const SizedBox(width: 40),
                Container(width: 1, height: 700, color: Colors.grey[200]),
                const SizedBox(width: 40),
                
                // Columna Derecha: Disponibilidad
                Expanded(flex: 2, child: _buildAvailabilitySection()),
              ],
            ),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          
          // Botones de Acción inferior
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  side: const BorderSide(color: Color(0xFF1E56A0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF1E56A0), fontSize: 12)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAAB2BD), // Gris como en la imagen
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Guardar Cambios', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Habilidades que enseñas
        const Text('Habilidades que enseñas', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
        const SizedBox(height: 16),
        _buildDataTable(['Categoría', 'Habilidad', 'Nivel', 'Acción'], [
          ['Diseño', 'Photoshop', 'Avanzado', 'delete'],
        ], isMobile),
        const SizedBox(height: 20),
        
        // Inputs para añadir
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(flex: 2, child: _buildDropdownField('Selecciona una habilidad', '-- Seleccionar --')),
            const SizedBox(width: 12),
            Expanded(flex: 1, child: _buildDropdownField('Nivel', 'Básico')),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Añadir', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFAAB2BD),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Habilidades que busco aprender
        const Text('Lo que busco aprender', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
        const SizedBox(height: 16),
        _buildDataTable(['Categoría', 'Habilidad', 'Acción'], [
          ['Música', 'Canto', 'delete'],
        ], isMobile),
        const SizedBox(height: 20),
        
        // Input para añadir
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _buildDropdownField('Selecciona lo que quieres aprender', '-- Seleccionar --')),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Añadir', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAAB2BD),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Disponibilidad Horaria', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
        const SizedBox(height: 20),
        _buildDropdownField('Turno', 'Lunes'),
        const SizedBox(height: 16),
        _buildDropdownField('Horario', '07:00 - 09:00'),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir Horario', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0056D2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text('Mis horarios:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1E3FF)),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF3F8FF),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Martes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('07:00 - 09:00', style: TextStyle(fontSize: 13)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 16),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('Promedio General', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildTextField('80.5'),
        const SizedBox(height: 20),
        const Text('Carrera', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildTextField('ej: Ingeniería en Sistemas'),
      ],
    );
  }

  Widget _buildPasswordCard(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cambiar Contraseña',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Para cambiar tu contraseña, debes verificar la actual',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  _buildPasswordField('Contraseña Actual *', 'Ingresa tu contraseña actual', _obscureCurrent, (val) => setState(() => _obscureCurrent = !_obscureCurrent)),
                  const SizedBox(height: 16),
                  _buildPasswordField('Nueva Contraseña *', 'Ingresa tu contraseña nueva', _obscureNew, (val) => setState(() => _obscureNew = !_obscureNew)),
                  const SizedBox(height: 16),
                  _buildPasswordField('Confirmar Nueva Contraseña *', 'Confirma tu contraseña nueva', _obscureConfirm, (val) => setState(() => _obscureConfirm = !_obscureConfirm)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056D2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cambiar Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Después de cambiar tu contraseña, serás desconectado y deberás iniciar sesión nuevamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<String> headers, List<List<String>> rows, bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: isMobile ? 400 : 500),
        child: Table(
          columnWidths: const {
            3: FixedColumnWidth(50),
          },
          children: [
            TableRow(
              children: headers.map((h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              )).toList(),
            ),
            ...rows.map((row) => TableRow(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[100]!))),
              children: row.map((cell) {
                if (cell == 'delete') {
                  return IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 16),
                    onPressed: () {},
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(cell, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                );
              }).toList(),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF5FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: [DropdownMenuItem(value: value, child: Text(value, style: const TextStyle(fontSize: 13)))],
              onChanged: (v) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String hint) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, String hint, bool obscure, Function(bool) toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF5FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.grey),
                onPressed: () => toggle(obscure),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
