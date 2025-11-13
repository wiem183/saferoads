# Amende CRUD System Documentation

## Overview
The Amende (Fine/Traffic Violation) CRUD system allows agents/admins to create and manage traffic fines, while users can view their fines and their payment status.

## Database Collection: `amendes`

### Document Structure
```json
{
  "id": "unique-amende-id",
  "userId": "user-receiving-fine",
  "agentId": "agent-creating-fine",
  "photoUrl": "https://example.com/photo.jpg",
  "location": "Avenue Habib Bourguiba, Tunis",
  "type": "speeding",
  "amount": 150.0,
  "violationDate": "2025-11-12T10:30:00.000Z",
  "createdDate": "2025-11-12T11:00:00.000Z",
  "status": "unpaid",
  "contestationReason": null,
  "isDeleted": false
}
```

## Data Models

### AmendeType Enum
Represents the type of violation:
- `speeding` - Excès de vitesse
- `parking` - Stationnement interdit
- `redLight` - Feu rouge
- `seatBelt` - Ceinture de sécurité
- `phoneUse` - Utilisation du téléphone
- `documentaryOffense` - Défaut de documents
- `other` - Autre

### AmendeStatus Enum
Represents the status of the fine:
- `unpaid` - Impayée (not yet paid)
- `paid` - Payée (paid)
- `contested` - Contestée (under dispute)
- `rejected` - Rejetée (rejected/cancelled)

## API Reference

### CREATE Operations

#### `createAmende()`
Creates a new fine (agent/admin only)

```dart
Future<String> createAmende({
  required String userId,
  required String agentId,
  String? photoUrl,
  required String location,
  required AmendeType type,
  required double amount,
  required DateTime violationDate,
})
```

**Parameters:**
- `userId`: ID of user receiving the fine
- `agentId`: ID of agent/admin creating the fine
- `photoUrl`: Optional URL to violation photo evidence
- `location`: Location where violation occurred
- `type`: Type of violation (from AmendeType enum)
- `amount`: Fine amount
- `violationDate`: When the violation occurred

**Returns:** The generated amende ID

**Example:**
```dart
final amendeId = await amendeController.createAmende(
  userId: 'user123',
  agentId: 'agent456',
  photoUrl: 'https://storage.example.com/photo.jpg',
  location: 'Boulevard du 7 Novembre',
  type: AmendeType.speeding,
  amount: 150.0,
  violationDate: DateTime.now().subtract(Duration(hours: 2)),
);
```

---

### READ Operations

#### `getUserAmendesStream(String userId)`
Returns a stream of all non-deleted fines for a specific user

```dart
Stream<List<Amende>> getUserAmendesStream(String userId)
```

**Returns:** Stream of Amende list

**Example:**
```dart
amendeController.getUserAmendesStream('user123').listen((amendes) {
  print('User has ${amendes.length} fines');
  for (var amende in amendes) {
    print('${amende.location}: ${amende.amount}DT - ${amende.getStatusLabel()}');
  }
});
```

#### `getUnpaidAmendesStream(String userId)`
Returns a stream of unpaid fines for a user

```dart
Stream<List<Amende>> getUnpaidAmendesStream(String userId)
```

#### `getContestedAmendesStream()`
Returns a stream of all contested fines (for admin review)

```dart
Stream<List<Amende>> getContestedAmendesStream()
```

#### `getAgentAmendesStream(String agentId)`
Returns a stream of all fines created by a specific agent

```dart
Stream<List<Amende>> getAgentAmendesStream(String agentId)
```

#### `getAmendeById(String amendeId)`
Fetches a specific fine by ID

```dart
Future<Amende?> getAmendeById(String amendeId)
```

**Returns:** Amende object or null if not found or soft-deleted

#### `getTotalUnpaidAmount(String userId)`
Calculates total unpaid fine amount for a user

```dart
Future<double> getTotalUnpaidAmount(String userId)
```

**Example:**
```dart
final total = await amendeController.getTotalUnpaidAmount('user123');
print('Total unpaid: ${total}DT');
```

#### `getUserAmendeStats(String userId)`
Returns statistics about a user's fines

```dart
Future<Map<String, dynamic>> getUserAmendeStats(String userId)
```

**Returns:** Map with keys:
- `total`: Total number of fines
- `unpaid`: Number of unpaid fines
- `paid`: Number of paid fines
- `contested`: Number of contested fines
- `rejected`: Number of rejected fines
- `totalAmount`: Total amount of all fines

**Example:**
```dart
final stats = await amendeController.getUserAmendeStats('user123');
print('Total fines: ${stats['total']}');
print('Unpaid: ${stats['unpaid']}');
print('Total amount: ${stats['totalAmount']}DT');
```

---

### UPDATE Operations

#### `updateAmendeStatus()`
Updates the status of a fine

```dart
Future<void> updateAmendeStatus(
  String amendeId,
  AmendeStatus newStatus,
  {String? contestationReason}
)
```

**Parameters:**
- `amendeId`: ID of the fine to update
- `newStatus`: New status value
- `contestationReason`: Optional reason if status is contested

**Example:**
```dart
await amendeController.updateAmendeStatus(
  'amende123',
  AmendeStatus.paid,
);
```

#### `contestAmende()`
Mark a fine as contested with a reason

```dart
Future<void> contestAmende(String amendeId, String contestationReason)
```

**Example:**
```dart
await amendeController.contestAmende(
  'amende123',
  'I was not speeding, radar was faulty',
);
```

#### `markAsPaid()`
Convenience method to mark a fine as paid

```dart
Future<void> markAsPaid(String amendeId)
```

---

### DELETE Operations

#### `deleteAmende()` - Soft Delete
Marks a fine as deleted (isDeleted = true) without removing from database

```dart
Future<void> deleteAmende(String amendeId)
```

**Note:** Soft-deleted fines won't appear in queries due to `isDeleted` filter

#### `hardDeleteAmende()` - Permanent Delete
Permanently removes a fine from database (admin only)

```dart
Future<void> hardDeleteAmende(String amendeId)
```

**Warning:** This is permanent and cannot be undone

#### `restoreAmende()`
Restores a soft-deleted fine

```dart
Future<void> restoreAmende(String amendeId)
```

---

## Firestore Security Rules

Recommended security rules for the `amendes` collection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /amendes/{amendeId} {
      // Users can read their own fines
      allow read: if request.auth.uid == resource.data.userId;
      
      // Agents/Admins can read all fines
      allow read: if hasRole(request.auth.uid, 'agent') || hasRole(request.auth.uid, 'admin');
      
      // Only agents/admins can create
      allow create: if hasRole(request.auth.uid, 'agent') || hasRole(request.auth.uid, 'admin');
      
      // Users can update status (for payment/contestation)
      allow update: if (
        request.auth.uid == resource.data.userId && 
        (request.resource.data.status == 'paid' || request.resource.data.status == 'contested')
      ) || (hasRole(request.auth.uid, 'admin'));
      
      // Only admins can delete
      allow delete: if hasRole(request.auth.uid, 'admin');
    }
  }
  
  function hasRole(uid, role) {
    return get(/databases/$(database)/documents/users/$(uid)).data.role == role;
  }
}
```

---

## Usage Examples

### Example 1: Display User's Fines
```dart
class UserAmendesScreen extends StatefulWidget {
  final String userId;

  const UserAmendesScreen({required this.userId});

  @override
  State<UserAmendesScreen> createState() => _UserAmendesScreenState();
}

class _UserAmendesScreenState extends State<UserAmendesScreen> {
  late AmendeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AmendeController();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Amende>>(
      stream: _controller.getUserAmendesStream(widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final amendes = snapshot.data!;

        if (amendes.isEmpty) {
          return const Text('No fines');
        }

        return ListView.builder(
          itemCount: amendes.length,
          itemBuilder: (context, index) {
            final amende = amendes[index];
            return Card(
              child: ListTile(
                title: Text(amende.getTypeLabel()),
                subtitle: Text(amende.location),
                trailing: Text(
                  '${amende.amount}DT - ${amende.getStatusLabel()}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
```

### Example 2: Create a Fine (Agent/Admin)
```dart
Future<void> createFineDemoDialog(BuildContext context, AmendeController controller) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Create Fine'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(label: const Text('User Phone'), key: const Key('userPhone')),
            TextField(label: const Text('Location'), key: const Key('location')),
            TextField(label: const Text('Amount'), key: const Key('amount')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await controller.createAmende(
              userId: 'user123',
              agentId: 'agent456',
              location: 'Boulevard Test',
              type: AmendeType.speeding,
              amount: 150.0,
              violationDate: DateTime.now(),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
```

### Example 3: Contest a Fine
```dart
Future<void> contestFineDialog(
  BuildContext context,
  AmendeController controller,
  String amendeId,
) {
  final reasonController = TextEditingController();
  
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Contest Fine'),
      content: TextField(
        controller: reasonController,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Enter your contestation reason...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await controller.contestAmende(
              amendeId,
              reasonController.text,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}
```

---

## Files Created

1. **`lib/models/amende.dart`** - Amende data model with enums
2. **`lib/controllers/amende_controller.dart`** - CRUD operations controller
3. **`test/amende_model_test.dart`** - Unit tests for Amende model
4. **`test/amende_controller_test.dart`** - Unit tests for controller

---

## Dependencies Required

Make sure your `pubspec.yaml` includes:
```yaml
dependencies:
  cloud_firestore: ^latest
  flutter: sdk: flutter
  uuid: ^latest
```

---

## Next Steps

1. ✅ Create UI screens for viewing fines
2. ✅ Create fine creation form (agent/admin only)
3. ✅ Add payment integration
4. ✅ Create notification system for new fines
5. ✅ Add fine filtering and sorting
6. ✅ Create statistics dashboard

---

## Firestore Indexes

For optimal query performance, create these composite indexes in Firestore:

| Collection | Fields | Direction |
|-----------|--------|-----------|
| amendes | userId, isDeleted | Asc, Asc |
| amendes | userId, status, isDeleted | Asc, Asc, Asc |
| amendes | agentId, isDeleted | Asc, Asc |
| amendes | status, isDeleted | Asc, Asc |

