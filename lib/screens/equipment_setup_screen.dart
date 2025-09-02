import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/checklist_provider.dart';
import 'checklist_screen.dart';

class EquipmentSetupScreen extends StatefulWidget {
  const EquipmentSetupScreen({super.key});

  @override
  State<EquipmentSetupScreen> createState() => _EquipmentSetupScreenState();
}

class _EquipmentSetupScreenState extends State<EquipmentSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialController = TextEditingController();

  String? _selectedPartNumber;
  String? _selectedCustomerNumber;
  bool _showBarcodeScanner = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _serialController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onBarcodeScanned(BarcodeCapture capture) {
    final barcode = capture.barcodes.first;
    if (barcode.rawValue != null) {
      setState(() {
        _serialController.text = barcode.rawValue!;
        _showBarcodeScanner = false;
      });
    }
  }

  void _setupEquipment() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPartNumber == null || _selectedCustomerNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both part number and customer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    checklistProvider.createNewEquipment(
      _serialController.text.trim(),
      _selectedPartNumber!,
      _selectedCustomerNumber!,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ChecklistScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checklistProvider = Provider.of<ChecklistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Setup'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: _showBarcodeScanner ? _buildBarcodeScanner() : _buildSetupForm(checklistProvider),
    );
  }

  Widget _buildBarcodeScanner() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeScanned,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Position the barcode within the frame to scan',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showBarcodeScanner = false;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _scannerController?.toggleTorch();
                      },
                      child: const Text('Toggle Flash'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSetupForm(ChecklistProvider checklistProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Serial Number',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _serialController,
                            decoration: InputDecoration(
                              labelText: 'Serial Number',
                              hintText: 'Enter or scan serial number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.qr_code),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter serial number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () {
                            setState(() {
                              _showBarcodeScanner = true;
                            });
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          tooltip: 'Scan Barcode',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Part Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPartNumber,
                      decoration: InputDecoration(
                        labelText: 'Part Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.precision_manufacturing),
                      ),
                      items: checklistProvider.parts.map((part) {
                        return DropdownMenuItem<String>(
                          value: part['number'],
                          child: Text('${part['number']} - ${part['name']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPartNumber = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a part number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCustomerNumber,
                      decoration: InputDecoration(
                        labelText: 'Customer',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.business),
                      ),
                      items: checklistProvider.customers.map((customer) {
                        return DropdownMenuItem<String>(
                          value: customer['number'],
                          child: Text('${customer['number']} - ${customer['name']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomerNumber = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a customer';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _setupEquipment,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue to Checklist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}