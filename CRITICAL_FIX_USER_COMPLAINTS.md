# 🔥 CRITICAL FIX: user_complaints Collection Rules

## 🚨 Issue: Complaint Submission Still Failed

**Error:**
```
Failed to submit complaint: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

---

## 🔍 Root Cause

**The Problem:**
- Added security rules for `complaints` collection ✅
- BUT the app actually uses `user_complaints` collection ❌
- No rules existed for `user_complaints` → Default deny all

**Code Evidence:**
```dart
// lib/services/complaint_service.dart (line 46)
final docRef = await _firestore
    .collection('user_complaints')  // ← ACTUAL collection name
    .add(complaint);
```

**Previous Rules:**
```javascript
match /complaints/{complaintId} {  // ← Wrong collection name!
  // Rules here...
}
```

---

## ✅ Solution

Added identical security rules for **`user_complaints`** collection:

```javascript
match /user_complaints/{complaintId} {
  // Helper: Check complaint ownership
  function isComplaintOwner() {
    return isAuthenticated() &&
           (resource.data.userId == request.auth.uid ||
            resource.data.user_id == request.auth.uid);
  }
  
  // List complaints (authenticated users)
  allow list: if isAuthenticated();
  
  // Read complaint (owner or admin)
  allow get: if isComplaintOwner() || isAdmin();
  
  // Create complaint (user must be complainant)
  allow create: if isAuthenticated() &&
                   (request.resource.data.userId == request.auth.uid ||
                    request.resource.data.user_id == request.auth.uid);
  
  // Update complaint (admin or owner for pending)
  allow update: if isAdmin() ||
                   (isComplaintOwner() &&
                    resource.data.status == 'pending');
  
  // Delete (admin only)
  allow delete: if isAdmin();
}
```

---

## 📊 Indexes Added

Added composite indexes for `user_complaints`:

**Index 1 - User's Complaints:**
```json
{
  "collectionGroup": "user_complaints",
  "fields": [
    {"fieldPath": "user_id", "order": "ASCENDING"},
    {"fieldPath": "created_at", "order": "DESCENDING"}
  ]
}
```

**Index 2 - Complaints by Status:**
```json
{
  "collectionGroup": "user_complaints",
  "fields": [
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "created_at", "order": "DESCENDING"}
  ]
}
```

---

## 🚀 Deployment

**Deploy Updated Rules:**
```bash
firebase deploy --only firestore:rules
```

**Deploy Updated Indexes:**
```bash
firebase deploy --only firestore:indexes
```

---

## 🧪 Testing

After deployment, test complaint submission:

```dart
await ComplaintService().submitComplaint(
  userId: currentUserId,
  userName: 'Test User',
  subject: 'Test Complaint',
  description: 'Testing complaint submission',
  category: ComplaintCategory.technical,
  priority: ComplaintPriority.medium,
);
```

**Expected Result:** ✅ Complaint submitted successfully (no permission error)

---

## 📝 Collection Names Summary

| Collection Name | Used By | Rules Status |
|----------------|---------|--------------|
| `user_complaints` | Main app (complaint_service.dart, admin_service.dart) | ✅ Fixed |
| `complaints` | CSV export service | ✅ Has rules |

Both collections now have proper security rules.

---

**Last Updated:** December 2024  
**Issue:** Fixed missing rules for user_complaints collection  
**Status:** RESOLVED
