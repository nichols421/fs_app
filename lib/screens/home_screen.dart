import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
// Update this import to match your chosen service in main.dart
import '../services/nfc_service.dart'; // or simple_nfc_service.dart
import '../providers/checklist_provider.dart';
import '../models/checklist_data.dart';
import 'equipment_setup_screen.dart';
import 'checklist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isScanning = false;
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
  }

  Future<void> _checkNFCAvailability() async {
    final nfcService = Provider.of<NFCService>(context, listen: false);
    final available = await nfcService.isNFCAvailable();
    setState(() {
      _nfcAvailable = available;
    });
  }

  Future<void> _scanRFID() async {
    if (!_nfcAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NFC is not available on this device'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    final nfcService = Provider.of<NFCService>(context, listen: false);
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);

    try {
      // Show scanning dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Hold your device near the RFID tag...'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  nfcService.stopSession();
                  Navigator.of(context).pop();
                  setState(() {
                    _isScanning = false;
                  });
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );

      final result = await nfcService.readFromTag();

      // Close scanning dialog
      Navigator.of(context).pop();

      setState(() {
        _isScanning = false;
      });

      if (result != null) {
        if (result.equipment == null) {
          // Empty tag - go to equipment setup
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empty tag detected - Setting up new equipment'),
              backgroundColor: Colors.blue,
            ),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const EquipmentSetupScreen(),
            ),
          );
        } else {
          // Load existing checklist data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded equipment: ${result.equipment!.partName}'),
              backgroundColor: Colors.green,
            ),
          );
          checklistProvider.loadChecklistData(result);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ChecklistScreen(),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to read RFID tag - please try again'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close scanning dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning RFID: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Field Services'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => authService.logout(),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.contactless,
                        size: 80,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome, ${authService.currentUser}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan an RFID tag to begin or continue maintenance work',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _isScanning ? null : _scanRFID,
                        icon: _isScanning
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Icon(Icons.nfc),
                        label: Text(_isScanning ? 'Scanning...' : 'Scan RFID Tag'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!_nfcAvailable)
                Card(
                  color: Colors.orange.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'NFC is not available on this device. Please ensure NFC is enabled in settings.',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                color: Colors.green.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Instructions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Hold your device near an RFID tag\n• If tag is empty, you\'ll scan a barcode for setup\n• If tag has data, you\'ll continue existing work\n• Progress is automatically saved to the tag',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}