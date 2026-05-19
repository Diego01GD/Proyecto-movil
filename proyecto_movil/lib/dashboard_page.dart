import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _supabase = Supabase.instance.client;

  // Parámetros de filtrado
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedLevel;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoadingUsers = true;

  // Categorías y habilidades cargadas desde public.skills
  Map<String, List<String>> categorySkills = {};

  List<Map<String, dynamic>> users = [];
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, full_name, career, gpa, is_complete');

      // Cargar el perfil del usuario actual para poder usar su nombre en el cuerpo del correo
      if (currentUserId != null) {
        try {
          final myProfile = await _supabase
              .from('profiles')
              .select('full_name')
              .eq('id', currentUserId)
              .maybeSingle();
          if (myProfile is Map<String, dynamic>) {
            _currentUserName = (myProfile['full_name'] ?? '').toString();
          }
        } catch (_) {
          // ignore
        }
      }

      final skillsResponse = await _supabase
          .from('skills')
          .select('id, name, category');

      final userSkillsResponse = await _supabase
          .from('user_skills')
          .select('profile_id, level, skill:skills(id, name, category)');

      final userInterestsResponse = await _supabase
          .from('user_interests')
          .select('profile_id, skill:skills(id, name, category)');

      final availabilityResponse = await _supabase
          .from('user_availability')
          .select('profile_id, day, comment, slot:time_slots(range, shift)');

      final emailByProfile = await _fetchEmailsByProfileId();

      final skillsRows = (skillsResponse as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      final userSkillsRows = (userSkillsResponse as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      final interestRows = (userInterestsResponse as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      final availabilityRows = (availabilityResponse as List)
          .whereType<Map<String, dynamic>>()
          .toList();

      final categoryMap = <String, Set<String>>{};
      for (final row in skillsRows) {
        final category = _readString(row, ['category'], 'General');
        final skillName = _readString(row, ['name'], 'Sin habilidad');
        categoryMap.putIfAbsent(category, () => <String>{}).add(skillName);
      }

      final userSkillsByProfile = <String, List<Map<String, dynamic>>>{};
      for (final row in userSkillsRows) {
        final profileId = row['profile_id']?.toString();
        if (profileId == null || profileId.isEmpty) continue;
        userSkillsByProfile
            .putIfAbsent(profileId, () => <Map<String, dynamic>>[])
            .add(row);
      }

      final interestsByProfile = <String, List<Map<String, dynamic>>>{};
      for (final row in interestRows) {
        final profileId = row['profile_id']?.toString();
        if (profileId == null || profileId.isEmpty) continue;
        interestsByProfile
            .putIfAbsent(profileId, () => <Map<String, dynamic>>[])
            .add(row);
      }

      final availabilityByProfile = <String, List<Map<String, dynamic>>>{};
      for (final row in availabilityRows) {
        final profileId = row['profile_id']?.toString();
        if (profileId == null || profileId.isEmpty) continue;
        availabilityByProfile
            .putIfAbsent(profileId, () => <Map<String, dynamic>>[])
            .add(row);
      }

      final profileRows = (profilesResponse as List)
          .whereType<Map<String, dynamic>>()
          .where((row) => row['id']?.toString() != currentUserId)
          .toList();

      final rows = profileRows.map((row) {
        final profileId = row['id']?.toString() ?? '';

        final skillsForProfile = userSkillsByProfile[profileId] ?? const [];
        final firstSkill = skillsForProfile.isNotEmpty
            ? (skillsForProfile.first['skill'] as Map<String, dynamic>?)
            : null;

        final interestsForProfile = interestsByProfile[profileId] ?? const [];
        final firstInterest = interestsForProfile.isNotEmpty
            ? (interestsForProfile.first['skill'] as Map<String, dynamic>?)
            : null;

        final availabilityForProfile =
            availabilityByProfile[profileId] ?? const [];
        final firstAvailability = availabilityForProfile.isNotEmpty
            ? availabilityForProfile.first
            : null;
        final slot = firstAvailability == null
            ? null
            : firstAvailability['slot'] as Map<String, dynamic>?;
        final range = slot == null ? '' : _readString(slot, ['range'], '');
        final parsedRange = _parseTimeRange(range);

        return {
          'name': _readString(row, ['full_name'], 'Usuario SkillSwap'),
          'email': emailByProfile[profileId] ?? '',
          'skill': firstSkill == null
              ? 'Habilidad por definir'
              : _readString(firstSkill, ['name'], 'Habilidad por definir'),
          'category': firstSkill == null
              ? 'General'
              : _readString(firstSkill, ['category'], 'General'),
          'level': _readString(
            skillsForProfile.isNotEmpty ? skillsForProfile.first : const {},
            ['level'],
            'Intermedio',
          ),
          'availability': range.isEmpty ? 'Horario por acordar' : range,
          'startTime': parsedRange[0],
          'endTime': parsedRange[1],
          'gpa': row['gpa']?.toString() ?? '-',
          'career': _readString(row, ['career'], 'Carrera no especificada'),
          'day': firstAvailability == null
              ? 'Por acordar'
              : _readString(firstAvailability, ['day'], 'Por acordar'),
          'interestSkill': firstInterest == null
              ? 'Sin interés registrado'
              : _readString(firstInterest, ['name'], 'Sin interés registrado'),
          'interestCategory': firstInterest == null
              ? 'General'
              : _readString(firstInterest, ['category'], 'General'),
        };
      }).toList();

      if (mounted) {
        setState(() {
          users = rows;
          categorySkills = {
            for (final entry in categoryMap.entries)
              entry.key: entry.value.toList()..sort(),
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          users = [];
          categorySkills = {};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo cargar información desde la base de datos: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  Future<Map<String, String>> _fetchEmailsByProfileId() async {
    try {
      final response = await _supabase.rpc('get_public_profiles_with_email');
      final rows = (response as List).whereType<Map<String, dynamic>>();
      final map = <String, String>{};
      for (final row in rows) {
        final id = row['id']?.toString();
        final email = row['email']?.toString();
        if (id != null && id.isNotEmpty && email != null && email.isNotEmpty) {
          map[id] = email;
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  List<TimeOfDay> _parseTimeRange(String range) {
    final match = RegExp(
      r'^(\d{2}):(\d{2})\s*-\s*(\d{2}):(\d{2})$',
    ).firstMatch(range.trim());
    if (match == null) {
      return [
        const TimeOfDay(hour: 0, minute: 0),
        const TimeOfDay(hour: 23, minute: 59),
      ];
    }

    return [
      TimeOfDay(
        hour: int.parse(match.group(1)!),
        minute: int.parse(match.group(2)!),
      ),
      TimeOfDay(
        hour: int.parse(match.group(3)!),
        minute: int.parse(match.group(4)!),
      ),
    ];
  }

  String _readString(
    Map<String, dynamic> row,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = row[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return users.where((user) {
      final matchesSearch =
          user['skill'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user['name'].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == null || user['category'] == _selectedCategory;
      final matchesLevel =
          _selectedLevel == null || user['level'] == _selectedLevel;

      bool matchesTime = true;
      if (_startTime != null && _endTime != null) {
        final userStart = user['startTime'] as TimeOfDay;
        final userEnd = user['endTime'] as TimeOfDay;

        // Verifica si hay solapamiento de horarios
        double toDouble(TimeOfDay myTime) => myTime.hour + myTime.minute / 60.0;
        double filterStart = toDouble(_startTime!);
        double filterEnd = toDouble(_endTime!);
        double uStart = toDouble(userStart);
        double uEnd = toDouble(userEnd);

        matchesTime = (uStart < filterEnd && uEnd > filterStart);
      }

      return matchesSearch && matchesCategory && matchesLevel && matchesTime;
    }).toList();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtros de Búsqueda',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Categorías
                  const Text(
                    'Categoría',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedCategory,
                    hint: const Text('Seleccionar categoría'),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: categorySkills.keys
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setModalState(() {
                        _selectedCategory = val;
                        // Si la habilidad actual no pertenece a la nueva categoría, la limpiamos
                        if (val != null &&
                            !(categorySkills[val]?.contains(_searchQuery) ??
                                false)) {
                          _searchQuery = '';
                        }
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 15),

                  // Habilidades específicas dinámicas
                  const Text(
                    'Habilidad',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue:
                        (categorySkills[_selectedCategory]?.contains(
                              _searchQuery,
                            ) ??
                            false)
                        ? _searchQuery
                        : null,
                    hint: const Text('Seleccionar habilidad'),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items:
                        (_selectedCategory == null
                                ? users
                                      .map((u) => u['skill'] as String)
                                      .toSet()
                                      .toList()
                                : categorySkills[_selectedCategory]!)
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (val) {
                      setModalState(() => _searchQuery = val ?? '');
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 15),

                  // Nivel
                  const Text(
                    'Nivel',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: ['Principiante', 'Intermedio', 'Avanzado'].map((
                      level,
                    ) {
                      final isSelected = _selectedLevel == level;
                      return ChoiceChip(
                        label: Text(level),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(
                            () => _selectedLevel = selected ? level : null,
                          );
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 15),

                  // Horario
                  const Text(
                    'Horario disponible',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _startTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setModalState(() => _startTime = time);
                              setState(() {});
                            }
                          },
                          child: Text(
                            _startTime == null
                                ? 'Desde'
                                : _startTime!.format(context),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('-'),
                      ),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _endTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setModalState(() => _endTime = time);
                              setState(() {});
                            }
                          },
                          child: Text(
                            _endTime == null
                                ? 'Hasta'
                                : _endTime!.format(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedCategory = null;
                              _selectedLevel = null;
                              _startTime = null;
                              _endTime = null;
                            });
                            setState(() {});
                          },
                          child: const Text('Limpiar Filtros'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7DAB),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Aplicar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUserProfile(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, controller) {
          final isMobile = MediaQuery.of(context).size.width < 600;
          final contentPadding = isMobile ? 16.0 : 32.0;

          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: isMobile
                  ? 0
                  : MediaQuery.of(context).size.width * 0.15,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF7F2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Barra superior de cierre para escritorio/web
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Volver a la ventana principal'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1E56A0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: EdgeInsets.symmetric(horizontal: contentPadding),
                    children: [
                      // Header Card (Nombre y Foto)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            Column(
                              crossAxisAlignment: isMobile
                                  ? CrossAxisAlignment.center
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'],
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A5F),
                                  ),
                                ),
                                Text(
                                  user['email'] == null ||
                                          (user['email'] as String)
                                              .trim()
                                              .isEmpty
                                      ? 'Correo no disponible'
                                      : user['email'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Info Cards Row/Column
                      if (isMobile) ...[
                        _buildInfoCard('Información Académica', [
                          'Promedio: ${user['gpa']}',
                          'Semestre: 6°',
                          'Matrícula: L22080765',
                        ], Colors.white),
                        const SizedBox(height: 12),
                        _buildInfoCard('Disponibilidad Semanal', [
                          user['day'],
                          user['availability'],
                        ], Colors.white),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInfoCard('Información Académica', [
                                'Promedio: ${user['gpa']}',
                                'Semestre: 6°',
                                'Matrícula: L22080765',
                              ], Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard('Disponibilidad Semanal', [
                                user['day'],
                                user['availability'],
                              ], Colors.white),
                            ),
                          ],
                        ),

                      const SizedBox(height: 25),

                      // Skills Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Habilidades que Ofrezco',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A5F),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Chip(
                              label: Text(
                                '${user['category']} • ${user['skill']} (Avanzado)',
                              ),
                              backgroundColor: const Color(0xFFE3F2FD),
                              labelStyle: const TextStyle(
                                color: Color(0xFF1E56A0),
                                fontSize: 13,
                              ),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Lo que busco aprender',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A5F),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Chip(
                              label: const Text('Música • Canto'),
                              backgroundColor: const Color(0xFFF5F5F5),
                              labelStyle: const TextStyle(
                                color: Color(0xFF616161),
                                fontSize: 13,
                              ),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Botón Enviar Correo
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _sendEmailToUser(user);
                          },
                          icon: const Icon(Icons.mail_outline_rounded),
                          label: const Text(
                            'Enviar Correo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7DAB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    List<String> items,
    Color color, {
    Widget? customContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 12),
          if (customContent != null)
            Center(child: customContent)
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _sendEmailToUser(Map<String, dynamic> user) async {
    final String userEmail = (user['email'] ?? '').toString().trim();
    if (userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este perfil no tiene correo disponible en la base de datos.',
          ),
        ),
      );
      return;
    }

    final String selectedSkill = (user['skill'] ?? 'la habilidad indicada')
        .toString();
    final String subject =
        'Solicitud de intercambio de habilidades - $selectedSkill';
    final String body =
        '''Hola ${user['name']},

  Vi tu perfil en SkillSwap y me interesa solicitar un intercambio de habilidades.

  Habilidad de interés: $selectedSkill.

  Si te parece bien, podemos coordinar horario y modalidad.

  Saludos,
  ${_currentUserName.isNotEmpty ? _currentUserName : '[Tu nombre]'}''';

    // Construimos la URI manualmente con codificación para evitar problemas
    // en dispositivos donde `canLaunchUrl` retorna false inesperadamente.
    final String encodedSubject = Uri.encodeComponent(subject);
    final String encodedBody = Uri.encodeComponent(body);
    final String uriString =
        'mailto:$userEmail?subject=$encodedSubject&body=$encodedBody';

    try {
      final uri = Uri.parse(uriString);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el cliente de correo'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir cliente de correo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.school, color: Color(0xFF2E7DAB)),
            const SizedBox(width: 8),
            if (!isMobile)
              const Text(
                'SkillSwap',
                style: TextStyle(
                  color: Color(0xFF1E3A5F),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                );
              },
              child: const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFF2E7DAB),
                child: Text(
                  'A',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de búsqueda
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _showFilterModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Icon(
                      Icons.tune,
                      size: 20,
                      color:
                          (_selectedCategory != null ||
                              _selectedLevel != null ||
                              _startTime != null)
                          ? const Color(0xFF2E7DAB)
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contenido principal
            if (_isLoadingUsers)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isMobile ? 0.85 : 1.1,
                ),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return _buildUserCard(user);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['name'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'HABILIDAD',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user['skill'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF2E7DAB),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  user['level'],
                  style: const TextStyle(fontSize: 9, color: Color(0xFF2E7DAB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 35,
            child: ElevatedButton(
              onPressed: () => _showUserProfile(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7DAB),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Más Info',
                style: TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estado de Intercambios',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tienes 0 de 6 activos',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.0,
            backgroundColor: Colors.grey[200],
            color: const Color(0xFF2E7DAB),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '0/6',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard() {
    final trends = [
      {'id': 1, 'name': 'Adobe Illustrator', 'count': '2 personas'},
      {'id': 2, 'name': 'React', 'count': '2 personas'},
      {'id': 3, 'name': 'Photoshop', 'count': '2 personas'},
      {'id': 4, 'name': 'Python', 'count': '2 personas'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Habilidades en Tendencia',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 12),
          ...trends.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      t['id'].toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t['name'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    t['count'] as String,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
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
