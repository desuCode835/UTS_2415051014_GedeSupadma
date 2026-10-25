import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String? course;
  final String deadline;
  final String priority;
  final String status;
  final String? description;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onToggleCompletion;
  final bool isToggling;

  const TaskCard({
    super.key,
    required this.title,
    this.course,
    required this.deadline,
    required this.priority,
    required this.status,
    this.description,
    this.onTap,
    this.margin,
    this.onToggleCompletion,
    this.isToggling = false,
  });

  bool get isCompleted => status.toLowerCase() == 'selesai';

  Color _getPriorityColor() {
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

  Color _getPriorityBg() {
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

  Color _getPriorityBorder() {
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

  IconData _getPriorityIcon() {
    switch (priority.toLowerCase()) {
      case 'tinggi':
        return Icons.arrow_upward_rounded;
      case 'sedang':
        return Icons.remove_rounded;
      case 'rendah':
      default:
        return Icons.arrow_downward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFE2E8F0),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Meta: Course Pill and Status Badge (Wrap ensures no overflow)
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (course != null && course!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
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
                                Icons.bookmark_border_rounded,
                                size: 12,
                                color: Color(0xFF475569),
                              ),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  course!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Modern Status Badge
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
                              status,
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
                ),

                const SizedBox(height: 10),

                // Main Row: Completion Circle Indicator + Title & Description
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: (isToggling || onToggleCompletion == null)
                          ? null
                          : onToggleCompletion,
                      behavior: HitTestBehavior.opaque,
                      child: Tooltip(
                        message: isCompleted
                            ? 'Tandai belum selesai'
                            : 'Tandai selesai',
                        child: Container(
                          margin: const EdgeInsets.only(top: 2, right: 10),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? const Color(0xFF16A34A)
                                : Colors.transparent,
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF94A3B8),
                              width: 1.8,
                            ),
                          ),
                          child: isToggling
                              ? const Padding(
                                  padding: EdgeInsets.all(3),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF16A34A),
                                    ),
                                  ),
                                )
                              : (isCompleted
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isCompleted
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: const Color(0xFF94A3B8),
                              decorationThickness: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (description != null &&
                              description!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              description!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.35,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),

                // Bottom Bar: Deadline & Priority Tag (Wrap ensures no overflow)
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              deadline,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityBg(),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getPriorityBorder(),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPriorityIcon(),
                              size: 12,
                              color: _getPriorityColor(),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              priority,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _getPriorityColor(),
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
        ),
      ),
    );
  }
}
