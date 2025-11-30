# 🔓 Premium Fields to Add for Abby Rukundo

## 📋 Current User Document Status

**User ID**: `h6zCXIW7SjX0bEG1PYpTvpJrLSx1`  
**Email**: datacollectorslimited@gmail.com  
**Name**: abby rukundo sme  
**Role**: sme ✅  
**Profile Complete**: true ✅  

---

## ➕ Fields to ADD to This User Document

Go to Firebase Console and add these fields to the user document:

### 1️⃣ has_premium_access
```
Field name: has_premium_access
Type: boolean
Value: true
```

### 2️⃣ subscription_status
```
Field name: subscription_status
Type: string
Value: active
```

### 3️⃣ subscription_plan
```
Field name: subscription_plan
Type: string
Value: premium_test
```

### 4️⃣ premium_features (MAP - Important!)
```
Field name: premium_features
Type: map

ADD THESE NESTED FIELDS INSIDE THE MAP:

  Nested field 1:
  Field name: farmer_directory
  Type: boolean
  Value: true

  Nested field 2:
  Field name: advanced_search
  Type: boolean
  Value: true

  Nested field 3:
  Field name: bulk_messaging
  Type: boolean
  Value: true

  Nested field 4:
  Field name: export_contacts
  Type: boolean
  Value: true
```

### 5️⃣ subscription_start
```
Field name: subscription_start
Type: timestamp
Value: Click "Set to current time"
```

### 6️⃣ subscription_expiry
```
Field name: subscription_expiry
Type: timestamp
Value: Set to: 2026-01-29
       (or January 29, 2026, 00:00:00)
```

### 7️⃣ UPDATE existing updated_at field
```
Field name: updated_at (already exists)
Type: timestamp
Value: Click "Set to current time"
```

---

## 🔗 Direct Link to User Document

**Firebase Console Path**:
```
Firestore Database → users → h6zCXIW7SjX0bEG1PYpTvpJrLSx1
```

**Direct Link**:
https://console.firebase.google.com/project/sayekataleapp/firestore/databases/-default-/data/~2Fusers~2Fh6zCXIW7SjX0bEG1PYpTvpJrLSx1

---

## ✅ After Adding Fields, Document Should Look Like:

```
User Document: h6zCXIW7SjX0bEG1PYpTvpJrLSx1
├── created_at: "2025-11-12T00:27:43.678"
├── disability_status: "no"
├── email: "datacollectorslimited@gmail.com"
├── fcm_token: "fWPdYv_rSHWIYhke3WMy8L..."
├── id: "h6zCXIW7SjX0bEG1PYpTvpJrLSx1"
├── is_profile_complete: true
├── is_suspended: false
├── is_verified: false
├── location: { district, latitude, longitude, parish, subcounty, village }
├── name: "abby rukundo sme"
├── name_on_id_photo: "Abby Rukundo Sme"
├── national_id: "CM900371081WYE"
├── national_id_photo: "https://..."
├── partner_info: null
├── phone: "0744646069"
├── profile_completion_deadline: "2025-11-13T00:27:43.678"
├── profile_image: "https://..."
├── role: "sme"
├── sex: "MALE"
├── system_id: "SME-00001"
├── verification_status: "pending"
│
├── ⭐ has_premium_access: true                    [NEW - ADD THIS]
├── ⭐ subscription_status: "active"                [NEW - ADD THIS]
├── ⭐ subscription_plan: "premium_test"            [NEW - ADD THIS]
├── ⭐ premium_features: {                          [NEW - ADD THIS]
│       farmer_directory: true,
│       advanced_search: true,
│       bulk_messaging: true,
│       export_contacts: true
│   }
├── ⭐ subscription_start: <current_timestamp>      [NEW - ADD THIS]
├── ⭐ subscription_expiry: 2026-01-29              [NEW - ADD THIS]
└── updated_at: <current_timestamp>                [UPDATE THIS]
```

---

## 🎯 Quick Action Steps

1. **Open**: https://console.firebase.google.com/project/sayekataleapp/firestore

2. **Navigate**: 
   - Firestore Database
   - Click on `users` collection
   - Find and click on document: `h6zCXIW7SjX0bEG1PYpTvpJrLSx1`

3. **Add Fields**: Click "Add field" button 7 times to add all fields above

4. **Save**: Click "Update" button

5. **Test**: 
   - User logs out from app
   - User logs back in
   - Verify premium features are accessible

---

## 🧪 Testing Credentials

**Web App**: https://5060-in9hu1x2vblsbdru37ud5-18e660f9.sandbox.novita.ai

**Login**:
- Email: datacollectorslimited@gmail.com
- Password: <user's password>

**Verify After Login**:
- ✅ "Premium Member" badge visible
- ✅ Farmer Directory section accessible
- ✅ Advanced search filters available
- ✅ Bulk messaging functionality
- ✅ Export to CSV button visible
- ✅ No "Upgrade to Premium" prompts

---

## ⏱️ Time Required

- **Adding fields**: 5 minutes
- **User logout/login**: 1 minute
- **Testing**: 3 minutes
- **Total**: ~10 minutes

---

## 📞 Need Help?

See detailed guides:
- `FIREBASE_CONSOLE_STEPS.txt` - Step-by-step visual guide
- `PREMIUM_UNLOCK_QUICK_GUIDE.md` - Quick reference
- `UNLOCK_PREMIUM_FARMER_DIRECTORY_GUIDE.md` - Complete guide

---

**Status**: ✅ Ready to Execute  
**User ID Confirmed**: h6zCXIW7SjX0bEG1PYpTvpJrLSx1  
**Email Verified**: datacollectorslimited@gmail.com  
**Role Verified**: sme ✅  
