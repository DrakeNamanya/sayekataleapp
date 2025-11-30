# PSA Document Storage Path Fix

## 🎯 Issue Identified

User reported that PSA verification documents should be uploaded to:
```
gs://sayekataleapp.firebasestorage.app/psa_verifications/
```

But the system was uploading to:
```
gs://sayekataleapp.firebasestorage.app/psa_verifications/{userId}/
```

This extra `{userId}` subfolder was incorrect.

---

## 🔧 Fix Applied

### 1. Added `useUserSubfolder` Parameter
**File**: `lib/services/image_storage_service.dart`

Added a new optional parameter to control whether to use userId subfolder:

```dart
Future<String> uploadImageFromXFile({
  required XFile imageFile,
  required String folder,
  required String userId,
  String? customName,
  bool compress = true,
  bool useUserSubfolder = true, // NEW parameter
}) async {
  // ...
  
  // Create storage path based on parameter
  final storagePath = useUserSubfolder 
      ? '$folder/$userId/$filename'  // Default behavior
      : '$folder/$filename';          // PSA verifications
}
```

### 2. Updated PSA Verification Uploads
**File**: `lib/screens/psa/psa_verification_form_screen.dart`

Set `useUserSubfolder: false` for all PSA document uploads:

```dart
// Business License
_businessLicenseUrl = await _imageStorageService.uploadImageFromXFile(
  imageFile: _businessLicenseFile!,
  folder: 'psa_verifications',
  userId: psaId,
  customName: 'business_license_${psaId}_${timestamp}',
  compress: false,
  useUserSubfolder: false, // Upload directly to psa_verifications/
);

// Tax ID Document
_taxIdDocumentUrl = await _imageStorageService.uploadImageFromXFile(
  imageFile: _taxIdDocumentFile!,
  folder: 'psa_verifications',
  userId: psaId,
  customName: 'tax_id_document_${psaId}_${timestamp}',
  compress: false,
  useUserSubfolder: false,
);

// National ID
_nationalIdUrl = await _imageStorageService.uploadImageFromXFile(
  imageFile: _nationalIdFile!,
  folder: 'psa_verifications',
  userId: psaId,
  customName: 'national_id_${psaId}_${timestamp}',
  compress: false,
  useUserSubfolder: false,
);

// Trade License
_tradeLicenseUrl = await _imageStorageService.uploadImageFromXFile(
  imageFile: _tradeLicenseFile!,
  folder: 'psa_verifications',
  userId: psaId,
  customName: 'trade_license_${psaId}_${timestamp}',
  compress: false,
  useUserSubfolder: false,
);
```

---

## 📁 Storage Structure

### Before Fix:
```
gs://sayekataleapp.firebasestorage.app/
└── psa_verifications/
    └── {userId}/                          ← WRONG! Extra subfolder
        ├── business_license_1234567890.jpg
        ├── tax_id_document_1234567890.jpg
        ├── national_id_1234567890.jpg
        └── trade_license_1234567890.jpg
```

### After Fix:
```
gs://sayekataleapp.firebasestorage.app/
└── psa_verifications/                     ← CORRECT! Direct uploads
    ├── business_license_{psaId}_1234567890.jpg
    ├── tax_id_document_{psaId}_1234567890.jpg
    ├── national_id_{psaId}_1234567890.jpg
    └── trade_license_{psaId}_1234567890.jpg
```

---

## 🏷️ File Naming Convention

Documents are now named with PSA ID for easy identification:

| Document Type | Filename Format | Example |
|--------------|----------------|---------|
| **Business License** | `business_license_{psaId}_{timestamp}.jpg` | `business_license_abc123_1701234567890.jpg` |
| **Tax ID Document** | `tax_id_document_{psaId}_{timestamp}.jpg` | `tax_id_document_abc123_1701234567891.jpg` |
| **National ID** | `national_id_{psaId}_{timestamp}.jpg` | `national_id_abc123_1701234567892.jpg` |
| **Trade License** | `trade_license_{psaId}_{timestamp}.jpg` | `trade_license_abc123_1701234567893.jpg` |

**Benefits**:
- ✅ Easy to identify which PSA uploaded the document
- ✅ Unique timestamps prevent filename collisions
- ✅ All documents in one flat folder structure
- ✅ Simple for admin to browse and manage

---

## 🔍 Verification in Firebase Console

To verify documents are uploaded correctly:

1. Go to **Firebase Console** → **Storage**
2. Navigate to: `gs://sayekataleapp.firebasestorage.app/`
3. Open **`psa_verifications/`** folder
4. You should see files like:
   ```
   business_license_abc123_1701234567890.jpg
   tax_id_document_abc123_1701234567891.jpg
   national_id_abc123_1701234567892.jpg
   trade_license_abc123_1701234567893.jpg
   ```

**What to Check**:
- ✅ Files are directly in `psa_verifications/` (not in subfolders)
- ✅ Filenames include PSA ID
- ✅ Filenames include timestamp
- ✅ Files are accessible (correct permissions)

---

## 🧪 Testing Instructions

### Test 1: Upload PSA Verification Documents

**Steps**:
1. Login as PSA
2. Fill verification form (all 6 steps)
3. Upload all 4 documents in Step 5
4. Submit verification

**Expected Results**:
- ✅ Documents upload successfully
- ✅ No errors during upload
- ✅ Success message appears
- ✅ Verification submitted to admin

**Verify in Firebase Console**:
- ✅ Check `gs://sayekataleapp.firebasestorage.app/psa_verifications/`
- ✅ 4 new files should appear
- ✅ Filenames follow format: `{type}_{psaId}_{timestamp}.jpg`
- ✅ Files are NOT in userId subfolder

---

### Test 2: Admin Views Documents

**Steps**:
1. Login as admin
2. Go to PSA Verifications
3. Open a verification with uploaded documents
4. Click to view each document

**Expected Results**:
- ✅ All 4 documents load correctly
- ✅ Images display properly
- ✅ Can zoom/preview documents
- ✅ Download links work

---

### Test 3: Multiple PSAs Upload Documents

**Steps**:
1. Login as PSA 1, upload documents
2. Login as PSA 2, upload documents
3. Login as PSA 3, upload documents
4. Check Firebase Storage

**Expected Results**:
- ✅ All documents in same `psa_verifications/` folder
- ✅ Each PSA's documents have unique filenames (psaId + timestamp)
- ✅ No filename collisions
- ✅ Easy to identify owner by psaId in filename

---

## 🚀 GitHub Status

**Repository**: https://github.com/DrakeNamanya/sayekataleapp

**Latest Commit**: `abaebf7`
- "fix: Upload PSA verification documents directly to psa_verifications folder"

**Commit History**:
- `abaebf7` - Storage path fix (direct to psa_verifications/)
- `14aaefc` - Update user verification status after submission
- `a07c279` - Add Submit Verification button
- `4a88c02` - Complete PSA registration flow

**Status**: ✅ **ALL FIXES COMMITTED AND PUSHED**

---

## ✅ Benefits of This Fix

### 1. Correct Storage Location
- ✅ Documents in correct Firebase Storage path
- ✅ Matches expected structure: `gs://sayekataleapp.firebasestorage.app/psa_verifications/`

### 2. Easy Management
- ✅ All PSA documents in one folder
- ✅ No nested subfolders to navigate
- ✅ Simple to browse and audit

### 3. Clear Identification
- ✅ PSA ID in filename
- ✅ Document type in filename
- ✅ Timestamp for uniqueness

### 4. Scalability
- ✅ Works for any number of PSAs
- ✅ No folder structure limits
- ✅ Efficient storage organization

---

## 📱 Complete PSA Verification Flow (Updated)

```
1. PSA registers → Redirects to verification form
   ↓
2. PSA fills 6-step form
   ↓
3. PSA uploads 4 documents in Step 5
   ↓
4. PSA clicks "Submit Verification"
   ↓
5. ✅ Documents upload to: gs://sayekataleapp.firebasestorage.app/psa_verifications/
   (No userId subfolder!)
   ↓
6. ✅ Document URLs saved to verification record
   ↓
7. ✅ User status updated to 'inReview'
   ↓
8. ✅ Admin receives complete verification
   ↓
9. Admin views documents (all 4 accessible)
   ↓
10. Admin approves verification
    ↓
11. ✅ PSA gets dashboard access
```

---

## 🔐 Firebase Storage Security Rules

Make sure Firebase Storage rules allow PSA uploads to `psa_verifications/`:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // PSA Verifications - PSAs can upload their documents
    match /psa_verifications/{filename} {
      allow read: if request.auth != null; // Any authenticated user can read
      allow write: if request.auth != null; // Any authenticated user can upload
    }
  }
}
```

**Note**: Adjust permissions based on your security requirements.

---

**Test URL**: https://5060-in9hu1x2vblsbdru37ud5-18e660f9.sandbox.novita.ai

**Status**: 🟢 STORAGE PATH FIX APPLIED

**Critical Change**: PSA documents now upload directly to `psa_verifications/` without userId subfolder!

**Date**: November 29, 2025
