// lib/services/real_nfc_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../models/checklist_data.dart';

class RealNFCService {
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
      print('Starting NFC read session...');

      // Start NFC session
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Hold your device near the RFID tag to read",
      );

      print('Tag discovered: ${tag.type}, ID: ${tag.id}');
      print('NDEF Available: ${tag.ndefAvailable}, Writable: ${tag.ndefWritable}');

      if (tag.ndefAvailable == true) {
        // Read NDEF records
        var ndefRecords = await FlutterNfcKit.readNDEFRecords();
        print('Found ${ndefRecords.length} NDEF records');

        if (ndefRecords.isNotEmpty) {
          // Get the payload from the first record
          var record = ndefRecords.first;
          print('Record type: ${record.type}');

          String payload = '';

          if (record.payload != null) {
            // Handle different payload formats
            if (record.payload is String) {
              payload = record.payload as String;
              print('Payload as string: $payload');
            } else if (record.payload is Uint8List) {
              var bytes = record.payload as Uint8List;
              print('Payload bytes length: ${bytes.length}');

              // Check if it's a text record (starts with text record header)
              if (bytes.length > 3) {
                // For text records, check the first byte
                if (bytes[0] == 0x02) {
                  // Standard text record with language code
                  int langCodeLength = bytes[2];
                  print('Language code length: $langCodeLength');
                  if (bytes.length > 3 + langCodeLength) {
                    payload = utf8.decode(bytes.skip(3 + langCodeLength).toList());
                  }
                } else {
                  // Try direct UTF-8 decode
                  try {
                    payload = utf8.decode(bytes);
                  } catch (e) {
                    print('UTF-8 decode failed, trying latin1: $e');
                    payload = String.fromCharCodes(bytes);
                  }
                }
              } else {
                payload = utf8.decode(bytes);
              }
              print('Decoded payload: $payload');
            } else {
              payload = record.payload.toString();
              print('Payload as toString: $payload');
            }

            // Try to parse as JSON
            if (payload.isNotEmpty) {
              try {
                final data = json.decode(payload);
                print('Successfully parsed JSON data');
                return ChecklistData.fromJson(data);
              } catch (e) {
                print('JSON parse error: $e');
                print('Raw payload: $payload');
                // If JSON parsing fails, treat as empty tag
                return ChecklistData.empty();
              }
            }
          }
        } else {
          print('No NDEF records found - treating as empty tag');
        }
      } else {
        print('Tag does not support NDEF - treating as empty tag');
      }

      // Empty tag or no readable NDEF records
      print('Returning empty checklist data');
      return ChecklistData.empty();

    } catch (e) {
      print('NFC read error: $e');
      return null;
    } finally {
      // Always finish the session
      try {
        await FlutterNfcKit.finish();
        print('NFC session finished');
      } catch (e) {
        print('Error finishing NFC session: $e');
      }
    }
  }

  Future<bool> writeToTag(ChecklistData data) async {
    try {
      print('Starting NFC write session...');

      // Start NFC session
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Hold your device near the RFID tag to save data",
      );

      print('Tag discovered for writing: ${tag.type}, ID: ${tag.id}');
      print('NDEF Available: ${tag.ndefAvailable}, Writable: ${tag.ndefWritable}');

      if (tag.ndefAvailable == true && tag.ndefWritable == true) {
        // Convert data to JSON string
        final jsonString = json.encode(data.toJson());
        print('Writing JSON data: ${jsonString.length} characters');
        print('First 100 chars: ${jsonString.length > 100 ? jsonString.substring(0, 100) + "..." : jsonString}');

        // Write using flutter_nfc_kit's writeNDEFRawRecords method
        // Create a simple text record without using ndef library
        final languageCode = 'en';
        final jsonBytes = utf8.encode(jsonString);
        final langBytes = utf8.encode(languageCode);

        // Build NDEF text record payload manually
        // Format: [Status byte][Language code][Text data]
        final recordPayload = <int>[
          0x02, // Status: UTF-8 encoding, short record
          ...langBytes,
          ...jsonBytes,
        ];

        // Create the raw record using the correct constructor
        final rawRecord = NDEFRawRecord(
          Uint8List(0), // identifier
          Uint8List.fromList([0x54]), // type ('T' for text record)
          Uint8List.fromList(recordPayload), // payload
          1, // typeNameFormat (1 = Well-known type)
        );

        // Write the raw record to the tag
        await FlutterNfcKit.writeNDEFRawRecords([rawRecord]);

        print('Successfully wrote data to RFID tag!');
        return true;
      } else {
        print('Tag is not NDEF writable');
        print('Available: ${tag.ndefAvailable}, Writable: ${tag.ndefWritable}');
        return false;
      }

    } catch (e) {
      print('NFC write error: $e');
      return false;
    } finally {
      // Always finish the session
      try {
        await FlutterNfcKit.finish();
        print('NFC write session finished');
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