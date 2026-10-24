import 'package:flutter/material.dart';
import '../models/task.dart';
import '../data/sample_tasks.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';
import 'task_detail_screen.dart';
import 'add_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  final List<Task>? tasks;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final void Function(Task task)? onTaskTap;
  final VoidCallback? onAddTask;

  const TaskListScreen({
    super.key,
    this.tasks,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onTaskTap,
    this.onAddTask,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _selectedFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  List<Task> get _allTasks => widget.tasks ?? sampleTasks;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> get _filteredTasks {
    List<Task> list;
    if (_selectedFilter == 'Semua') {
      list = _allTasks;
    } else if (_selectedFilter == 'Belum Selesai') {
      list = _allTasks.where((t) => !t.isCompleted).toList();
    } else if (_selectedFilter == 'Selesai') {
      list = _allTasks.where((t) => t.isCompleted).toList();
    } else {
      // 'Arsip' filter is empty to demonstrate EmptyState
      return [];
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) {
        final title = t.title.toLowerCase();
        final desc = t.description.toLowerCase();
        return title.contains(query) || desc.contains(query);
      }).toList();
    }

    return list;
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
                    _buildFilterChip('Semua', all.length),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Belum Selesai',
                      all.where((t) => !t.isCompleted).length,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Selesai',
                      all.where((t) => t.isCompleted).length,
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
      body: widget.isLoading && _allTasks.isEmpty
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
              ? Center(
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
                            border: Border.all(color: const Color(0xFFFECACA)),
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
                        if (widget.onRetry != null) ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: widget.onRetry,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
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
                      ],
                    ),
                  ),
                )
              : tasks.isEmpty
                  ? EmptyState(
                      icon: _allTasks.isEmpty
                          ? Icons.task_outlined
                          : (_selectedFilter == 'Arsip'
                              ? Icons.archive_outlined
                              : Icons.search_off_rounded),
                      title: _allTasks.isEmpty
                          ? 'Belum Ada Tugas'
                          : (_selectedFilter == 'Arsip'
                              ? 'Belum Ada Tugas Terarsip'
                              : 'Tugas Tidak Ditemukan'),
                      message: _allTasks.isEmpty
                          ? 'Belum ada tugas kuliah yang tersimpan. Ketuk tombol di bawah untuk menambahkan tugas baru.'
                          : (_selectedFilter == 'Arsip'
                              ? 'Tugas kuliah yang Anda selesaikan dan arsipkan akan muncul di folder arsip ini.'
                              : 'Tidak ada tugas yang cocok dengan kata kunci atau filter yang Anda pilih.'),
                      actionLabel: 'Tambah Tugas Baru',
                      onAction: _openAddTask,
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
                        if (widget.errorMessage != null && _allTasks.isNotEmpty)
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
                                if (widget.onRetry != null)
                                  InkWell(
                                    onTap: widget.onRetry,
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

                              return GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
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
