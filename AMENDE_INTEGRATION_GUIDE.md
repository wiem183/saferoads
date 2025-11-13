# Amende CRUD System - Integration Guide

## Quick Reference

### What Was Created

| File | Purpose |
|------|---------|
| `lib/models/amende.dart` | Data model with enums |
| `lib/controllers/amende_controller.dart` | CRUD operations |
| `test/amende_model_test.dart` | Model unit tests |
| `test/amende_controller_test.dart` | Controller unit tests |
| `lib/screens/amende_screens_example.dart` | Example UI screens |
| `AMENDE_CRUD_DOCUMENTATION.md` | Full API documentation |
| `AMENDE_IMPLEMENTATION_SUMMARY.md` | Implementation overview |

---

## Integration Steps

### Step 1: Ensure Dependencies

Update `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cloud_firestore: ^4.0.0
  uuid: ^4.0.0
```

Run:
```bash
flutter pub get
```

### Step 2: Create Provider Setup (Optional but Recommended)

If using Provider pattern, add to your main app:

```dart
import 'package:provider/provider.dart';
import 'controllers/amende_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AmendeController(),
        ),
        // Add other controllers here
      ],
      child: MaterialApp(
        title: 'SafeRoads',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
```

### Step 3: Set Up Firestore Security Rules

In Firebase Console → Firestore → Rules, replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Check if user has role
    function getUserRole(uid) {
      return get(/databases/$(database)/documents/users/$(uid)).data.role;
    }
    
    // Amendes collection rules
    match /amendes/{amendeId} {
      // Users can read their own fines
      allow read: if request.auth.uid == resource.data.userId;
      
      // Agents/Admins can read all fines
      allow read: if (
        getUserRole(request.auth.uid) == 'agent' ||
        getUserRole(request.auth.uid) == 'admin'
      );
      
      // Only agents/admins can create fines
      allow create: if (
        getUserRole(request.auth.uid) == 'agent' ||
        getUserRole(request.auth.uid) == 'admin'
      );
      
      // Users can contest or pay (update status only)
      allow update: if 
        (request.auth.uid == resource.data.userId && 
         (request.resource.data.status == 'paid' || 
          request.resource.data.status == 'contested'))
        || getUserRole(request.auth.uid) == 'admin';
      
      // Only admins can delete
      allow delete: if getUserRole(request.auth.uid) == 'admin';
    }
  }
}
```

### Step 4: Create Firestore Indexes

1. Go to Firebase Console
2. Firestore Database → Indexes → Create Index

**Create these composite indexes:**

| Collection | Fields (in order) | Direction |
|-----------|------------------|-----------|
| amendes | userId | Ascending |
| amendes | userId, isDeleted | Ascending, Ascending |
| amendes | userId, status | Ascending, Ascending |
| amendes | agentId, isDeleted | Ascending, Ascending |
| amendes | status, isDeleted | Ascending, Ascending |

### Step 5: Update User Model

Ensure your user model has a `role` field:

```dart
class User {
  String id;
  String name;
  String email;
  String phone;
  String role; // 'user', 'agent', or 'admin'
  // ... other fields
  
  // In Firestore
  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    role = json['role']; // Make sure this exists
    // ...
  }
}
```

---

## Usage Examples

### Display User Fines

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/amende_controller.dart';
import 'models/amende.dart';

class UserFinesScreen extends StatelessWidget {
  final String userId;

  const UserFinesScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final amendeController = 
        context.read<AmendeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Fines')),
      body: StreamBuilder<List<Amende>>(
        stream: amendeController.getUserAmendesStream(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No fines'));
          }

          return ListView(
            children: snapshot.data!
                .map((amende) => ListTile(
                  title: Text(amende.getTypeLabel()),
                  subtitle: Text(amende.location),
                  trailing: Text('${amende.amount}DT'),
                ))
                .toList(),
          );
        },
      ),
    );
  }
}
```

### Create a Fine (Admin)

```dart
Future<void> createFine(
  BuildContext context,
  AmendeController controller,
) async {
  try {
    final amendeId = await controller.createAmende(
      userId: 'violator-id',
      agentId: 'agent-id',
      photoUrl: 'https://storage.example.com/photo.jpg',
      location: 'Avenue Habib Bourguiba, Tunis',
      type: AmendeType.speeding,
      amount: 150.0,
      violationDate: DateTime.now().subtract(
        const Duration(hours: 2),
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fine created: $amendeId')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

### Contest a Fine

```dart
Future<void> contestFine(
  BuildContext context,
  AmendeController controller,
  String amendeId,
  String reason,
) async {
  try {
    await controller.contestAmende(amendeId, reason);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fine contested successfully'),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

### View Statistics

```dart
FutureBuilder<Map<String, dynamic>>(
  future: amendeController.getUserAmendeStats(userId),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    final stats = snapshot.data!;
    
    return Column(
      children: [
        Text('Total Fines: ${stats['total']}'),
        Text('Unpaid: ${stats['unpaid']}'),
        Text('Paid: ${stats['paid']}'),
        Text('Contested: ${stats['contested']}'),
        Text('Total Amount: ${stats['totalAmount']}DT'),
      ],
    );
  },
)
```

### Mark as Paid

```dart
await amendeController.markAsPaid(amendeId);
```

### Contest with Reason

```dart
await amendeController.contestAmende(
  amendeId,
  'I was not speeding. The radar was faulty.',
);
```

---

## Screen Implementation

Use the example screens in `lib/screens/amende_screens_example.dart`:

1. **`UserAmendesScreen`** - Displays user's fines with summary
2. **`CreateAmendeScreen`** - Form to create new fines (admin)

Import and use:

```dart
// Show user fines
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => UserAmendesScreen(userId: userId),
  ),
);

// Create new fine
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CreateAmendeScreen(agentId: agentId),
  ),
);
```

---

## Admin Dashboard Features

For admins, create these screens:

```dart
// View all contested fines
amendeController.getContestedAmendesStream()

// View all fines by agent
amendeController.getAgentAmendesStream(agentId)

// Approve contested fines
amendeController.updateAmendeStatus(
  amendeId,
  AmendeStatus.rejected, // or paid
)
```

---

## Testing

Run tests:

```bash
flutter test test/amende_model_test.dart
flutter test test/amende_controller_test.dart
```

For Firebase integration tests, you'll need to mock Firestore:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
```

---

## Troubleshooting

### Error: "Target of URI doesn't exist"
- Run `flutter pub get`
- Clean and rebuild: `flutter clean && flutter pub get && flutter build`

### Error: "isDeleted field not found"
- Ensure all existing documents are updated or use migration scripts
- Or allow Firestore to use default values (set `false` in queries)

### Slow queries
- Ensure Firestore indexes are created (see Step 4)
- Check Firestore usage in console

### Permission denied errors
- Verify Firestore security rules are set correctly
- Check user role is set in user document

---

## Performance Optimization

### Pagination for Large Datasets

```dart
Stream<List<Amende>> getUserAmendesStreamPaginated(
  String userId, {
  int pageSize = 20,
}) {
  return _db
      .collection(_collection)
      .where('userId', isEqualTo: userId)
      .where('isDeleted', isEqualTo: false)
      .orderBy('createdDate', descending: true)
      .limit(pageSize)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Amende.fromJson(d.data()))
          .toList());
}
```

### Caching with Provider

```dart
class AmendeProvider with ChangeNotifier {
  final AmendeController _controller = AmendeController();
  List<Amende> _cachedAmendes = [];

  List<Amende> get amendes => _cachedAmendes;

  void loadAmendes(String userId) {
    _controller.getUserAmendesStream(userId).listen((amendes) {
      _cachedAmendes = amendes;
      notifyListeners();
    });
  }
}
```

---

## Next Features to Add

- [ ] Photo upload to Firebase Storage
- [ ] Payment integration (Stripe, PayPal)
- [ ] Email notifications for new fines
- [ ] SMS notifications
- [ ] Fine expiration (statute of limitations)
- [ ] Partial payment support
- [ ] Fine appeal workflow
- [ ] Statistics/analytics dashboard
- [ ] Export fines to PDF
- [ ] Multi-language support (FR, EN, AR)
- [ ] QR code for fine reference
- [ ] Mobile wallet integration

---

## Support Files

- **Full API Docs**: `AMENDE_CRUD_DOCUMENTATION.md`
- **Implementation Summary**: `AMENDE_IMPLEMENTATION_SUMMARY.md`
- **Example Screens**: `lib/screens/amende_screens_example.dart`

---

## FAQ

**Q: Can users delete their own fines?**  
A: No. Fines can only be soft-deleted by admins or hard-deleted (permanent) by admins. Users can only contest fines.

**Q: What happens to soft-deleted fines?**  
A: They're marked with `isDeleted: true` and excluded from all queries. Data is preserved for audit trails. Admins can restore them.

**Q: How do users pay fines?**  
A: Implement a payment screen that calls `markAsPaid()` after successful payment. Update status to `AmendeStatus.paid`.

**Q: Can a fine be un-contested?**  
A: Yes, update status back to `unpaid` or `paid`. The contestation reason is preserved in the record.

**Q: How are agents/admins determined?**  
A: Check the user's `role` field in the `users` collection. Set role to 'agent' or 'admin' in Firestore.

---

## Version Information

- **Created**: 2025-11-12
- **Flutter Version**: Compatible with Flutter 3.0+
- **Dart Version**: Compatible with Dart 3.0+
- **Cloud Firestore**: v4.0.0+

