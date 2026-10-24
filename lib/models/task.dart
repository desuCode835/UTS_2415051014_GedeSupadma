class TaskItem {
  final String id;
  final String title;
  final String course;
  final String deadline;
  final String priority;
  final String status;
  final String description;

  const TaskItem({
    required this.id,
    required this.title,
    this.course = '',
    required this.deadline,
    this.priority = 'Sedang',
    this.status = 'Belum Selesai',
    this.description = '',
  });

  bool get isCompleted => status.toLowerCase() == 'selesai';

  TaskItem copyWith({
    String? id,
    String? title,
    String? course,
    String? deadline,
    String? priority,
    String? status,
    String? description,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      course: course ?? this.course,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'course': course,
      'deadline': deadline,
      'priority': priority,
      'status': status,
      'description': description,
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      course: map['course'] as String? ?? '',
      deadline: map['deadline'] as String? ?? '',
      priority: map['priority'] as String? ?? 'Sedang',
      status: map['status'] as String? ?? 'Belum Selesai',
      description: map['description'] as String? ?? '',
    );
  }
}

typedef Task = TaskItem;
