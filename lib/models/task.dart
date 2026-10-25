class Task {
  final String id;
  final String title;
  final String description;
  final String? courseCategory;
  final String deadline;
  final String priority;
  final bool isCompleted;
  final bool isArchived;
  final String? userId;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    this.courseCategory,
    required this.deadline,
    required this.priority,
    required this.isCompleted,
    this.isArchived = false,
    this.userId,
  });

  String get displayCourseCategory =>
      (courseCategory != null && courseCategory!.trim().isNotEmpty)
          ? courseCategory!.trim()
          : 'Belum ditentukan';

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? courseCategory,
    String? deadline,
    String? priority,
    bool? isCompleted,
    bool? isArchived,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseCategory: courseCategory ?? this.courseCategory,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      isArchived: isArchived ?? this.isArchived,
      userId: userId ?? this.userId,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: (json['description'] ?? '') as String,
      courseCategory: json['course_category']?.toString() ??
          json['courseCategory']?.toString(),
      deadline: json['deadline'] as String,
      priority: (json['priority'] ?? 'Sedang') as String,
      isCompleted: json['is_completed'] == true ||
          json['isCompleted'] == true ||
          json['is_completed'] == 1 ||
          json['is_completed'] == 'true',
      isArchived: json['is_archived'] == true ||
          json['isArchived'] == true ||
          json['is_archived'] == 1 ||
          json['is_archived'] == 'true',
      userId: json['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline,
      'priority': priority,
      'isCompleted': isCompleted,
      'isArchived': isArchived,
    };
    if (courseCategory != null && courseCategory!.isNotEmpty) {
      map['course_category'] = courseCategory;
    }
    if (userId != null) {
      map['user_id'] = userId;
    }
    return map;
  }

  /// Format data khusus untuk payload tabel 'tasks' di Supabase
  Map<String, dynamic> toSupabaseMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'course_category': courseCategory,
      'deadline': deadline,
      'priority': priority,
      'is_completed': isCompleted,
      'is_archived': isArchived,
    };
    if (userId != null) {
      map['user_id'] = userId;
    }
    return map;
  }
}


