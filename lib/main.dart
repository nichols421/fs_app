import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
// Choose ONE of these NFC services based on your testing needs:
import 'services/nfc_service.dart'; // Full NFC service (requires real NFC hardware)
// import 'services/simple_nfc_service.dart'; // Alternative simple service
import 'providers/checklist_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService().initDatabase();

  runApp(const FieldServicesApp());
}

class FieldServicesApp extends StatelessWidget {
  const FieldServicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ChecklistProvider()),
        Provider(create: (_) => DatabaseService()),

        // Choose ONE NFC service for your testing:

        // Option 1: Full NFC Service (for real RFID testing)
        Provider(create: (_) => NFCService()),

        // Option 2: Mock NFC Service (for testing without hardware)
        // Provider(create: (_) => MockNFCService()),

        // Option 3: Local Storage Service (uses SharedPreferences instead of NFC)
        // Provider(create: (_) => LocalStorageNFCService()),
      ],
      child: MaterialApp(
        title: 'Field Services',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            return authService.isLoggedIn ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}