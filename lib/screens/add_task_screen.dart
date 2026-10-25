import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  String _selectedPriority = 'Sedang';
  bool _isSubmitting = false;

  static const List<String> _validPriorities = ['Rendah', 'Sedang', 'Tinggi'];

  final List<String> _courseSuggestions = [
    'Pemrograman Mobile - Tugas',
    'Basis Data - Praktikum',
    'Pemrograman Mobile - Proyek',
    'Statistika - Ujian',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _courseController.dispose();
    _descController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: DateTime(now.year + 4),
      helpText: 'PILIH TENGGAT WAKTU (DEADLINE)',
      confirmText: 'LANJUT',
      cancelText: 'BATAL',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
        helpText: 'PILIH JAM TENGGAT WAKTU',
        confirmText: 'SIMPAN',
        cancelText: 'BATAL',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF0F172A),
                onPrimary: Colors.white,
                onSurface: Color(0xFF0F172A),
              ),
            ),
            child: child!,
          );
        },
      );

      if (context.mounted) {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des'
        ];
        final String hour =
            (pickedTime?.hour ?? 23).toString().padLeft(2, '0');
        final String minute =
            (pickedTime?.minute ?? 59).toString().padLeft(2, '0');
        setState(() {
          _deadlineController.text =
              '${pickedDate.day} ${months[pickedDate.month - 1]} ${pickedDate.year}, $hour:$minute WITA';
        });
      }
    }
  }

  Future<void> _submitTask() async {
    final title = _titleController.text.trim();
    final deadline = _deadlineController.text.trim();
    final description = _descController.text.trim();
    final courseCategory = _courseController.text.trim().isEmpty
        ? null
        : _courseController.text.trim();

    // Validasi judul wajib diisi dan bukan hanya spasi
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Judul tugas wajib diisi!'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Validasi tenggat waktu wajib dipilih
    if (deadline.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tenggat waktu (deadline) wajib diisi!'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Validasi prioritas harus valid
    if (!_validPriorities.contains(_selectedPriority)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prioritas wajib dipilih dan harus valid!'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      Task? createdTask;
      TaskProvider? provider;
      try {
        provider = Provider.of<TaskProvider>(context, listen: false);
      } catch (_) {
        provider = null;
      }

      if (provider != null) {
        createdTask = await provider.createTask(
          title: title,
          description: description,
          deadline: deadline,
          priority: _selectedPriority,
          isCompleted: false,
          courseCategory: courseCategory,
        );
      } else {
        // Fallback jika AddTaskScreen dijalankan tanpa Provider di context test
        createdTask = Task(
          id: 'task_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          description: description,
          deadline: deadline,
          priority: _selectedPriority,
          isCompleted: false,
          courseCategory: courseCategory,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tugas "$title" berhasil ditambahkan!'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, createdTask);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan tugas: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF0F172A),
              size: 18,
            ),
          ),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Tugas Baru',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Group 1: Task Information
                _buildFormSection(
                  title: 'Informasi Tugas',
                  icon: Icons.assignment_outlined,
                  children: [
                    _buildFieldLabel('Judul Tugas *'),
                    TextFormField(
                      controller: _titleController,
                      enabled: !_isSubmitting,
                      decoration: _inputDecoration(
                        hintText: 'Contoh: Laporan Praktikum Mobile',
                        prefixIcon: Icons.title_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul tugas wajib diisi!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Mata Kuliah / Kategori'),
                    TextFormField(
                      controller: _courseController,
                      enabled: !_isSubmitting,
                      decoration: _inputDecoration(
                        hintText: 'Pilih atau ketik mata kuliah...',
                        prefixIcon: Icons.school_outlined,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Suggestion Pills
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _courseSuggestions.map((c) {
                        return InkWell(
                          onTap: _isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _courseController.text = c;
                                  });
                                },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '+ $c',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Card Group 2: Schedule & Priority
                _buildFormSection(
                  title: 'Jadwal & Prioritas',
                  icon: Icons.calendar_today_rounded,
                  children: [
                    _buildFieldLabel('Tenggat Waktu (Deadline) *'),
                    InkWell(
                      onTap: _isSubmitting ? null : () => _selectDeadline(context),
                      borderRadius: BorderRadius.circular(12),
                      child: IgnorePointer(
                        child: TextFormField(
                          controller: _deadlineController,
                          readOnly: true,
                          decoration: _inputDecoration(
                            hintText: 'Ketuk untuk memilih deadline',
                            prefixIcon: Icons.calendar_month_rounded,
                            suffixIcon: const Icon(
                              Icons.edit_calendar_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Tenggat waktu (deadline) wajib diisi!';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Tingkat Prioritas *'),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedPriority),
                      initialValue: _selectedPriority,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        hintText: 'Pilih tingkat prioritas',
                        prefixIcon: Icons.flag_rounded,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF64748B),
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(
                          value: 'Rendah',
                          child: Text(
                            'Rendah',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Sedang',
                          child: Text(
                            'Sedang',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Tinggi',
                          child: Text(
                            'Tinggi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPriority = value;
                                });
                              }
                            },
                      validator: (value) {
                        if (value == null ||
                            !_validPriorities.contains(value)) {
                          return 'Prioritas wajib dipilih!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    // Quick priority selection buttons
                    Row(
                      children: [
                        _buildPriorityOption('Rendah', const Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        _buildPriorityOption('Sedang', const Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        _buildPriorityOption('Tinggi', const Color(0xFFDC2626)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Card Group 3: Description
                _buildFormSection(
                  title: 'Rincian & Catatan',
                  icon: Icons.notes_rounded,
                  children: [
                    _buildFieldLabel('Deskripsi Tugas (Opsional)'),
                    TextFormField(
                      controller: _descController,
                      enabled: !_isSubmitting,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Tuliskan instruksi tugas, kriteria penilaian, atau catatan penting...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F172A),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitTask,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 20),
                    label: Text(_isSubmitting ? 'Menyimpan Tugas...' : 'Simpan Tugas Baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      disabledBackgroundColor: const Color(0xFF64748B),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      elevation: 3,
                      shadowColor: const Color(0x330F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton.icon(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Batal'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
      ),
    );
  }

  Widget _buildPriorityOption(String label, Color color) {
    final isSelected = _selectedPriority == label;
    return Expanded(
      child: GestureDetector(
        onTap: _isSubmitting
            ? null
            : () {
                setState(() {
                  _selectedPriority = label;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(25) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
