import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../providers/checklist_provider.dart';
import '../services/auth_service.dart';
// Update this import to match your chosen service in main.dart
import '../services/nfc_service.dart'; // or simple_nfc_service.dart

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  late SignatureController _signatureController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  void _clearSignature() {
    _signatureController.clear();
  }

  Future<void> _saveSignatureAndComplete() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a signature'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Get signature as PNG bytes
      final Uint8List? signatureBytes = await _signatureController.toPngBytes();

      if (signatureBytes != null) {
        // Convert to base64 for storage
        final String signatureBase64 = base64Encode(signatureBytes);

        // Update checklist with signature
        final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
        checklistProvider.setSignature(signatureBase64);

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
                const Text('Hold your device near the RFID tag to complete...'),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    final nfcService = Provider.of<NFCService>(context, listen: false);
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

        // Save final data to RFID tag
        final nfcService = Provider.of<NFCService>(context, listen: false);
        final finalData = checklistProvider.getCurrentData();
        final success = await nfcService.writeToTag(finalData);

        // Close saving dialog
        Navigator.of(context).pop();

        setState(() {
          _isSaving = false;
        });

        if (success) {
          _showCompletionDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save to RFID tag'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
          content: Text('Error saving signature: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Checklist Completed!'),
          ],
        ),
        content: const Text(
          'The maintenance checklist has been completed and saved to the RFID tag successfully. The equipment is ready for operation.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Clear the checklist data
              final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
              checklistProvider.clearData();

              // Navigate back to home screen
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Return to Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final equipment = checklistProvider.currentEquipment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Signature'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Equipment Summary
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maintenance Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (equipment != null) ...[
                    _buildInfoRow('Equipment:', '${equipment.partName} (${equipment.partNumber})'),
                    _buildInfoRow('Serial Number:', equipment.serialNumber),
                    _buildInfoRow('Customer:', equipment.customerName),
                  ],
                  _buildInfoRow('Technician:', authService.currentUser ?? 'Unknown'),
                  _buildInfoRow('Date:', DateTime.now().toString().split(' ')[0]),
                  _buildInfoRow('Tasks Completed:', '${checklistProvider.tasks.where((t) => t.isCompleted).length} of ${checklistProvider.tasks.length}'),
                ],
              ),
            ),
          ),

          // Signature Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Please sign below to confirm that all maintenance tasks have been completed according to specifications.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Signature Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Technician Signature',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _clearSignature,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Signature(
                            controller: _signatureController,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'By signing, you certify that all maintenance tasks have been completed and the equipment is safe for operation.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSignatureAndComplete,
                icon: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.assignment_turned_in),
                label: Text(_isSaving ? 'Completing...' : 'Complete Maintenance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}