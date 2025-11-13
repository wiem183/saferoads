# QR Code Scanning Implementation

## Overview
The Amendes system now has a complete QR code workflow:
1. **QR Generation**: When viewing an amende, a scannable QR code is generated containing the full amende data as JSON
2. **QR Scanning**: Users can scan QR codes using the QR Scanner screen to view amende details
3. **Data Display**: Scanned amende details are displayed in a formatted, easy-to-read screen

## How It Works

### Part 1: Generating QR Codes

When a user taps on a fine in the list, a dialog appears showing:
- A QR code (280x280 pixels) containing the amende JSON data
- A label "Scan to view details"
- The raw JSON data (for reference or copying)

**QR Encoding:**
```dart
final jsonStr = jsonEncode(amende.toJson());
```

The QR code contains the complete amende data:
```json
{
  "id": "amende_id",
  "userId": "user_id",
  "agentId": "agent_id", 
  "photoUrl": "https://...",
  "location": "Street/Location",
  "type": "speeding",
  "amount": 150.0
}
```

### Part 2: Scanning QR Codes

**Location**: Bottom navigation bar in the Amendes screen has a new QR scanner button (purple, with QR code icon)

**How to use:**
1. Click the purple QR scanner button
2. Point your camera at a QR code
3. The scanner automatically detects and decodes the QR code
4. The amende details screen displays with all information

**Features:**
- Automatic QR detection
- Torch/flashlight toggle button in the app bar
- Error handling for invalid QR codes
- Displays detailed amende information in a formatted card

### Part 3: Displaying Scanned Details

The scanned amende details screen shows:

```
┌─────────────────────────────────┐
│   Violation Type: Speeding      │
│   Amount: 150 DT                │
├─────────────────────────────────┤
│ 📍 Location: Street/Location    │
│ 👤 Violator ID: user_123        │
│ 🏢 Agent ID: agent_456          │
│ 🏷️  Amende ID: amende_789       │
│ 📷 Photo Evidence: [Image]      │
├─────────────────────────────────┤
│              [Close]            │
└─────────────────────────────────┘
```

## Technical Implementation

### Files Modified/Created:

1. **`lib/screens/amende_screens_example.dart`**
   - Updated QR generation with better size (300px) and gapless rendering
   - Added QR scanner button to the FAB menu
   - Improved QR dialog with white background container
   - Added "Scan to view details" label

2. **`lib/screens/qr_scanner_screen.dart` (NEW)**
   - `QrScannerScreen`: Main scanning interface
   - `_AmendeDetailsScreen`: Displays scanned amende details
   - Uses `mobile_scanner` package for camera access

3. **`pubspec.yaml`**
   - Added dependency: `mobile_scanner: ^5.0.0`

### Key Functions:

**QR Generation:**
```dart
Future<Uint8List> _buildQrPngBytes(String data) async {
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    gapless: false,
  );
  final image = await painter.toImage(300);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
```

**QR Scanning:**
```dart
void _handleBarcode(BarcodeCapture barcodes) {
  final barcode = barcodes.barcodes.first;
  final rawValue = barcode.rawValue;
  
  try {
    final jsonData = jsonDecode(rawValue);
    final amende = Amende.fromJson(jsonData);
    // Display amende details
  } catch (e) {
    // Show error
  }
}
```

## User Flow

### Creating/Viewing an Amende with QR:

```
┌─────────────────────────────┐
│  1. User sees amende list   │
│     [Fine 1] [Fine 2] [Fine 3] (with edit/delete buttons)
└─────────────────────────────┘
         ↓ (tap item)
┌─────────────────────────────┐
│  2. QR Dialog shows:        │
│     - QR Code Image         │
│     - JSON Data             │
│     - "Scan to view details"│
└─────────────────────────────┘
```

### Scanning an Amende:

```
┌─────────────────────────────┐
│  1. Click purple QR button  │
│     (Scan QR Code button)   │
└─────────────────────────────┘
         ↓
┌─────────────────────────────┐
│  2. Camera opens            │
│     Point at QR code        │
│     (Torch available)       │
└─────────────────────────────┘
         ↓ (QR detected)
┌─────────────────────────────┐
│  3. Details screen shows    │
│     - Violation Type        │
│     - Location              │
│     - Amount                │
│     - Photo Evidence        │
│     - IDs                   │
└─────────────────────────────┘
```

## Testing the Feature

1. **Generate a QR:**
   - Navigate to Amendes tab
   - Create a new fine or click on an existing one
   - Tap the fine to view its QR code

2. **Scan the QR:**
   - Click the purple "Scan QR Code" button
   - Point camera at the QR code
   - Details should display automatically

3. **Troubleshooting:**
   - Ensure the QR code is well-lit and clear
   - Make sure camera permissions are granted
   - QR should be large enough on screen (~2 inches minimum)

## Permissions Required

The `mobile_scanner` package requires camera permissions:

- **Android**: `android.permission.CAMERA` (declared in AndroidManifest.xml)
- **iOS**: Camera usage permission (declared in Info.plist)

These are typically already configured in Flutter projects.

## Future Enhancements

1. **Batch QR Downloads**: Allow exporting multiple amendes as QR codes
2. **QR History**: Track scanned QR codes with timestamp
3. **QR Sharing**: Share individual amende QR codes
4. **Custom QR Styling**: Add branding/logos to QR codes
5. **Web Version**: Web-based QR reader for desktop viewing
