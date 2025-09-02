# Field Services Technician App

A Flutter-based field services application that allows technicians to perform maintenance checklists using RFID tags for data persistence and progress tracking.

## Features

### Core Functionality
- **User Authentication**: Simple login system with two demo accounts
- **RFID Integration**: Read from and write checklist data to NFC/RFID tags
- **Equipment Setup**: Barcode scanning and manual entry for equipment identification
- **Interactive Checklist**: Step-by-step maintenance tasks with progress tracking
- **Photo Documentation**: Camera integration for task documentation
- **Digital Signature**: Electronic signature capture for job completion
- **Offline Operation**: All data stored locally and on RFID tags

### Workflow
1. **Login**: Technician logs in with credentials
2. **RFID Scan**: Scan an RFID tag to begin or continue work
3. **Equipment Setup**: If tag is empty, scan barcode and select part/customer
4. **Checklist Execution**: Complete maintenance tasks with notes and photos
5. **Progress Saving**: Save progress to RFID tag at any time
6. **Completion**: Digital signature and final save to RFID tag

## Tech Stack

- **Framework**: Flutter (Dart)
- **Database**: SQLite (for temporary working storage)
- **RFID/NFC**: nfc_manager plugin
- **Barcode Scanning**: mobile_scanner plugin
- **Image Handling**: image_picker plugin
- **Digital Signature**: signature plugin
- **State Management**: Provider pattern

## Prerequisites

### Development Environment
- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio or VS Code with Flutter extensions

### Hardware Requirements
- Android device with NFC capability (for RFID functionality)
- Camera (for barcode scanning and photo documentation)
- RFID/NFC tags compatible with NDEF format

## Installation

### 1. Clone and Setup
```bash
# Clone the repository
git clone <repository-url>
cd field_services_app

# Install dependencies
flutter pub get

# Generate code (if needed)
flutter packages pub run build_runner build
```

### 2. Android Configuration
Ensure the AndroidManifest.xml file includes the necessary permissions (already configured in the provided manifest).

### 3. iOS Configuration (if needed)
Add the following to `ios/Runner/Info.plist`:
```xml
<key>NFCReaderUsageDescription</key>
<string>This app needs access to NFC to read and write maintenance data</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos for maintenance documentation</string>
```

## Demo Accounts

For testing purposes, use these hardcoded accounts:

| Username | Password   |
|----------|-----------|
| tech1    | password1 |
| tech2    | password2 |

## Hardcoded Data

### Customers
- **123 - Company A**
- **345 - Company B**

### Parts
- **AAA - Part A**
- **BBB - Part B**

### Maintenance Checklist
The app includes a comprehensive preventive maintenance checklist with four main categories: