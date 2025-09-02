import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import '../models/equipment.dart';
import '../models/checklist_data.dart';

class NFCService {
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
          String payload;

          if (record.payload != null) {
            // Handle different payload formats
            if (record.payload is String) {
              payload = record.payload as String;
            } else if (record.payload is Uint8List) {
              // For text records, skip language code if present
              var bytes = record.payload as Uint8List;
              if (bytes.length > 3 && bytes[0] == 0x02) {
                // Text record with language code
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

        // Create NDEF text record using the ndef library
        final textRecord = ndef.TextRecord(
          text: jsonString,
          language: 'en',
        );

        // Write the record to the tag
        await FlutterNfcKit.writeNDEFRecords([textRecord]);

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
    // Flutter NFC Kit automatically manages sessions
    FlutterNfcKit.finish().catchError((e) {
      print('Error stopping session: $e');
    });
  }
}