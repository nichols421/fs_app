import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/checklist_provider.dart';
import '../services/auth_service.dart';
// Update this import to match your chosen service in main.dart
import '../services/nfc_service.dart'; // or simple_nfc_service.dart
import 'task_detail_screen.dart';
import 'signature_screen.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  bool _isSaving = false;

  Future<void> _saveProgress() async {
    setState(() {
      _isSaving = true;
    });

    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    final nfcService = Provider.of<NFCService>(context, listen: false);

    try {
      // Show saving dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Hold your device near the RFID tag to save...'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  nfcService.stopSession();
                  Navigator.of(context).pop();
                  setState(() {
                    _isSaving = false;
                  });
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );

      final currentData = checklistProvider.getCurrentData();
      final success = await nfcService.writeToTag(currentData);

      // Close saving dialog
      Navigator.of(context).pop();

      setState(() {
        _isSaving = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress saved to RFID tag successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save progress to RFID tag'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close saving dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving to RFID: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeChecklist() async {
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);

    // Check if all tasks are completed
    final incompleteTasks = checklistProvider.tasks.where((task) => !task.isCompleted).toList();

    if (incompleteTasks.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Tasks'),
          content: Text(
            'You have ${incompleteTasks.length} incomplete tasks. Please complete all tasks before signing off.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to signature screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SignatureScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChecklistProvider>(
      builder: (context, checklistProvider, child) {
        final equipment = checklistProvider.currentEquipment;
        final categories = checklistProvider.categories;
        final progressPercentage = checklistProvider.progressPercentage;

        if (equipment == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Checklist'),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text('No equipment data available'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Maintenance Checklist'),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: _isSaving ? null : _saveProgress,
                icon: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.save),
                tooltip: 'Save to RFID Tag',
              ),
            ],
          ),
          body: Column(
            children: [
              // Equipment Info Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.precision_manufacturing, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${equipment.partNumber} - ${equipment.partName}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.qr_code, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text('Serial: ${equipment.serialNumber}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text('Customer: ${equipment.customerName}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progressPercentage,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progressPercentage * 100).round()}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Categories List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final tasks = checklistProvider.getTasksForCategory(category);
                    final completedTasks = tasks.where((task) => task.isCompleted).length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('$completedTasks of ${tasks.length} completed'),
                        leading: CircleAvatar(
                          backgroundColor: completedTasks == tasks.length
                              ? Colors.green
                              : Colors.orange,
                          child: Text(
                            '$completedTasks/${tasks.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        children: tasks.map((task) {
                          return ListTile(
                            leading: Icon(
                              task.isCompleted
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: task.isCompleted ? Colors.green : Colors.grey,
                            ),
                            title: Text(task.task),
                            subtitle: task.notes != null
                                ? Text(
                              task.notes!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (task.photoPath != null)
                                  Icon(
                                    Icons.photo,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailScreen(task: task),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _saveProgress,
                        icon: _isSaving
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.save),
                        label: const Text('Save Progress'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _completeChecklist,
                        icon: const Icon(Icons.assignment_turned_in),
                        label: const Text('Complete & Sign'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Technician: ${Provider.of<AuthService>(context).currentUser}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}