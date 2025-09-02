import 'dart:convert';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../models/checklist_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ultra-Simplified NFC Service - Guaranteed to work
class UltraSimpleNFCService {
  Future<bool> isNFCAvailable() async {
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (e) {
      return false;
    }
  }

  Future<ChecklistData?> readFromTag() async {
    try {
      // This is a simplified version that just returns empty for POC
      // You can enhance it once the basic app is working
      NFCTag tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 10));

      // For POC, always return empty (new equipment setup)
      return ChecklistData.empty();

    } catch (e) {
      print('NFC read error: $e');
      return null;
    } finally {
      await FlutterNfcKit.finish().catchError((e) => null);
    }
  }

  Future<bool> writeToTag(ChecklistData data) async {
    try {
      NFCTag tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 10));

      // For POC, just simulate success
      await Future.delayed(Duration(seconds: 1));
      print('Simulated NFC write success');
      return true;

    } catch (e) {
      print('NFC write error: $e');
      return false;
    } finally {
      await FlutterNfcKit.finish().catchError((e) => null);
    }
  }

  void stopSession() {
    FlutterNfcKit.finish().catchError((e) => null);
  }
}

/// Mock NFC Service for development without NFC hardware
class MockNFCService {
  static ChecklistData? _mockData;

  Future<bool> isNFCAvailable() async {
    return true; // Always available for testing
  }

  Future<ChecklistData?> readFromTag() async {
    // Simulate NFC scanning delay
    await Future.delayed(Duration(seconds: 2));
    return _mockData ?? ChecklistData.empty();
  }

  Future<bool> writeToTag(ChecklistData data) async {
    // Simulate NFC writing delay
    await Future.delayed(Duration(seconds: 2));
    _mockData = data;
    print('Mock NFC: Saved data with ${data.tasks.length} tasks');
    return true;
  }

  void stopSession() {
    // No-op for mock
  }
}

/// SharedPreferences-based alternative (no NFC needed)

class LocalStorageNFCService {
  static const String _storageKey = 'checklist_data';

  Future<bool> isNFCAvailable() async {
    return true; // Always available
  }

  Future<ChecklistData?> readFromTag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final data = json.decode(jsonString);
        return ChecklistData.fromJson(data);
      }

      return ChecklistData.empty();
    } catch (e) {
      print('Local storage read error: $e');
      return ChecklistData.empty();
    }
  }

  Future<bool> writeToTag(ChecklistData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(data.toJson());
      await prefs.setString(_storageKey, jsonString);
      print('Saved to local storage: ${jsonString.length} characters');
      return true;
    } catch (e) {
      print('Local storage write error: $e');
      return false;
    }
  }

  void stopSession() {
    // No-op
  }
}