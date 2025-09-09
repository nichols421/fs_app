import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/real_nfc_service.dart'; // Make sure this import is correct
import 'providers/checklist_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
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
        // Use RealNFCService for actual RFID read/write
        Provider<RealNFCService>(create: (_) => RealNFCService()),
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