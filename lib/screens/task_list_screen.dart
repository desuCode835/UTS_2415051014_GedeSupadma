import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../data/sample_tasks.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';
import 'task_detail_screen.dart';
import 'add_task_screen.dart';
import 'archive_screen.dart';

class TaskListScreen extends StatefulWidget {
  final List<Task>? tasks;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;
  final void Function(Task task)? onTaskTap;
  final VoidCallback? onAddTask;

  const TaskListScreen({
    super.key,
    this.tasks,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onRefresh,
    this.onTaskTap,
    this.onAddTask,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _selectedFilter = 'Semua';
  String _selectedPriority = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _togglingTaskIds = {};

  List<Task> get _allTasks => widget.tasks ?? sampleTasks;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> get _filteredTasks {
    List<Task> list;
    if (_selectedFilter == 'Semua') {
      list = _allTasks.where((t) => !t.isArchived).toList();
    } else if (_selectedFilter == 'Belum Selesai') {
      list = _allTasks.where((t) => !t.isArchived && !t.isCompleted).toList();
    } else if (_selectedFilter == 'Selesai') {
      list = _allTasks.where((t) => !t.isArchived && t.isCompleted).toList();
    } else {
      // 'Arsip' filter
      list = _allTasks.where((t) => t.isArchived).toList();
    }

    if (_selectedPriority != 'Semua') {
      list = list.where((t) {
        return t.priority.trim().toLowerCase() ==
            _selectedPriority.trim().toLowerCase();
      }).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) {
        final title = t.title.toLowerCase();
        final desc = t.description.toLowerCase();
        final course = (t.courseCategory ?? '').toLowerCase();
        return title.contains(query) ||
            desc.contains(query) ||
            course.contains(query);
      }).toList();
    }

    return list;
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    } else {
      try {
        await Provider.of<TaskProvider>(context, listen: false).loadTasks();
      } catch (_) {}
    }
  }

  void _handleRetry() {
    if (widget.onRetry != null) {
      widget.onRetry!();
    } else {
      try {
        Provider.of<TaskProvider>(context, listen: false).loadTasks();
      } catch (_) {}
    }
  }

  Future<void> _handleToggleTaskCompletion(Task task) async {
    if (_togglingTaskIds.contains(task.id)) return;

    setState(() {
      _togglingTaskIds.add(task.id);
    });

    try {
      TaskProvider? provider;
      try {
        provider = Provider.of<TaskProvider>(context, listen: false);
      } catch (_) {
        provider = null;
      }

      if (provider != null) {
        final updated = await provider.toggleTaskCompletion(task);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                updated.isCompleted
                    ? 'Tugas "${task.title}" ditandai selesai.'
                    : 'Tugas "${task.title}" ditandai belum selesai.',
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status tugas: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _togglingTaskIds.remove(task.id);
        });
      }
    }
  }

  void _openAddTask() {
    if (widget.onAddTask != null) {
      widget.onAddTask!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddTaskScreen()),
      );
    }
  }

  void _handleTaskTap(Task task) {
    if (widget.onTaskTap != null) {
      widget.onTaskTap!(task);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(task: task),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _filteredTasks;
    final all = _allTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
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
              )
            : null,
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
            tooltip: 'Halaman Arsip',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.archive_outlined,
                color: Color(0xFF334155),
                size: 20,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArchiveScreen()),
              );
            },
          ),
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
            onPressed: _openAddTask,
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(154),
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
                    key: const ValueKey('task_search_field'),
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
              const SizedBox(height: 8),

              // Status Filter Chips
              Container(
                height: 38,
                padding: const EdgeInsets.only(bottom: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip(
                      'Semua',
                      all.where((t) => !t.isArchived).length,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Belum Selesai',
                      all.where((t) => !t.isArchived && !t.isCompleted).length,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Selesai',
                      all.where((t) => !t.isArchived && t.isCompleted).length,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Arsip',
                      all.where((t) => t.isArchived).length,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Priority Filter Chips Row
              Container(
                height: 34,
                padding: const EdgeInsets.only(bottom: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildPriorityChip('Semua'),
                    const SizedBox(width: 8),
                    _buildPriorityChip('Tinggi'),
                    const SizedBox(width: 8),
                    _buildPriorityChip('Sedang'),
                    const SizedBox(width: 8),
                    _buildPriorityChip('Rendah'),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: widget.isLoading && _allTasks.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memuat daftar tugas...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              )
            : widget.errorMessage != null && _allTasks.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: const Color(0xFFFECACA)),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Gagal Memuat Tugas',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    key: const ValueKey('retry_button'),
                                    onPressed: _handleRetry,
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 18),
                                    label: const Text('Coba Lagi'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F172A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : tasks.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final isFiltered = _searchController.text.trim().isNotEmpty ||
                              _selectedPriority != 'Semua' ||
                              (_selectedFilter != 'Semua' && _selectedFilter != 'Arsip');

                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: EmptyState(
                                icon: isFiltered
                                    ? Icons.search_off_rounded
                                    : (_selectedFilter == 'Arsip'
                                        ? Icons.archive_outlined
                                        : Icons.task_outlined),
                                title: isFiltered
                                    ? 'Tugas Tidak Ditemukan'
                                    : (_selectedFilter == 'Arsip'
                                        ? 'Belum Ada Tugas Terarsip'
                                        : 'Belum Ada Tugas'),
                                message: _searchController.text.trim().isNotEmpty
                                    ? 'Tidak ada tugas yang cocok dengan "${_searchController.text.trim()}". Periksa kata kunci atau ubah filter.'
                                    : (isFiltered
                                        ? 'Tidak ada tugas yang sesuai dengan filter yang dipilih.'
                                        : (_selectedFilter == 'Arsip'
                                            ? 'Tugas kuliah yang Anda arsipkan akan muncul di folder arsip ini.'
                                            : 'Belum ada tugas kuliah yang tersimpan. Ketuk tombol di bawah untuk menambahkan tugas baru.')),
                                actionLabel: isFiltered
                                    ? 'Reset Filter & Pencarian'
                                    : (_selectedFilter == 'Arsip'
                                        ? 'Buka Halaman Arsip'
                                        : 'Tambah Tugas Baru'),
                                onAction: isFiltered
                                    ? () {
                                        setState(() {
                                          _searchController.clear();
                                          _selectedFilter = 'Semua';
                                          _selectedPriority = 'Semua';
                                        });
                                      }
                                    : (_selectedFilter == 'Arsip'
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ArchiveScreen()),
                                            );
                                          }
                                        : _openAddTask),
                              ),
                            ),
                          );
                        },
                      )
                    : Column(
                        children: [
                          if (widget.isLoading && _allTasks.isNotEmpty)
                            const LinearProgressIndicator(
                              minHeight: 2.5,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2563EB),
                              ),
                            ),
                          if (widget.errorMessage != null &&
                              _allTasks.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              color: const Color(0xFFFEF2F2),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 16,
                                    color: Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF991B1B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  InkWell(
                                    key: const ValueKey('banner_retry_button'),
                                    onTap: _handleRetry,
                                    child: const Text(
                                      'Coba Lagi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFDC2626),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                final int crossAxisCount;
                                if (width < 600) {
                                  crossAxisCount = 1;
                                } else if (width < 840) {
                                  crossAxisCount = 2;
                                } else {
                                  crossAxisCount = 3;
                                }

                                return Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 1200),
                                    child: GridView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 16, 16, 80),
                                      itemCount: tasks.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                        mainAxisExtent: crossAxisCount == 1
                                            ? 245
                                            : (crossAxisCount == 2 ? 240 : 250),
                                      ),
                                      itemBuilder: (context, index) {
                                        final task = tasks[index];
                                        return TaskCard(
                                          title: task.title,
                                          course: task.courseCategory,
                                          deadline: task.deadline,
                                          priority: task.priority,
                                          status: task.isCompleted
                                              ? 'Selesai'
                                              : 'Belum Selesai',
                                          description: task.description.isEmpty
                                              ? null
                                              : task.description,
                                          margin: EdgeInsets.zero,
                                          onTap: () => _handleTaskTap(task),
                                          isToggling: _togglingTaskIds
                                              .contains(task.id),
                                          onToggleCompletion: () =>
                                              _handleToggleTaskCompletion(task),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'task_list_add_task_fab',
        onPressed: _openAddTask,
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
      key: ValueKey('filter_chip_$label'),
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

  Widget _buildPriorityChip(String label) {
    final isSelected = _selectedPriority == label;
    final Color accentColor;
    switch (label.toLowerCase()) {
      case 'tinggi':
        accentColor = const Color(0xFFDC2626);
        break;
      case 'sedang':
        accentColor = const Color(0xFFD97706);
        break;
      case 'rendah':
        accentColor = const Color(0xFF2563EB);
        break;
      default:
        accentColor = const Color(0xFF0F172A);
    }

    return GestureDetector(
      key: ValueKey('priority_chip_$label'),
      onTap: () {
        setState(() {
          _selectedPriority = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withAlpha(50),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != 'Semua') ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label == 'Semua' ? 'Semua Prioritas' : label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
