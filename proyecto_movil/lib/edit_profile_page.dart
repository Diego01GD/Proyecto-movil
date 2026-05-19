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
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  List<Map<String, dynamic>> _mySkills = [];
  String? _currentUserId;
  List<Map<String, dynamic>> _availableSkills = [];
  String? _selectedSkillId;
  String _selectedLevelForAdd = 'Básico';
  final List<Map<String, String>> _pendingAdds = [];
  final Set<String> _pendingDeletes = {};
  // Interests
  List<Map<String, dynamic>> _myInterests = [];
  String? _selectedInterestSkillId;
  final List<Map<String, String>> _pendingInterestAdds = [];
  final Set<String> _pendingInterestDeletes = {};
  List<Map<String, dynamic>> _myAvailability = [];
  List<Map<String, dynamic>> _availableTimeSlots = [];
  final List<String> _weekDays = const [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];
  String? _selectedAvailabilityDay;
  String? _selectedAvailabilitySlotId;
  final List<Map<String, String>> _pendingAvailabilityAdds = [];
  final Set<String> _pendingAvailabilityDeletes = {};

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _initProfile() async {
    _currentUserId = supabase.auth.currentUser?.id;
    await Future.wait([
      _loadMySkills(),
      _loadAvailableSkills(),
      _loadMyInterests(),
      _loadAvailableTimeSlots(),
      _loadMyAvailability(),
    ]);
  }

  bool _hasPendingChanges() {
    return _pendingAdds.isNotEmpty ||
        _pendingDeletes.isNotEmpty ||
        _pendingInterestAdds.isNotEmpty ||
        _pendingInterestDeletes.isNotEmpty ||
        _pendingAvailabilityAdds.isNotEmpty ||
        _pendingAvailabilityDeletes.isNotEmpty;
  }

  Map<String, dynamic>? _findAvailableSkillById(String id) {
    for (final skill in _availableSkills) {
      if (skill['id']?.toString() == id) {
        return skill;
      }
    }
    return null;
  }

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
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.school, color: Color(0xFF1E56A0)),
          ),
        ),
        title: const Text(
          'SkillSwap',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.bold,
          ),
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
                    MaterialPageRoute(
                      builder: (context) => const LandingPage(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0097B2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editar Habilidades y Horarios',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
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
                _buildAvailabilitySection(isMobile),
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
                Expanded(flex: 2, child: _buildAvailabilitySection(isMobile)),
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
                onPressed: () async {
                  // Descartar cambios pendientes y cerrar
                  _pendingAdds.clear();
                  _pendingDeletes.clear();
                  _pendingInterestAdds.clear();
                  _pendingInterestDeletes.clear();
                  _pendingAvailabilityAdds.clear();
                  _pendingAvailabilityDeletes.clear();
                  await _loadMySkills();
                  await _loadMyInterests();
                  await _loadMyAvailability();
                  if (mounted) Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: Color(0xFF1E56A0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Color(0xFF1E56A0), fontSize: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () async {
                  await _saveChanges();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasPendingChanges()
                      ? const Color(0xFF0056D2)
                      : const Color(0xFFAAB2BD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Guardar Cambios',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadMySkills() async {
    if (_currentUserId == null) return;
    try {
      final response = await supabase
          .from('user_skills')
          .select('skill_id, level, skill:skills(id, name, category)')
          .eq('profile_id', _currentUserId!);

      final rows = (response as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      setState(() {
        _mySkills = rows.map((r) {
          final skill = (r['skill'] as Map<String, dynamic>?) ?? {};
          return {
            'skill_id':
                r['skill_id']?.toString() ?? skill['id']?.toString() ?? '',
            'name': skill['name']?.toString() ?? 'Sin nombre',
            'category': skill['category']?.toString() ?? 'General',
            'level': r['level']?.toString() ?? 'Intermedio',
          };
        }).toList();
      });
    } catch (e) {
      setState(() => _mySkills = []);
    }
  }

  Future<void> _loadAvailableSkills() async {
    try {
      final response = await supabase
          .from('skills')
          .select('id, name, category');
      final rows = (response as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      setState(() {
        _availableSkills = rows
            .map(
              (r) => {
                'id': r['id']?.toString() ?? '',
                'name': r['name']?.toString() ?? '',
                'category': r['category']?.toString() ?? 'General',
              },
            )
            .toList();
      });
    } catch (_) {
      setState(() => _availableSkills = []);
    }
  }

  Future<void> _loadMyInterests() async {
    if (_currentUserId == null) return;
    try {
      final response = await supabase
          .from('user_interests')
          .select('skill:skills(id, name, category)')
          .eq('profile_id', _currentUserId!);
      final rows = (response as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      setState(() {
        _myInterests = rows.map((r) {
          final skill = (r['skill'] as Map<String, dynamic>?) ?? {};
          return {
            'skill_id': skill['id']?.toString() ?? '',
            'name': skill['name']?.toString() ?? 'Sin nombre',
            'category': skill['category']?.toString() ?? 'General',
          };
        }).toList();
      });
    } catch (_) {
      setState(() => _myInterests = []);
    }
  }

  Future<void> _loadAvailableTimeSlots() async {
    try {
      final response = await supabase
          .from('time_slots')
          .select('id, range, shift');
      final rows = (response as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      setState(() {
        _availableTimeSlots = rows
            .map(
              (r) => {
                'id': r['id']?.toString() ?? '',
                'range': r['range']?.toString() ?? '',
                'shift': r['shift']?.toString() ?? '',
              },
            )
            .toList();
      });
    } catch (_) {
      setState(() => _availableTimeSlots = []);
    }
  }

  Future<void> _loadMyAvailability() async {
    if (_currentUserId == null) return;
    try {
      final response = await supabase
          .from('user_availability')
          .select('id, day, slot_id, slot:time_slots(id, range, shift)')
          .eq('profile_id', _currentUserId!);
      final rows = (response as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      setState(() {
        _myAvailability = rows.map((r) {
          final slot = (r['slot'] as Map<String, dynamic>?) ?? {};
          return {
            'id': r['id']?.toString() ?? '',
            'day': r['day']?.toString() ?? '',
            'slot_id': r['slot_id']?.toString() ?? '',
            'range': slot['range']?.toString() ?? '',
            'shift': slot['shift']?.toString() ?? '',
          };
        }).toList();
      });
    } catch (_) {
      setState(() => _myAvailability = []);
    }
  }

  Future<void> _saveChanges() async {
    if (_currentUserId == null) return;
    try {
      // Deletes
      for (final skillId in _pendingDeletes) {
        await supabase.from('user_skills').delete().match({
          'profile_id': _currentUserId!,
          'skill_id': skillId,
        });
      }

      for (final skillId in _pendingInterestDeletes) {
        await supabase.from('user_interests').delete().match({
          'profile_id': _currentUserId!,
          'skill_id': skillId,
        });
      }

      // Adds
      if (_pendingAdds.isNotEmpty) {
        final inserts = _pendingAdds
            .map(
              (a) => {
                'profile_id': _currentUserId!,
                'skill_id': a['skill_id'],
                'level': a['level'],
              },
            )
            .toList();
        await supabase.from('user_skills').insert(inserts);
      }

      if (_pendingInterestAdds.isNotEmpty) {
        final insertsI = _pendingInterestAdds
            .map(
              (a) => {'profile_id': _currentUserId!, 'skill_id': a['skill_id']},
            )
            .toList();
        await supabase.from('user_interests').insert(insertsI);
      }

      for (final availabilityId in _pendingAvailabilityDeletes) {
        await supabase.from('user_availability').delete().match({
          'profile_id': _currentUserId!,
          'id': availabilityId,
        });
      }

      if (_pendingAvailabilityAdds.isNotEmpty) {
        final insertsA = _pendingAvailabilityAdds
            .map(
              (a) => {
                'profile_id': _currentUserId!,
                'day': a['day'],
                'slot_id': a['slot_id'],
              },
            )
            .toList();
        await supabase.from('user_availability').insert(insertsA);
      }

      _pendingAdds.clear();
      _pendingDeletes.clear();
      _pendingInterestAdds.clear();
      _pendingInterestDeletes.clear();
      _pendingAvailabilityAdds.clear();
      _pendingAvailabilityDeletes.clear();
      await _loadMySkills();
      await _loadMyInterests();
      await _loadMyAvailability();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cambios guardados')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error guardando cambios: $e')));
    }
  }

  Future<void> _deleteMySkill(String skillId) async {
    if (_currentUserId == null) return;
    try {
      await supabase.from('user_skills').delete().match({
        'profile_id': _currentUserId!,
        'skill_id': skillId,
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Habilidad eliminada')));
      await _loadMySkills();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la habilidad: $e')),
      );
    }
  }

  Future<void> _deleteMyInterest(String skillId) async {
    if (_currentUserId == null) return;
    try {
      await supabase.from('user_interests').delete().match({
        'profile_id': _currentUserId!,
        'skill_id': skillId,
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Interés eliminado')));
      await _loadMyInterests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el interés: $e')),
      );
    }
  }

  String _resolveTimeSlotRange(String slotId) {
    for (final slot in _availableTimeSlots) {
      if (slot['id']?.toString() == slotId) {
        return slot['range']?.toString() ?? '';
      }
    }
    return '';
  }

  Widget _buildAvailabilitySection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disponibilidad Horaria',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(height: 16),
        _buildAvailabilityTable(isMobile),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _buildSelectionDropdown(
                label: 'Día',
                value: _selectedAvailabilityDay,
                items: _weekDays,
                onChanged: (value) =>
                    setState(() => _selectedAvailabilityDay = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSelectionDropdown(
                label: 'Horario',
                value: _selectedAvailabilitySlotId,
                items: _availableTimeSlots
                    .map((slot) => slot['id']?.toString() ?? '')
                    .where((v) => v.isNotEmpty)
                    .toList(),
                displayBuilder: (slotId) => _resolveTimeSlotRange(slotId),
                onChanged: (value) =>
                    setState(() => _selectedAvailabilitySlotId = value),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                if (_selectedAvailabilityDay == null ||
                    _selectedAvailabilitySlotId == null ||
                    _selectedAvailabilitySlotId!.isEmpty) {
                  return;
                }
                final alreadyExisting =
                    _myAvailability.any(
                      (a) =>
                          a['day'] == _selectedAvailabilityDay &&
                          a['slot_id'] == _selectedAvailabilitySlotId,
                    ) &&
                    !_pendingAvailabilityDeletes.any(
                      (id) => _myAvailability.any(
                        (a) =>
                            a['id'] == id &&
                            a['day'] == _selectedAvailabilityDay &&
                            a['slot_id'] == _selectedAvailabilitySlotId,
                      ),
                    );
                final alreadyPending = _pendingAvailabilityAdds.any(
                  (a) =>
                      a['day'] == _selectedAvailabilityDay &&
                      a['slot_id'] == _selectedAvailabilitySlotId,
                );
                if (alreadyExisting || alreadyPending) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ese horario ya está agregado'),
                    ),
                  );
                  return;
                }
                _pendingAvailabilityAdds.add({
                  'day': _selectedAvailabilityDay!,
                  'slot_id': _selectedAvailabilitySlotId!,
                });
                setState(() {});
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Añadir', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (_selectedAvailabilityDay != null &&
                        _selectedAvailabilitySlotId != null &&
                        _selectedAvailabilitySlotId!.isNotEmpty)
                    ? const Color(0xFF0056D2)
                    : const Color(0xFFAAB2BD),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String)? displayBuilder,
  }) {
    final validItems = items.where((item) => item.isNotEmpty).toList();
    final currentValue = value != null && validItems.contains(value)
        ? value
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
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
              value: currentValue,
              isExpanded: true,
              hint: const Text('-- Seleccionar --'),
              items: validItems
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        displayBuilder == null ? item : displayBuilder(item),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa la contraseña actual y la nueva'),
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La nueva contraseña no coincide')),
      );
      return;
    }

    final email = supabase.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener el correo del usuario'),
        ),
      );
      return;
    }

    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      await supabase.auth.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada. Inicia sesión otra vez.'),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (Route<dynamic> route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cambiar la contraseña: ${e.message}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cambiar la contraseña: $e')),
      );
    }
  }

  Widget _buildAvailabilityTable(bool isMobile) {
    final rows = <List<String>>[];

    for (final availability in _myAvailability) {
      final availabilityId = availability['id']?.toString() ?? '';
      final status = _pendingAvailabilityDeletes.contains(availabilityId)
          ? 'markedDelete'
          : 'existing';
      rows.add([
        availability['day']?.toString() ?? '',
        availability['range']?.toString() ?? '',
        'delete',
        availabilityId,
        status,
      ]);
    }

    for (final pending in _pendingAvailabilityAdds) {
      rows.add([
        pending['day'] ?? '',
        _resolveTimeSlotRange(pending['slot_id'] ?? ''),
        'delete',
        '${pending['day']}|${pending['slot_id']}',
        'pendingAdd',
      ]);
    }

    return _buildDataTableWithDelete(
      ['Día', 'Horario', 'Acción'],
      rows,
      isMobile,
    );
  }

  Widget _buildSkillsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Habilidades que enseñas
        const Text(
          'Habilidades que enseñas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(height: 16),
        _buildMySkillsTable(isMobile),
        const SizedBox(height: 20),

        // Inputs para añadir
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona una habilidad',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
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
                        value: _selectedSkillId,
                        isExpanded: true,
                        hint: const Text('-- Seleccionar --'),
                        items: _availableSkills
                            .map(
                              (s) => DropdownMenuItem<String>(
                                value: s['id']?.toString(),
                                child: Text(s['name'] ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSkillId = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nivel',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
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
                        value: _selectedLevelForAdd,
                        isExpanded: true,
                        items: ['Básico', 'Intermedio', 'Avanzado']
                            .map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)),
                            )
                            .toList(),
                        onChanged: (v) => setState(
                          () => _selectedLevelForAdd = v ?? 'Básico',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            // Añadir en memoria
            if (_selectedSkillId == null || _selectedSkillId!.isEmpty) return;
            final alreadyExisting =
                _mySkills.any((s) => s['skill_id'] == _selectedSkillId) &&
                !_pendingDeletes.contains(_selectedSkillId);
            final alreadyPendingAdd = _pendingAdds.any(
              (a) => a['skill_id'] == _selectedSkillId,
            );
            if (alreadyExisting || alreadyPendingAdd) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('La habilidad ya está en tu lista'),
                ),
              );
              return;
            }
            _pendingAdds.add({
              'skill_id': _selectedSkillId!,
              'level': _selectedLevelForAdd,
            });
            setState(() {});
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Añadir', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                (_selectedSkillId != null && _selectedSkillId!.isNotEmpty)
                ? const Color(0xFF0056D2)
                : const Color(0xFFAAB2BD),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Habilidades que busco aprender
        const Text(
          'Lo que busco aprender',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(height: 16),
        _buildMyInterestsTable(isMobile),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedInterestSkillId,
                    isExpanded: true,
                    hint: const Text('-- Seleccionar --'),
                    items: _availableSkills
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s['id']?.toString(),
                            child: Text(s['name'] ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedInterestSkillId = v),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                if (_selectedInterestSkillId == null ||
                    _selectedInterestSkillId!.isEmpty) {
                  return;
                }
                final alreadyExisting =
                    _myInterests.any(
                      (s) => s['skill_id'] == _selectedInterestSkillId,
                    ) &&
                    !_pendingInterestDeletes.contains(_selectedInterestSkillId);
                final alreadyPending = _pendingInterestAdds.any(
                  (a) => a['skill_id'] == _selectedInterestSkillId,
                );
                if (alreadyExisting || alreadyPending) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El interés ya está en tu lista'),
                    ),
                  );
                  return;
                }
                _pendingInterestAdds.add({
                  'skill_id': _selectedInterestSkillId!,
                });
                setState(() {});
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Añadir', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (_selectedInterestSkillId != null &&
                        _selectedInterestSkillId!.isNotEmpty)
                    ? const Color(0xFF0056D2)
                    : const Color(0xFFAAB2BD),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMySkillsTable(bool isMobile) {
    final List<List<String>> rows = [];

    for (final s in _mySkills) {
      final id = s['skill_id']?.toString() ?? '';
      final status = _pendingDeletes.contains(id) ? 'markedDelete' : 'existing';
      rows.add([
        s['category'] ?? '',
        s['name'] ?? '',
        s['level'] ?? '',
        'delete',
        id,
        status,
      ]);
    }

    for (final a in _pendingAdds) {
      final id = a['skill_id'] ?? '';
      final skill =
          _findAvailableSkillById(id) ??
          <String, dynamic>{'id': '', 'name': '', 'category': ''};
      rows.add([
        skill['category'] ?? '',
        skill['name'] ?? '',
        a['level'] ?? '',
        'delete',
        id,
        'pendingAdd',
      ]);
    }

    return _buildDataTableWithDelete(
      ['Categoría', 'Habilidad', 'Nivel', 'Acción'],
      rows,
      isMobile,
    );
  }

  Widget _buildMyInterestsTable(bool isMobile) {
    final List<List<String>> rows = [];

    for (final s in _myInterests) {
      final id = s['skill_id']?.toString() ?? '';
      final status = _pendingInterestDeletes.contains(id)
          ? 'markedDelete'
          : 'existing';
      rows.add([s['category'] ?? '', s['name'] ?? '', 'delete', id, status]);
    }

    for (final a in _pendingInterestAdds) {
      final id = a['skill_id'] ?? '';
      final skill =
          _findAvailableSkillById(id) ??
          <String, dynamic>{'id': '', 'name': '', 'category': ''};
      rows.add([
        skill['category'] ?? '',
        skill['name'] ?? '',
        'delete',
        id,
        'pendingAdd',
      ]);
    }

    return _buildDataTableWithDelete(
      ['Categoría', 'Habilidad', 'Acción'],
      rows,
      isMobile,
    );
  }

  Widget _buildDataTableWithDelete(
    List<String> headers,
    List<List<String>> rows,
    bool isMobile,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: isMobile ? 400 : 500),
        child: Table(
          columnWidths: const {3: FixedColumnWidth(50)},
          children: [
            TableRow(
              children: headers
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            ...rows.map((row) {
              return TableRow(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[100]!)),
                ),
                children: List<Widget>.generate(headers.length, (colIdx) {
                  // Determine indices for extra metadata appended to row
                  final int skillIdIndex = headers
                      .length; // skill_id placed just after visible columns
                  final int statusIndex =
                      headers.length + 1; // status after skill_id
                  final String skillId = (row.length > skillIdIndex)
                      ? (row[skillIdIndex] ?? '')
                      : '';
                  final String status = (row.length > statusIndex)
                      ? (row[statusIndex] ?? 'existing')
                      : 'existing';
                  final bool isAvailabilityTable =
                      headers.isNotEmpty && headers.first == 'Día';

                  final int actionColIdx =
                      headers.length - 1; // last visible column is action

                  if (colIdx == actionColIdx) {
                    if (status == 'markedDelete') {
                      return IconButton(
                        icon: const Icon(
                          Icons.undo,
                          color: Colors.orange,
                          size: 16,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isAvailabilityTable) {
                              _pendingAvailabilityDeletes.remove(skillId);
                            } else {
                              _pendingDeletes.remove(skillId);
                              _pendingInterestDeletes.remove(skillId);
                            }
                          });
                        },
                      );
                    }

                    if (status == 'pendingAdd') {
                      return IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 16,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isAvailabilityTable) {
                              _pendingAvailabilityAdds.removeWhere(
                                (a) => '${a['day']}|${a['slot_id']}' == skillId,
                              );
                            } else {
                              _pendingAdds.removeWhere(
                                (a) => a['skill_id'] == skillId,
                              );
                              _pendingInterestAdds.removeWhere(
                                (a) => a['skill_id'] == skillId,
                              );
                            }
                          });
                        },
                      );
                    }

                    return IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 16,
                      ),
                      onPressed: skillId.isEmpty
                          ? null
                          : () => setState(() {
                              if (isAvailabilityTable) {
                                _pendingAvailabilityDeletes.add(skillId);
                              } else {
                                // mark delete for skills or interests depending on presence
                                if (_mySkills.any(
                                  (s) => s['skill_id'] == skillId,
                                )) {
                                  _pendingDeletes.add(skillId);
                                }
                                if (_myInterests.any(
                                  (s) => s['skill_id'] == skillId,
                                )) {
                                  _pendingInterestDeletes.add(skillId);
                                }
                              }
                            }),
                    );
                  }

                  final cellValue = (colIdx < row.length)
                      ? (row[colIdx] ?? '')
                      : '';
                  final text = cellValue.toString();
                  TextStyle style = const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  );
                  if (status == 'markedDelete') {
                    style = style.copyWith(
                      color: Colors.redAccent,
                      decoration: TextDecoration.lineThrough,
                    );
                  } else if (status == 'pendingAdd') {
                    style = style.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.green[800],
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(text, style: style),
                  );
                }),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cambiar Contraseña',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
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
                  _buildPasswordField(
                    'Contraseña Actual *',
                    'Ingresa tu contraseña actual',
                    _currentPasswordController,
                    _obscureCurrent,
                    (val) => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    'Nueva Contraseña *',
                    'Ingresa tu contraseña nueva',
                    _newPasswordController,
                    _obscureNew,
                    (val) => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    'Confirmar Nueva Contraseña *',
                    'Confirma tu contraseña nueva',
                    _confirmPasswordController,
                    _obscureConfirm,
                    (val) => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056D2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cambiar Contraseña',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildDataTable(
    List<String> headers,
    List<List<String>> rows,
    bool isMobile,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: isMobile ? 400 : 500),
        child: Table(
          columnWidths: const {3: FixedColumnWidth(50)},
          children: [
            TableRow(
              children: headers
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            ...rows.map(
              (row) => TableRow(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[100]!)),
                ),
                children: row.map((cell) {
                  if (cell == 'delete') {
                    return IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 16,
                      ),
                      onPressed: () {},
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      cell,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
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
              items: [
                DropdownMenuItem(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 13)),
                ),
              ],
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

  Widget _buildPasswordField(
    String label,
    String hint,
    TextEditingController controller,
    bool obscure,
    Function(bool) toggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF5FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: () => toggle(obscure),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
