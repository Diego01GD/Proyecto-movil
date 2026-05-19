import 'package:flutter/material.dart';
import 'main.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

class PersonalizeExperiencePage extends StatefulWidget {
  const PersonalizeExperiencePage({super.key});

  @override
  State<PersonalizeExperiencePage> createState() =>
      _PersonalizeExperiencePageState();
}

class _PersonalizeExperiencePageState extends State<PersonalizeExperiencePage> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _skillCatalog = [];
  final List<Map<String, dynamic>> _timeSlotsCatalog = [];

  @override
  void initState() {
    super.initState();
    // Verificación de seguridad al inicio de la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (supabase.auth.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión requerida. Por favor inicia sesión.'),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    });
    _loadCatalogs();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    try {
      final catalogResponse = await supabase
          .from('skills')
          .select('id, name, category');
      final timeSlotsResponse = await supabase
          .from('time_slots')
          .select('id, range, shift');

      final catalogRows = (catalogResponse as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      final timeSlotRows = (timeSlotsResponse as List)
          .whereType<Map<String, dynamic>>()
          .toList();

      if (!mounted) return;
      setState(() {
        _skillCatalog
          ..clear()
          ..addAll(
            catalogRows.map(
              (row) => {
                'id': row['id']?.toString() ?? '',
                'name': row['name']?.toString() ?? '',
                'category': row['category']?.toString() ?? '',
              },
            ),
          );
        _timeSlotsCatalog
          ..clear()
          ..addAll(
            timeSlotRows.map(
              (row) => {
                'id': row['id']?.toString() ?? '',
                'range': row['range']?.toString() ?? '',
                'shift': row['shift']?.toString() ?? '',
              },
            ),
          );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando catálogos: $e')));
    }
  }

  // Data lists for dynamic fields
  List<Map<String, String?>> skillsPossessed = [
    {'category': null, 'skill': null, 'level': 'Básico'},
  ];
  List<Map<String, String?>> skillsToLearn = [
    {'category': null, 'skill': null},
  ];
  List<Map<String, String?>> availability = [
    {'day': null, 'hour': null},
  ];

  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _gpaController = TextEditingController();

  List<String> get _skillCategories {
    final categories = _skillCatalog
        .map((skill) => skill['category']?.toString() ?? '')
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  List<Map<String, dynamic>> _skillsForCategory(String? category) {
    if (category == null || category.isEmpty) return [];
    return _skillCatalog
        .where((skill) => skill['category'] == category)
        .toList();
  }

  String? _findSkillId(String? category, String? skillName) {
    if (category == null || skillName == null) return null;
    for (final skill in _skillCatalog) {
      if (skill['category'] == category && skill['name'] == skillName) {
        return skill['id']?.toString();
      }
    }
    return null;
  }

  List<String> get _timeSlotRanges {
    return _timeSlotsCatalog
        .map((slot) => slot['range']?.toString() ?? '')
        .where((range) => range.isNotEmpty)
        .toList();
  }

  String? _findTimeSlotId(String? range) {
    if (range == null) return null;
    for (final slot in _timeSlotsCatalog) {
      if (slot['range'] == range) {
        return slot['id']?.toString();
      }
    }
    return null;
  }

  final List<String> levels = ['Básico', 'Intermedio', 'Avanzado'];
  final List<String> days = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

  void _addSkillPossessed() {
    setState(() {
      skillsPossessed.add({'category': null, 'skill': null, 'level': 'Básico'});
    });
  }

  void _addSkillToLearn() {
    setState(() {
      skillsToLearn.add({'category': null, 'skill': null});
    });
  }

  void _addAvailability() {
    setState(() {
      availability.add({'day': null, 'hour': null});
    });
  }

  void _saveAndContinue() async {
    print('**** BUTTON PRESSED ****');
    if (_formKey.currentState!.validate()) {
      print('**** FORM IS VALID ****');

      // Validar que haya al menos un skill para enseñar y uno para aprender
      final hasSkillsToTeach = skillsPossessed.any(
        (skill) => skill['category'] != null && skill['skill'] != null,
      );
      final hasSkillsToLearn = skillsToLearn.any(
        (skill) => skill['category'] != null && skill['skill'] != null,
      );

      if (!hasSkillsToTeach || !hasSkillsToLearn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Por favor, selecciona al menos un skill para enseñar y uno para aprender',
            ),
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
                'Error: No se encontró sesión de usuario. Por favor, inicia sesión de nuevo.',
              ),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
          return;
        }

        final teachRows = <Map<String, dynamic>>[];
        for (final skill in skillsPossessed) {
          final category = skill['category'];
          final name = skill['skill'];
          final skillId = _findSkillId(category, name);
          if (skillId == null) {
            throw Exception(
              'No se encontró la habilidad para enseñar "$name" en la categoría "$category"',
            );
          }
          teachRows.add({
            'profile_id': userId,
            'skill_id': skillId,
            'level': skill['level'] ?? 'Básico',
          });
        }

        final learnRows = <Map<String, dynamic>>[];
        for (final skill in skillsToLearn) {
          final category = skill['category'];
          final name = skill['skill'];
          final skillId = _findSkillId(category, name);
          if (skillId == null) {
            throw Exception(
              'No se encontró la habilidad para aprender "$name" en la categoría "$category"',
            );
          }
          learnRows.add({'profile_id': userId, 'skill_id': skillId});
        }

        final availabilityRows = <Map<String, dynamic>>[];
        for (final slot in availability) {
          final day = slot['day'];
          final range = slot['hour'];
          final slotId = _findTimeSlotId(range);
          if (day == null || day.isEmpty || slotId == null) {
            throw Exception('Selecciona un día y un horario válidos');
          }
          availabilityRows.add({
            'profile_id': userId,
            'day': day,
            'slot_id': slotId,
            'comment': _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
          });
        }

        print('**** UPDATING SUPABASE ****');
        await supabase
            .from('profiles')
            .update({
              'is_complete': true,
              'gpa': double.tryParse(_gpaController.text) ?? 0.0,
            })
            .eq('id', userId);

        await supabase.from('user_skills').insert(teachRows);
        await supabase.from('user_interests').insert(learnRows);
        await supabase.from('user_availability').insert(availabilityRows);
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al guardar datos: $e')));
        }
      }
    } else {
      print('**** FORM IS INVALID ****');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos.'),
        ),
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

                      const Divider(),
                      const SizedBox(height: 16),

                      _buildSectionTitle('¿Qué habilidades posees?'),
                      const Text(
                        'Selecciona lo que puedes enseñar a otros',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ...skillsPossessed
                          .asMap()
                          .entries
                          .map(
                            (entry) =>
                                _buildSkillPossessedRow(entry.key, isMobile),
                          )
                          .toList(),

                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),

                      _buildSectionTitle('¿Qué quieres aprender?'),
                      const Text(
                        'Habilidades que buscas desarrollar',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ...skillsToLearn
                          .asMap()
                          .entries
                          .map(
                            (entry) =>
                                _buildSkillToLearnRow(entry.key, isMobile),
                          )
                          .toList(),

                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Disponibilidad Horaria'),
                      const SizedBox(height: 16),
                      ...availability
                          .asMap()
                          .entries
                          .map(
                            (entry) =>
                                _buildAvailabilityRow(entry.key, isMobile),
                          )
                          .toList(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _commentController,
                        decoration: _inputDecoration(
                          'COMENTARIO (OPCIONAL)',
                          'Añade un comentario...',
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Información Académica'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _gpaController,
                        decoration: _inputDecoration(
                          'PROMEDIO GENERAL',
                          'Ej: 8.50',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Campo requerido';
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Guardar y Continuar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A5F),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E3A5F),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildSkillPossessedRow(int index, bool isMobile) {
    String? selectedCategory = skillsPossessed[index]['category'];
    final availableSkills = _skillsForCategory(selectedCategory);

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
              items: _skillCategories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  skillsPossessed[index]['category'] = val;
                  skillsPossessed[index]['skill'] =
                      null; // Reiniciar habilidad al cambiar categoría
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
              items: availableSkills
                  .map(
                    (s) => DropdownMenuItem(
                      value: s['name']?.toString(),
                      child: Text(
                        s['name']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => skillsPossessed[index]['skill'] = val),
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 150,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration('DOMINIO', 'Básico'),
              value: skillsPossessed[index]['level'],
              items: levels
                  .map(
                    (l) => DropdownMenuItem(
                      value: l,
                      child: Text(l, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => skillsPossessed[index]['level'] = val),
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          if (index == skillsPossessed.length - 1)
            IconButton(
              onPressed: _addSkillPossessed,
              icon: const Icon(
                Icons.add_circle,
                color: Color(0xFF2E7DAB),
                size: 32,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillToLearnRow(int index, bool isMobile) {
    String? selectedCategory = skillsToLearn[index]['category'];
    final availableSkills = _skillsForCategory(selectedCategory);

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
              items: _skillCategories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
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
              items: availableSkills
                  .map(
                    (s) => DropdownMenuItem(
                      value: s['name']?.toString(),
                      child: Text(
                        s['name']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => skillsToLearn[index]['skill'] = val),
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          if (index == skillsToLearn.length - 1)
            IconButton(
              onPressed: _addSkillToLearn,
              icon: const Icon(
                Icons.add_circle,
                color: Color(0xFF2E7DAB),
                size: 32,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityRow(int index, bool isMobile) {
    final selectedDay = availability[index]['day'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 180,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration('DÍA', 'Selecciona día'),
              value: selectedDay,
              items: days
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => availability[index]['day'] = val),
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 180,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration('HORARIO', 'Selecciona horario'),
              items: _timeSlotRanges
                  .map(
                    (range) =>
                        DropdownMenuItem(value: range, child: Text(range)),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => availability[index]['hour'] = val),
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          if (index == availability.length - 1)
            IconButton(
              onPressed: _addAvailability,
              icon: const Icon(
                Icons.add_circle,
                color: Color(0xFF2E7DAB),
                size: 32,
              ),
            ),
        ],
      ),
    );
  }
}
