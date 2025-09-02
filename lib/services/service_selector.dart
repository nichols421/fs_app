// Service Selector - Choose which NFC service to use for your POC
// Uncomment the service you want to use in main.dart

import 'nfc_service.dart'; // Full NFC with ndef library
// import 'simple_nfc_service.dart'; // Alternative implementations

// Option 1: Full NFC Service (requires ndef library)
// Use this if your build works with the ndef dependency
typedef SelectedNFCService = NFCService;

// Option 2: Ultra Simple NFC Service (basic NFC without ndef)
// Uncomment this line if you have ndef library issues:
// typedef SelectedNFCService = UltraSimpleNFCService;

// Option 3: Mock NFC Service (no hardware needed)
// Uncomment this line for development without NFC:
// typedef SelectedNFCService = MockNFCService;

// Option 4: Local Storage Service (SharedPreferences)
// Uncomment this line to use local storage instead of NFC:
// typedef SelectedNFCService = LocalStorageNFCService;

// Usage in main.dart:
// Provider(create: (_) => SelectedNFCService()),