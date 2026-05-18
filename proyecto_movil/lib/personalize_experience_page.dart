import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'main.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

class PersonalizeExperiencePage extends StatefulWidget {
  const PersonalizeExperiencePage({super.key});

  @override
  State<PersonalizeExperiencePage> createState() => _PersonalizeExperiencePageState();
}

class _PersonalizeExperiencePageState extends State<PersonalizeExperiencePage> {
  final _formKey = GlobalKey<FormState>();
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Verificación de seguridad al inicio de la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (supabase.auth.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión requerida. Por favor inicia sesión.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }
  
  // Data lists for dynamic fields
  List<Map<String, String?>> skillsPossessed = [{ 'category': null, 'skill': null, 'level': 'Básico' }];
  List<Map<String, String?>> skillsToLearn = [{ 'category': null, 'skill': null }];
  List<Map<String, String?>> availability = [{ 'shift': null, 'hour': null, 'day': null }];
  
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _gpaController = TextEditingController();

  // Mock data for dropdowns mapping categories to skills
  final Map<String, List<String>> categorySkills = {
    'Programación': ['Flutter', 'Python', 'Java', 'Web Development', 'Data Science'],
    'Idiomas': ['Inglés', 'Francés', 'Alemán', 'Chino Mandarín', 'Italiano'],
    'Diseño': ['UI/UX Design', 'Graphic Design', 'Figma', 'Photoshop', 'Adobe Illustrator'],
    'Música': ['Piano', 'Guitarra', 'Canto', 'Teoría Musical', 'Producción Musical'],
    'Matemáticas': ['Cálculo', 'Álgebra', 'Estadística', 'Trigonometría'],
    'Comunicación': ['Oratoria', 'Redacción', 'Relaciones Públicas', 'Storytelling'],
    'Deportes': ['Fútbol', 'Básquetbol', 'Natación', 'Yoga', 'Entrenamiento Funcional'],
    'Herramientas digitales': ['Excel', 'Word', 'PowerPoint', 'Google Workspace', 'Notion'],
  };

  final List<String> levels = ['Básico', 'Intermedio', 'Avanzado'];
  final List<String> shifts = ['Mañana', 'Tarde', 'Noche'];
  final List<String> hoursString = ['08:00', '10:00', '14:00', '16:00', '18:00', '20:00'];
  final List<String> days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  void _addSkillPossessed() {
    setState(() {
      skillsPossessed.add({ 'category': null, 'skill': null, 'level': 'Básico' });
    });
  }

  void _addSkillToLearn() {
    setState(() {
      skillsToLearn.add({ 'category': null, 'skill': null });
    });
  }

  void _addAvailability() {
    setState(() {
      availability.add({ 'shift': null, 'hour': null, 'day': null });
    });
  }

  void _saveAndContinue() async {
    print('**** BUTTON PRESSED ****');
    if (_formKey.currentState!.validate()) {
      print('**** FORM IS VALID ****');
      
      // Validar que haya al menos un skill para enseñar y uno para aprender
      final hasSkillsToTeach = skillsPossessed.any((skill) => 
        skill['category'] != null && skill['skill'] != null);
      final hasSkillsToLearn = skillsToLearn.any((skill) => 
        skill['category'] != null && skill['skill'] != null);
      
      if (!hasSkillsToTeach || !hasSkillsToLearn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecciona al menos un skill para enseñar y uno para aprender'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      try {
        final userId = supabase.auth.currentUser?.id;
        print('**** USER ID: $userId');
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Error: No se encontró sesión de usuario. Por favor, inicia sesión de nuevo.')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
          return;
        }

        // Marcamos el perfil como completo en Supabase
        print('**** UPDATING SUPABASE ****');
        await supabase.from('profiles').update({
          'is_complete': true,
          'gpa': double.tryParse(_gpaController.text) ?? 0.0,
        }).eq('id', userId);
        print('**** SUPABASE UPDATE SUCCESSFUL ****');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil completado exitosamente')),
          );
          // Navegamos al Dashboard (donde verá a otros usuarios)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardPage()),
            (route) => false,
          );
        }
      } catch (e) {
        print('**** ERROR IN _saveAndContinue: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar datos: $e')),
          );
        }
      }
    } else {
      print('**** FORM IS INVALID ****');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, completa todos los campos requeridos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
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
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Personaliza tu Experiencia',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cuéntanos más sobre ti para encontrar tu match perfecto',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Profile Photo Upload Placeholder
                      GestureDetector(
                        onTap: _pickImage,
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF2E7DAB), width: 2),
                                image: _imageFile != null
                                    ? DecorationImage(
                                        image: kIsWeb
                                            ? NetworkImage(_imageFile!.path)
                                            : FileImage(File(_imageFile!.path)) as ImageProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _imageFile == null
                                  ? const Icon(Icons.camera_alt_outlined, size: 40, color: Color(0xFF2E7DAB))
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _imageFile == null ? 'HAZ CLIC PARA SUBIR TU FOTO' : 'CAMBIAR FOTO',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7DAB)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),

                      _buildSectionTitle('¿Qué habilidades posees?'),
                      const Text('Selecciona lo que puedes enseñar a otros', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ...skillsPossessed.asMap().entries.map((entry) => _buildSkillPossessedRow(entry.key, isMobile)).toList(),
                      
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),

                      _buildSectionTitle('¿Qué quieres aprender?'),
                      const Text('Habilidades que buscas desarrollar', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ...skillsToLearn.asMap().entries.map((entry) => _buildSkillToLearnRow(entry.key, isMobile)).toList(),

                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Disponibilidad Horaria'),
                      const SizedBox(height: 16),
                      ...availability.asMap().entries.map((entry) => _buildAvailabilityRow(entry.key, isMobile)).toList(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _commentController,
                        decoration: _inputDecoration('COMENTARIO (OPCIONAL)', 'Añade un comentario...'),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Información Académica'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _gpaController,
                        decoration: _inputDecoration('PROMEDIO GENERAL', 'Ej: 8.50'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Campo requerido';
                          return null;
                        },
                      ),

                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveAndContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7DAB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Guardar y Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildSkillPossessedRow(int index, bool isMobile) {
    String? selectedCategory = skillsPossessed[index]['category'];
    List<String> availableSkills = selectedCategory != null ? categorySkills[selectedCategory]! : [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 150,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration('CATEGORÍA', 'Selecciona categoría'),
              value: selectedCategory,
              items: categorySkills.keys.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (val) {
                setState(() {
                  skillsPossessed[index]['category'] = val;
                  skillsPossessed[index]['skill'] = null; // Reiniciar habilidad al cambiar categoría
                });
              },
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 150,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration('HABILIDAD', 'Selecciona habilidad'),
              value: skillsPossessed[index]['skill'],
              items: availableSkills.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (val) => setState(() => skillsPossessed[index]['skill'] = val),
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 150,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration('DOMINIO', 'Básico'),
              value: skillsPossessed[index]['level'],
              items: levels.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (val) => setState(() => skillsPossessed[index]['level'] = val),
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          if (index == skillsPossessed.length - 1)
            IconButton(
              onPressed: _addSkillPossessed,
              icon: const Icon(Icons.add_circle, color: Color(0xFF2E7DAB), size: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillToLearnRow(int index, bool isMobile) {
    String? selectedCategory = skillsToLearn[index]['category'];
    List<String> availableSkills = selectedCategory != null ? categorySkills[selectedCategory]! : [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 200,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration('CATEGORÍA', 'Selecciona categoría'),
              value: selectedCategory,
              items: categorySkills.keys.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (val) {
                setState(() {
                  skillsToLearn[index]['category'] = val;
                  skillsToLearn[index]['skill'] = null; // Reiniciar habilidad
                });
              },
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 200,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration('HABILIDAD', 'Selecciona habilidad'),
              value: skillsToLearn[index]['skill'],
              items: availableSkills.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (val) => setState(() => skillsToLearn[index]['skill'] = val),
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          if (index == skillsToLearn.length - 1)
            IconButton(
              onPressed: _addSkillToLearn,
              icon: const Icon(Icons.add_circle, color: Color(0xFF2E7DAB), size: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityRow(int index, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 130,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration('TURNO', 'Selecciona un turno'),
              items: shifts.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => availability[index]['shift'] = val,
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 130,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration('HORA', 'Selecciona hora'),
              items: hoursString.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
              onChanged: (val) => availability[index]['hour'] = val,
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 130,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration('DÍA', 'Selecciona día'),
              items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (val) => availability[index]['day'] = val,
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          if (index == availability.length - 1)
            IconButton(
              onPressed: _addAvailability,
              icon: const Icon(Icons.add_circle, color: Color(0xFF2E7DAB), size: 32),
            ),
        ],
      ),
    );
  }
}
