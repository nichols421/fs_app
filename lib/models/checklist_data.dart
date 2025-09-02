import 'equipment.dart';
import 'checklist_task.dart';

class ChecklistData {
  final Equipment? equipment;
  final List<ChecklistTask> tasks;
  final bool isCompleted;
  final String? signature;
  final DateTime lastUpdated;

  ChecklistData({
    this.equipment,
    required this.tasks,
    required this.isCompleted,
    this.signature,
    required this.lastUpdated,
  });

  factory ChecklistData.empty() {
    return ChecklistData(
      tasks: [],
      isCompleted: false,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'equipment': equipment?.toMap(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'isCompleted': isCompleted,
      'signature': signature,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ChecklistData.fromJson(Map<String, dynamic> json) {
    return ChecklistData(
      equipment: json['equipment'] != null
          ? Equipment.fromMap(json['equipment'])
          : null,
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((task) => ChecklistTask.fromJson(task))
          .toList(),
      isCompleted: json['isCompleted'] ?? false,
      signature: json['signature'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  ChecklistData copyWith({
    Equipment? equipment,
    List<ChecklistTask>? tasks,
    bool? isCompleted,
    String? signature,
    DateTime? lastUpdated,
  }) {
    return ChecklistData(
      equipment: equipment ?? this.equipment,
      tasks: tasks ?? this.tasks,
      isCompleted: isCompleted ?? this.isCompleted,
      signature: signature ?? this.signature,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  double get progressPercentage {
    if (tasks.isEmpty) return 0.0;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    return completedTasks / tasks.length;
  }
}