// lib/services/working_nfc_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../models/checklist_data.dart';

class WorkingNFCService {
  Future<bool> isNFCAvailable() async {
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (e) {
      print('NFC availability check error: $e');
      return false;
    }
  }

  Future<ChecklistData?> readFromTag() async {
    try {
      // Start NFC session
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Scan your tag",
      );

      print('Tag discovered: ${tag.type}');

      if (tag.ndefAvailable == true) {
        // Read NDEF records
        var ndefRecords = await FlutterNfcKit.readNDEFRecords();

        if (ndefRecords.isNotEmpty) {
          // Get the payload from the first record
          var record = ndefRecords.first;
          String payload = '';

          if (record.payload != null) {
            // Handle different payload formats
            if (record.payload is String) {
              payload = record.payload as String;
            } else if (record.payload is Uint8List) {
              var bytes = record.payload as Uint8List;
              // Skip language encoding for text records
              if (bytes.length > 3 && bytes[0] == 0x02) {
                // Text record with language code - skip first 3 + language length bytes
                int langCodeLength = bytes[2];
                payload = utf8.decode(bytes.skip(3 + langCodeLength).toList());
              } else {
                payload = utf8.decode(bytes);
              }
            } else {
              payload = record.payload.toString();
            }

            // Try to parse as JSON
            try {
              final data = json.decode(payload);
              return ChecklistData.fromJson(data);
            } catch (e) {
              print('JSON parse error: $e, payload: $payload');
              // Return empty checklist if can't parse
              return ChecklistData.empty();
            }
          }
        }
      }

      // Empty tag or no NDEF records
      return ChecklistData.empty();

    } catch (e) {
      print('NFC read error: $e');
      return null;
    } finally {
      // Always finish the session
      try {
        await FlutterNfcKit.finish();
      } catch (e) {
        print('Error finishing NFC session: $e');
      }
    }
  }

  Future<bool> writeToTag(ChecklistData data) async {
    try {
      // Start NFC session
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Hold your device near the tag to save",
      );

      print('Writing to tag: ${tag.type}');

      if (tag.ndefAvailable == true && tag.ndefWritable == true) {
        // Convert data to JSON string
        final jsonString = json.encode(data.toJson());
        print('Writing JSON: ${jsonString.length} characters');

        // Create a simple text record manually
        final textBytes = utf8.encode(jsonString);
        final languageBytes = utf8.encode('en');

        // Create NDEF text record payload
        final payload = Uint8List.fromList([
          0x02, // Text record type
          languageBytes.length, // Language code length
          ...languageBytes, // Language code
          ...textBytes, // Actual text data
        ]);

        // Create the NDEF record
        final record = NDEFRecord(
          id: null,
          payload: payload,
          type: Uint8List.fromList([0x54]), // 'T' for text record
          typeNameFormat: NDEFTypeNameFormat.nfcWellKnown,
        );

        // Write the record to the tag
        await FlutterNfcKit.writeNDEFRecords([record]);

        print('Successfully wrote to tag');
        return true;
      } else {
        print('Tag is not NDEF writable. Available: ${tag.ndefAvailable}, Writable: ${tag.ndefWritable}');
        return false;
      }

    } catch (e) {
      print('NFC write error: $e');
      return false;
    } finally {
      // Always finish the session
      try {
        await FlutterNfcKit.finish();
      } catch (e) {
        print('Error finishing NFC session: $e');
      }
    }
  }

  void stopSession() {
    FlutterNfcKit.finish().catchError((e) {
      print('Error stopping session: $e');
    });
  }
}