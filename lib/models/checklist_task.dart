class ChecklistTask {
  final String id;
  final String equipmentId;
  final String category;
  final String task;
  final bool isCompleted;
  final String? notes;
  final String? photoPath;
  final String? completedBy;
  final DateTime? completedAt;

  ChecklistTask({
    required this.id,
    required this.equipmentId,
    required this.category,
    required this.task,
    required this.isCompleted,
    this.notes,
    this.photoPath,
    this.completedBy,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'category': category,
      'task': task,
      'isCompleted': isCompleted ? 1 : 0,
      'notes': notes,
      'photoPath': photoPath,
      'completedBy': completedBy,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'category': category,
      'task': task,
      'isCompleted': isCompleted,
      'notes': notes,
      'photoPath': photoPath,
      'completedBy': completedBy,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ChecklistTask.fromMap(Map<String, dynamic> map) {
    return ChecklistTask(
      id: map['id'],
      equipmentId: map['equipmentId'],
      category: map['category'],
      task: map['task'],
      isCompleted: map['isCompleted'] == 1,
      notes: map['notes'],
      photoPath: map['photoPath'],
      completedBy: map['completedBy'],
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }

  factory ChecklistTask.fromJson(Map<String, dynamic> json) {
    return ChecklistTask(
      id: json['id'],
      equipmentId: json['equipmentId'],
      category: json['category'],
      task: json['task'],
      isCompleted: json['isCompleted'],
      notes: json['notes'],
      photoPath: json['photoPath'],
      completedBy: json['completedBy'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  ChecklistTask copyWith({
    String? id,
    String? equipmentId,
    String? category,
    String? task,
    bool? isCompleted,
    String? notes,
    String? photoPath,
    String? completedBy,
    DateTime? completedAt,
  }) {
    return ChecklistTask(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      category: category ?? this.category,
      task: task ?? this.task,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      completedBy: completedBy ?? this.completedBy,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}