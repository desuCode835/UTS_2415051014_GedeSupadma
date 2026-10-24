import 'package:flutter/material.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';
import 'task_detail_screen.dart';
import 'add_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _selectedFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  // Sample local tasks data
  final List<Map<String, String>> _allTasks = [
    {
      'title': 'Implementasi Arsitektur & UI TaskMate',
      'course': 'Pemrograman Berbasis Mobile',
      'deadline': '28 Okt 2026, 23:59',
      'priority': 'Tinggi',
      'status': 'Belum Selesai',
      'description':
          'Menyelesaikan struktur folder dan membangun antarmuka 6 screen awal.',
    },
    {
      'title': 'Makalah Etika Profesi Teknologi Informasi',
      'course': 'Etika Profesi TI',
      'deadline': '30 Okt 2026, 17:00',
      'priority': 'Sedang',
      'status': 'Belum Selesai',
      'description':
          'Menyusun pembahasan kode etik pengembang perangkat lunak.',
    },
    {
      'title': 'Proyek Akhir Kecerdasan Buatan',
      'course': 'Kecerdasan Buatan',
      'deadline': '5 Nov 2026, 23:59',
      'priority': 'Tinggi',
      'status': 'Belum Selesai',
      'description':
          'Membuat model klasifikasi machine learning dengan dataset evaluasi performa.',
    },
    {
      'title': 'Review Jurnal Rekayasa Perangkat Lunak',
      'course': 'Rekayasa Perangkat Lunak',
      'deadline': '25 Okt 2026, 20:00',
      'priority': 'Rendah',
      'status': 'Selesai',
      'description':
          'Analisis metodologi Agile dalam pengembangan sistem mobile modern.',
    },
    {
      'title': 'Desain Wireframe Sistem Informasi Akademik',
      'course': 'Interaksi Manusia dan Komputer',
      'deadline': '24 Okt 2026, 15:00',
      'priority': 'Sedang',
      'status': 'Selesai',
      'description':
          'Membuat prototipe tampilan antarmuka berpusat pada pengalaman pengguna.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredTasks {
    List<Map<String, String>> list;
    if (_selectedFilter == 'Semua') {
      list = _allTasks;
    } else if (_selectedFilter == 'Belum Selesai') {
      list = _allTasks.where((t) => t['status'] == 'Belum Selesai').toList();
    } else if (_selectedFilter == 'Selesai') {
      list = _allTasks.where((t) => t['status'] == 'Selesai').toList();
    } else {
      // 'Arsip' filter is empty to demonstrate EmptyState
      return [];
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) {
        final title = t['title']?.toLowerCase() ?? '';
        final course = t['course']?.toLowerCase() ?? '';
        return title.contains(query) || course.contains(query);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _filteredTasks;

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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daftar Tugas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tambah Tugas',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTaskScreen()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              // Modern Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari tugas atau mata kuliah...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Chips
              Container(
                height: 46,
                padding: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('Semua', _allTasks.length),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Belum Selesai',
                      _allTasks.where((t) => t['status'] == 'Belum Selesai').length,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Selesai',
                      _allTasks.where((t) => t['status'] == 'Selesai').length,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip('Arsip', 0),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ],
          ),
        ),
      ),
      body: tasks.isEmpty
          ? EmptyState(
              icon: _selectedFilter == 'Arsip'
                  ? Icons.archive_outlined
                  : Icons.search_off_rounded,
              title: _selectedFilter == 'Arsip'
                  ? 'Belum Ada Tugas Terarsip'
                  : 'Tugas Tidak Ditemukan',
              message: _selectedFilter == 'Arsip'
                  ? 'Tugas kuliah yang Anda selesaikan dan arsipkan akan muncul di folder arsip ini.'
                  : 'Tidak ada tugas yang cocok dengan kata kunci atau filter yang Anda pilih.',
              actionLabel: 'Tambah Tugas Baru',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTaskScreen()),
                );
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(
                  title: task['title']!,
                  course: task['course'],
                  deadline: task['deadline']!,
                  priority: task['priority']!,
                  status: task['status']!,
                  description: task['description'],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TaskDetailScreen(),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
        },
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x180F172A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withAlpha(40)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
