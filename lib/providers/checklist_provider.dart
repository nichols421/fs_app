import 'package:flutter/foundation.dart';
import '../models/equipment.dart';
import '../models/checklist_task.dart';
import '../models/checklist_data.dart';
import 'package:uuid/uuid.dart';

class ChecklistProvider extends ChangeNotifier {
  Equipment? _currentEquipment;
  List<ChecklistTask> _tasks = [];
  bool _isCompleted = false;
  String? _signature;

  // Hardcoded customers and parts for POC
  final List<Map<String, String>> customers = [
    {'number': '123', 'name': 'Company A'},
    {'number': '345', 'name': 'Company B'},
  ];

  final List<Map<String, String>> parts = [
    {'number': 'AAA', 'name': 'Part A'},
    {'number': 'BBB', 'name': 'Part B'},
  ];

  // Hardcoded checklist from the document
  final List<Map<String, dynamic>> _checklistTemplate = [
    {
      'category': 'Initial Inspection',
      'tasks': [
        'Inspect the equipment for any visible signs of damage or wear.',
        'Check for any loose or missing parts.',
        'Ensure all safety guards and covers are in place.',
        'Verify that the equipment is clean and free of debris.',
        'Remove old maintenance stickers!',
      ]
    },
    {
      'category': 'Power On',
      'tasks': [
        'Ensure the power supply is stable and within the required specifications.',
        'Turn on the equipment and verify that it powers up correctly.',
        'Listen for any unusual noises during startup.',
        'Check all control panels and indicators for proper operation.',
      ]
    },
    {
      'category': 'Equipment Specific For [Type of Equipment]',
      'tasks': [
        'Perform operational checks specific to the equipment type and/or the required maintenance tasks.',
        'Verify firmware and software version.',
        'Calibrate the equipment if necessary.',
        'Inspect and replace any filters, belts, or other consumable parts.',
        'Lubricate moving parts as required.',
        'Conduct any manufacturer-recommended diagnostic tests.',
      ]
    },
    {
      'category': 'Close Out',
      'tasks': [
        'Ensure the maintenance sticker is correct!',
        'Ensure all maintenance tools and materials are removed from the work area.',
        'Verify that the equipment is in a safe and operational state.',
      ]
    },
  ];

  Equipment? get currentEquipment => _currentEquipment;
  List<ChecklistTask> get tasks => _tasks;
  bool get isCompleted => _isCompleted;
  String? get signature => _signature;

  void loadChecklistData(ChecklistData data) {
    _currentEquipment = data.equipment;
    _tasks = data.tasks;
    _isCompleted = data.isCompleted;
    _signature = data.signature;
    notifyListeners();
  }

  void createNewEquipment(String serialNumber, String partNumber, String customerNumber) {
    final selectedPart = parts.firstWhere((part) => part['number'] == partNumber);
    final selectedCustomer = customers.firstWhere((customer) => customer['number'] == customerNumber);

    final equipmentId = const Uuid().v4();
    _currentEquipment = Equipment(
      id: equipmentId,
      serialNumber: serialNumber,
      partNumber: partNumber,
      partName: selectedPart['name']!,
      customerNumber: customerNumber,
      customerName: selectedCustomer['name']!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Create tasks from template
    _tasks = [];
    for (var category in _checklistTemplate) {
      for (var task in category['tasks']) {
        _tasks.add(ChecklistTask(
          id: const Uuid().v4(),
          equipmentId: equipmentId,
          category: category['category'],
          task: task,
          isCompleted: false,
        ));
      }
    }

    _isCompleted = false;
    _signature = null;
    notifyListeners();
  }

  void updateTask(String taskId, {
    bool? isCompleted,
    String? notes,
    String? photoPath,
    String? completedBy,
  }) {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        isCompleted: isCompleted ?? _tasks[taskIndex].isCompleted,
        notes: notes ?? _tasks[taskIndex].notes,
        photoPath: photoPath ?? _tasks[taskIndex].photoPath,
        completedBy: completedBy ?? _tasks[taskIndex].completedBy,
        completedAt: (isCompleted == true) ? DateTime.now() : _tasks[taskIndex].completedAt,
      );
      notifyListeners();
    }
  }

  void setSignature(String signatureData) {
    _signature = signatureData;
    _isCompleted = true;
    notifyListeners();
  }

  ChecklistData getCurrentData() {
    return ChecklistData(
      equipment: _currentEquipment,
      tasks: _tasks,
      isCompleted: _isCompleted,
      signature: _signature,
      lastUpdated: DateTime.now(),
    );
  }

  void clearData() {
    _currentEquipment = null;
    _tasks = [];
    _isCompleted = false;
    _signature = null;
    notifyListeners();
  }

  double get progressPercentage {
    if (_tasks.isEmpty) return 0.0;
    final completedTasks = _tasks.where((task) => task.isCompleted).length;
    return completedTasks / _tasks.length;
  }

  List<String> get categories {
    return _tasks.map((task) => task.category).toSet().toList();
  }

  List<ChecklistTask> getTasksForCategory(String category) {
    return _tasks.where((task) => task.category == category).toList();
  }
}