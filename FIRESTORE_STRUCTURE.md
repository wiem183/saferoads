# Firestore Structure for Amende CRUD System

## Collection: `amendes`

### Document Example

```
Database: saferoads
└── Collection: amendes
    └── Document: amende_001
        ├── id: "amende_001"
        ├── userId: "user_123" [String]
        ├── agentId: "agent_456" [String]
        ├── photoUrl: "https://storage.googleapis.com/saferoads/photo_xyz.jpg" [String]
        ├── location: "Avenue Habib Bourguiba, Tunis" [String]
        ├── type: "speeding" [String] ← From AmendeType enum
        ├── amount: 150.0 [Number]
        ├── violationDate: 2025-11-12T10:30:00.000Z [Timestamp]
        ├── createdDate: 2025-11-12T11:00:00.000Z [Timestamp]
        ├── status: "unpaid" [String] ← From AmendeStatus enum
        ├── contestationReason: "Radar was faulty" [String, nullable]
        └── isDeleted: false [Boolean]
```

---

## Typical Query Patterns

### 1. Get All User Fines
```firestore
Query: 
  collection('amendes')
    .where('userId', '==', 'user_123')
    .where('isDeleted', '==', false)

Returns: List<Amende>
```

### 2. Get Unpaid Fines
```firestore
Query:
  collection('amendes')
    .where('userId', '==', 'user_123')
    .where('status', '==', 'unpaid')
    .where('isDeleted', '==', false)

Returns: List<Amende>
```

### 3. Get Contested Fines (Admin)
```firestore
Query:
  collection('amendes')
    .where('status', '==', 'contested')
    .where('isDeleted', '==', false)

Returns: List<Amende>
```

### 4. Get Fines by Agent
```firestore
Query:
  collection('amendes')
    .where('agentId', '==', 'agent_456')
    .where('isDeleted', '==', false)

Returns: List<Amende>
```

---

## Firestore Indexes Required

Create these composite indexes in Firebase Console:

### Index 1: User Fines
```
Collection: amendes
Fields:
  1. userId (Ascending)
  2. isDeleted (Ascending)
```

### Index 2: User Unpaid Fines
```
Collection: amendes
Fields:
  1. userId (Ascending)
  2. status (Ascending)
  3. isDeleted (Ascending)
```

### Index 3: Agent Fines
```
Collection: amendes
Fields:
  1. agentId (Ascending)
  2. isDeleted (Ascending)
```

### Index 4: Contested Fines
```
Collection: amendes
Fields:
  1. status (Ascending)
  2. isDeleted (Ascending)
```

### Index 5: Violation Date Query (Optional)
```
Collection: amendes
Fields:
  1. userId (Ascending)
  2. violationDate (Descending)
```

---

## Data Model Relationships

```
┌─────────────────────────────────────────────────────┐
│                    Amende Document                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  userId ──────────→ Reference to users/{userId}   │
│  agentId ────────→ Reference to users/{agentId}   │
│  photoUrl ────────→ URL to Firebase Storage       │
│                                                     │
│  Status Flow:                                       │
│  unpaid ──→ paid     (after payment)               │
│       ├──→ contested (user disputes)               │
│       └──→ rejected  (auto/admin)                  │
│                                                     │
│  Soft Delete:                                       │
│  isDeleted: false ───→ isDeleted: true             │
│  (visible)          (hidden from queries)          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Related Collections

### Users Collection Structure (Reference)
```
Database: saferoads
└── Collection: users
    └── Document: user_123
        ├── id: "user_123"
        ├── name: "Ahmed Salah"
        ├── email: "ahmed@example.com"
        ├── phone: "+216 12 345 678"
        ├── role: "user" ← Determines permissions
        └── ...other fields
```

### Agents/Admins Collection Reference
```
Database: saferoads
└── Collection: users
    └── Document: agent_456
        ├── id: "agent_456"
        ├── name: "Officer Mohamed"
        ├── email: "officer@saferoads.tn"
        ├── phone: "+216 98 765 432"
        ├── role: "agent" ← Can create fines
        ├── agency: "Traffic Department"
        └── ...other fields
```

---

## Backup & Recovery Strategy

### Firestore Backup Rules
```
- Daily snapshots of amendes collection
- Soft-deleted documents preserved for 90 days
- Hard-deleted documents logged to audit trail
- Restoration available within 30 days
```

### Archive Strategy
```
Collection: amendes_archive
- Store resolved fines (paid/rejected) after 1 year
- Searchable by dateRange
- Reduces main collection size for faster queries
```

---

## Sample Data Generation (Development)

### Create 5 Test Fines
```javascript
// Firebase Console -> Firestore -> Run Query

// Add test data
db.collection("amendes").add({
  userId: "user_123",
  agentId: "agent_456",
  location: "Avenue Habib Bourguiba",
  type: "speeding",
  amount: 150.0,
  violationDate: new Date("2025-11-12"),
  createdDate: new Date(),
  status: "unpaid",
  isDeleted: false
});

db.collection("amendes").add({
  userId: "user_123",
  agentId: "agent_456",
  location: "Downtown Tunis",
  type: "parking",
  amount: 75.0,
  violationDate: new Date("2025-11-10"),
  createdDate: new Date(),
  status: "paid",
  isDeleted: false
});

// ... add more
```

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to get user role
    function getUserRole(uid) {
      return get(/databases/$(database)/documents/users/$(uid)).data.role;
    }
    
    // Amendes collection
    match /amendes/{amendeId} {
      
      // READ: Users see their own fines, Agents/Admins see all
      allow read: if 
        request.auth.uid == resource.data.userId ||
        getUserRole(request.auth.uid) in ['agent', 'admin'];
      
      // CREATE: Only agents and admins can create
      allow create: if 
        getUserRole(request.auth.uid) in ['agent', 'admin'] &&
        request.resource.data.userId != null &&
        request.resource.data.agentId != null &&
        request.resource.data.location != null &&
        request.resource.data.type != null &&
        request.resource.data.amount > 0 &&
        request.resource.data.status == 'unpaid' &&
        request.resource.data.isDeleted == false;
      
      // UPDATE: 
      // - Users can only change status to 'paid' or 'contested'
      // - Admins can change anything
      allow update: if 
        (request.auth.uid == resource.data.userId && 
         (request.resource.data.status in ['paid', 'contested'] || 
          request.resource.data.contestationReason != null)) ||
        getUserRole(request.auth.uid) == 'admin';
      
      // DELETE: Only admins can delete
      allow delete: if 
        getUserRole(request.auth.uid) == 'admin';
    }
  }
}
```

---

## Monitoring & Logging

### Recommended Logging Events
```dart
// When fine is created
logger.log('amende_created', {
  'amendeId': amendeId,
  'userId': userId,
  'agentId': agentId,
  'amount': amount,
});

// When status changes
logger.log('amende_status_changed', {
  'amendeId': amendeId,
  'oldStatus': oldStatus,
  'newStatus': newStatus,
  'timestamp': DateTime.now(),
});

// When fine is contested
logger.log('amende_contested', {
  'amendeId': amendeId,
  'reason': reason,
  'contestedAt': DateTime.now(),
});

// When fine is deleted
logger.log('amende_deleted', {
  'amendeId': amendeId,
  'deletedAt': DateTime.now(),
  'deletedBy': adminId,
});
```

---

## Performance Optimization Tips

### 1. Use Pagination
```dart
.limit(20)  // Load 20 at a time
```

### 2. Index Complex Queries
- Already defined in "Firestore Indexes Required" section

### 3. Batch Operations
```dart
final batch = _db.batch();
batch.update(doc1, data1);
batch.update(doc2, data2);
await batch.commit();
```

### 4. Filter Before Downloading
```dart
// ✅ Good: Filter in Firestore
.where('status', '==', 'unpaid')

// ❌ Avoid: Download all and filter in app
.get().then((docs) => docs.where(...))
```

### 5. Cache User's Fines Locally
```dart
class AmendeCache {
  static final Map<String, List<Amende>> _cache = {};
  
  static void set(String userId, List<Amende> amendes) {
    _cache[userId] = amendes;
  }
  
  static List<Amende>? get(String userId) => _cache[userId];
}
```

---

## Migration from Old System

If migrating existing data:

```dart
// Step 1: Export old fine data
List<OldFine> oldFines = await database.getOldFines();

// Step 2: Transform to new format
List<Amende> newAmendes = oldFines.map((old) => Amende(
  id: Uuid().v4(),
  userId: old.violatorId,
  agentId: old.officerId,
  location: old.location,
  type: _mapType(old.violationType),
  amount: old.amount.toDouble(),
  violationDate: old.violationDate,
  createdDate: old.createdDate,
  status: _mapStatus(old.paymentStatus),
  isDeleted: false,
)).toList();

// Step 3: Upload to Firestore
for (var amende in newAmendes) {
  await _db.collection('amendes').doc(amende.id).set(amende.toJson());
}

// Step 4: Verify and clean up old data
```

---

## Firestore Console URL

```
https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/databases/(default)/data
```

---

## Exporting & Reporting

### Export All Fines to CSV
```dart
Future<String> exportToCSV(String userId) async {
  final amendes = await getAmendesForExport(userId);
  
  String csv = 'ID,Type,Location,Amount,Status,Date\n';
  for (var a in amendes) {
    csv += '${a.id},${a.getTypeLabel()},${a.location},${a.amount},${a.getStatusLabel()},${a.violationDate}\n';
  }
  
  return csv;
}
```

---

## Notes

- Document IDs use UUID v4 for uniqueness
- All timestamps use ISO 8601 format
- Soft delete allows recovery within retention period
- Indexes automatically created when queries are run in Firebase Console
- Consider regional deployment for data residency compliance

