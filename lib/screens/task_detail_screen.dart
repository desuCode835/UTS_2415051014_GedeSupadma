import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../data/sample_tasks.dart';
import '../providers/task_provider.dart';
import 'edit_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task? task;
  final void Function(Task updatedTask)? onTaskUpdated;
  final void Function(String taskId)? onTaskDeleted;

  const TaskDetailScreen({
    super.key,
    this.task,
    this.onTaskUpdated,
    this.onTaskDeleted,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  bool _isTogglingStatus = false;
  bool _isTogglingArchive = false;
  bool _isDeleting = false;

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
    final updated = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => EditTaskScreen(task: _task)),
    );

    if (updated != null && mounted) {
      setState(() {
        _task = updated;
      });
      widget.onTaskUpdated?.call(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Perubahan tugas "${updated.title}" berhasil disimpan!',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _toggleTaskStatus() async {
    if (_isTogglingStatus) return;

    setState(() {
      _isTogglingStatus = true;
    });

    try {
      TaskProvider? provider;
      try {
        provider = Provider.of<TaskProvider>(context, listen: false);
      } catch (_) {
        provider = null;
      }

      Task savedResult;
      if (provider != null) {
        // Alur Provider -> Repository -> Service -> Supabase
        savedResult = await provider.toggleTaskCompletion(_task);
      } else {
        // Fallback saat dijalankan tanpa provider (misal unit widget test)
        savedResult = _task.copyWith(isCompleted: !_task.isCompleted);
      }

      if (mounted) {
        setState(() {
          _task = savedResult;
          _isTogglingStatus = false;
        });

        widget.onTaskUpdated?.call(savedResult);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedResult.isCompleted
                  ? 'Tugas ditandai selesai.'
                  : 'Tugas ditandai belum selesai.',
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTogglingStatus = false;
        });

        // Error Supabase ditampilkan dengan jelas dan tidak dianggap sebagai keberhasilan
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
    }
  }

  Future<void> _toggleArchiveStatus() async {
    if (_isTogglingArchive) return;

    setState(() {
      _isTogglingArchive = true;
    });

    try {
      TaskProvider? provider;
      try {
        provider = Provider.of<TaskProvider>(context, listen: false);
      } catch (_) {
        provider = null;
      }

      Task savedResult;
      if (provider != null) {
        savedResult = await provider.toggleTaskArchive(_task);
      } else {
        savedResult = _task.copyWith(isArchived: !_task.isArchived);
      }

      if (mounted) {
        setState(() {
          _task = savedResult;
          _isTogglingArchive = false;
        });

        widget.onTaskUpdated?.call(savedResult);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedResult.isArchived
                  ? 'Tugas "${savedResult.title}" berhasil diarsipkan.'
                  : 'Tugas "${savedResult.title}" berhasil dipulihkan dari arsip.',
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTogglingArchive = false;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status arsip tugas: $e'),
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

  /// Menampilkan dialog konfirmasi sebelum menghapus tugas.
  /// Batal: menutup dialog tanpa mengubah database atau state.
  /// Hapus: memanggil _deleteTask() untuk menghapus record dari Supabase.
  Future<void> _confirmDeleteTask() async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Hapus Tugas?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          content: Text.rich(
            TextSpan(
              text: 'Apakah Anda yakin ingin menghapus tugas ',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '"${_task.title}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const TextSpan(
                  text: '? Tindakan ini akan menghapus tugas secara permanen dan tidak dapat dibatalkan.',
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Hapus',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _deleteTask();
    }
  }

  /// Menjalankan penghapusan tugas melalui alur UI -> Provider -> Repository -> Service -> Supabase.
  /// Mencegah permintaan penghapusan berulang dan hanya menutup halaman jika database berhasil.
  Future<void> _deleteTask() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      TaskProvider? provider;
      try {
        provider = Provider.of<TaskProvider>(context, listen: false);
      } catch (_) {
        provider = null;
      }

      if (provider != null) {
        await provider.deleteTask(_task.id);
      }

      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        widget.onTaskDeleted?.call(_task.id);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tugas "${_task.title}" berhasil dihapus.'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Menutup halaman detail dan kembali ke halaman sebelumnya
        // Tanpa nilai bool agar kompatibel dengan Route bertipe Task?
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus tugas: $e'),
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

    return PopScope(
      canPop: !_isDeleting,
      child: Scaffold(
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
            onPressed: _isDeleting ? null : () => Navigator.pop(context, _task),
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
              tooltip: _task.isArchived ? 'Pulihkan Tugas' : 'Arsipkan Tugas',
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _task.isArchived
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isTogglingArchive
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2563EB),
                          ),
                        ),
                      )
                    : Icon(
                        _task.isArchived
                            ? Icons.unarchive_rounded
                            : Icons.archive_outlined,
                        color: _task.isArchived
                            ? const Color(0xFFD97706)
                            : const Color(0xFF334155),
                        size: 19,
                      ),
              ),
              onPressed: _isTogglingArchive ? null : _toggleArchiveStatus,
            ),
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
              onPressed:
                  (_isDeleting || _isTogglingStatus || _isTogglingArchive)
                  ? null
                  : _openEditTask,
            ),
            IconButton(
              key: const ValueKey('delete_task_button'),
              tooltip: 'Hapus Tugas',
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFDC2626),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 19,
                      ),
              ),
              onPressed:
                  (_isDeleting || _isTogglingStatus || _isTogglingArchive)
                  ? null
                  : _confirmDeleteTask,
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
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
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
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
                          if (_task.courseCategory != null &&
                              _task.courseCategory!.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFDDD6FE),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.school_outlined,
                                    size: 12,
                                    color: Color(0xFF7C3AED),
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      _task.courseCategory!.trim(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF7C3AED),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_task.isArchived)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                  width: 0.8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.archive_outlined,
                                    size: 12,
                                    color: Color(0xFFB45309),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Diarsipkan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
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
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
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
                      // Course Category Item
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: Color(0xFF7C3AED),
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mata Kuliah / Kategori',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _task.displayCourseCategory,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          (_task.courseCategory != null &&
                                              _task.courseCategory!
                                                  .trim()
                                                  .isNotEmpty)
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFF94A3B8),
                                      fontStyle:
                                          (_task.courseCategory != null &&
                                              _task.courseCategory!
                                                  .trim()
                                                  .isNotEmpty)
                                          ? FontStyle.normal
                                          : FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

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
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
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
                      onPressed: _isTogglingStatus ? null : _toggleTaskStatus,
                      icon: _isTogglingStatus
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              isCompleted
                                  ? Icons.undo_rounded
                                  : Icons.check_circle_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _isTogglingStatus
                            ? 'Menyimpan...'
                            : (isCompleted ? 'Tandai Belum' : 'Tandai Selesai'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF16A34A),
                        disabledBackgroundColor: const Color(0xFF64748B),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white70,
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

                    Widget archiveButton = OutlinedButton.icon(
                      onPressed: _isTogglingArchive
                          ? null
                          : _toggleArchiveStatus,
                      icon: _isTogglingArchive
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2563EB),
                                ),
                              ),
                            )
                          : Icon(
                              _task.isArchived
                                  ? Icons.unarchive_rounded
                                  : Icons.archive_outlined,
                              size: 18,
                              color: _task.isArchived
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF475569),
                            ),
                      label: Text(
                        _isTogglingArchive
                            ? 'Menyimpan...'
                            : (_task.isArchived
                                  ? 'Pulihkan Tugas'
                                  : 'Arsipkan Tugas'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _task.isArchived
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF0F172A),
                        side: BorderSide(
                          color: _task.isArchived
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFFCBD5E1),
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

                    Widget deleteButton = OutlinedButton.icon(
                      key: const ValueKey('delete_task_bottom_button'),
                      onPressed:
                          (_isDeleting ||
                              _isTogglingStatus ||
                              _isTogglingArchive)
                          ? null
                          : _confirmDeleteTask,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFDC2626),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Color(0xFFDC2626),
                            ),
                      label: Text(
                        _isDeleting ? 'Menghapus...' : 'Hapus Tugas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(
                          color: Color(0xFFFECACA),
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

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          editButton,
                          const SizedBox(height: 10),
                          archiveButton,
                          const SizedBox(height: 10),
                          completeButton,
                          const SizedBox(height: 10),
                          deleteButton,
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: editButton),
                            const SizedBox(width: 12),
                            Expanded(child: archiveButton),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: completeButton),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: deleteButton),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
