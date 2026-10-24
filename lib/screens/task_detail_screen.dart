import 'package:flutter/material.dart';
import '../models/task.dart';
import '../data/sample_tasks.dart';
import 'edit_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskItem? task;
  final void Function(TaskItem updatedTask)? onTaskUpdated;

  const TaskDetailScreen({
    super.key,
    this.task,
    this.onTaskUpdated,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TaskItem _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task ?? sampleTasks.first;
  }

  @override
  void didUpdateWidget(covariant TaskDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task != null && widget.task != oldWidget.task) {
      _task = widget.task!;
    }
  }

  Future<void> _openEditTask() async {
    final updated = await Navigator.push<TaskItem>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTaskScreen(task: _task),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _task = updated;
      });
      widget.onTaskUpdated?.call(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perubahan tugas "${updated.title}" berhasil disimpan!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _toggleTaskStatus() {
    final nextStatus = _task.isCompleted ? 'Belum Selesai' : 'Selesai';
    final updated = _task.copyWith(status: nextStatus);
    setState(() {
      _task = updated;
    });
    widget.onTaskUpdated?.call(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated.isCompleted
              ? 'Tugas ditandai selesai.'
              : 'Tugas ditandai belum selesai.',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'tinggi':
        return const Color(0xFFDC2626);
      case 'sedang':
        return const Color(0xFFD97706);
      case 'rendah':
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color _getPriorityBg(String priority) {
    switch (priority.toLowerCase()) {
      case 'tinggi':
        return const Color(0xFFFEF2F2);
      case 'sedang':
        return const Color(0xFFFFFBEB);
      case 'rendah':
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _getPriorityBorder(String priority) {
    switch (priority.toLowerCase()) {
      case 'tinggi':
        return const Color(0xFFFECACA);
      case 'sedang':
        return const Color(0xFFFDE68A);
      case 'rendah':
      default:
        return const Color(0xFFBFDBFE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _task.isCompleted;
    final priorityColor = _getPriorityColor(_task.priority);
    final priorityBg = _getPriorityBg(_task.priority);
    final priorityBorder = _getPriorityBorder(_task.priority);

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
          onPressed: () => Navigator.pop(context, _task),
        ),
        title: const Text(
          'Detail Tugas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Tugas',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF2563EB),
                size: 19,
              ),
            ),
            onPressed: _openEditTask,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card: Title, Course, and Badges
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                    // Badges row with Wrap to guarantee NO overflow
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Course Badge
                        if (_task.course.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school_rounded,
                                  size: 12,
                                  color: Color(0xFF475569),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _task.course,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: priorityBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: priorityBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flag_rounded,
                                size: 12,
                                color: priorityColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _task.priority,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: priorityColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFFEDD5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFFDBA74),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.schedule_rounded,
                                size: 12,
                                color: isCompleted
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFC2410C),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCompleted ? 'Selesai' : 'Belum Selesai',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFC2410C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Task Title
                    Text(
                      _task.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                        letterSpacing: -0.4,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Section: Rincian Tenggat & Urgensi
              const Text(
                'Informasi Tugas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Deadline Item
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Color(0xFF2563EB),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tenggat Waktu (Deadline)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _task.deadline,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),

                    // Priority Item
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: priorityBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.flag_rounded,
                              color: priorityColor,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tingkat Prioritas',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Prioritas ${_task.priority}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: priorityColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),

                    // Status Item
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFFEDD5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.schedule_rounded,
                              color: isCompleted
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFEA580C),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status Pengerjaan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCompleted
                                      ? 'Selesai Dikerjakan'
                                      : 'Belum Selesai (Dalam Proses)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isCompleted
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFEA580C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Section: Deskripsi Tugas
              const Text(
                'Deskripsi Tugas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: Text(
                  _task.description.isEmpty
                      ? 'Tidak ada rincian atau catatan khusus untuk tugas ini.'
                      : _task.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                    height: 1.6,
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Section: Action Buttons (Responsive Layout)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 340;

                  Widget editButton = OutlinedButton.icon(
                    onPressed: _openEditTask,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      'Edit Tugas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(
                        color: Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );

                  Widget completeButton = ElevatedButton.icon(
                    onPressed: _toggleTaskStatus,
                    icon: Icon(
                      isCompleted
                          ? Icons.undo_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isCompleted ? 'Tandai Belum' : 'Tandai Selesai',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0x22000000),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        editButton,
                        const SizedBox(height: 10),
                        completeButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: editButton),
                      const SizedBox(width: 12),
                      Expanded(child: completeButton),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
