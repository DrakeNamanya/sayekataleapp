# ⚡ Premium Farmer Directory - Quick Unlock Guide

## 🎯 Quick Action Required

**User**: Abby Rukundo (datacollectorslimited@gmail.com)  
**Feature**: Premium Farmer Directory Access  
**Duration**: 1 year (testing)

---

## 🚀 FASTEST METHOD: Firebase Console (5 Minutes)

### Step 1: Open Firestore Database

Go to: **https://console.firebase.google.com/project/sayekataleapp/firestore/databases/-default-/data/~2Fusers**

### Step 2: Find User Document

1. Click on **"users"** collection
2. Search for email: **datacollectorslimited@gmail.com**
3. Click on the user document (should show "Abby Rukundo")

### Step 3: Add These Exact Fields

Click **"Add field"** and enter these fields ONE BY ONE:

```
Field Name: has_premium_access
Type: boolean
Value: true
```

```
Field Name: subscription_status
Type: string
Value: active
```

```
Field Name: subscription_plan
Type: string
Value: premium_test
```

```
Field Name: premium_features
Type: map
Add nested fields:
  - farmer_directory: boolean = true
  - advanced_search: boolean = true
  - bulk_messaging: boolean = true
  - export_contacts: boolean = true
```

```
Field Name: subscription_start
Type: timestamp
Value: <Click "Set to current time">
```

```
Field Name: subscription_expiry
Type: timestamp
Value: <Set to 2026-01-29 (1 year from now)>
```

### Step 4: Update Timestamp

```
Field Name: updated_at
Type: timestamp
Value: <Click "Set to current time">
```

### Step 5: Save Changes

Click **"Update"** button at the bottom.

---

## ✅ Verification

After saving, verify the user document looks like this:

```json
{
  "name": "Abby Rukundo",
  "email": "datacollectorslimited@gmail.com",
  "role": "sme",
  "has_premium_access": true,
  "subscription_status": "active",
  "subscription_plan": "premium_test",
  "premium_features": {
    "farmer_directory": true,
    "advanced_search": true,
    "bulk_messaging": true,
    "export_contacts": true
  },
  "subscription_start": "2025-01-29T...",
  "subscription_expiry": "2026-01-29T...",
  "updated_at": "2025-01-29T..."
}
```

---

## 🧪 Testing

### Test Login:

1. **Web App**: https://5060-in9hu1x2vblsbdru37ud5-18e660f9.sandbox.novita.ai
2. **Email**: datacollectorslimited@gmail.com
3. **Password**: <user's password>

### Test Premium Features:

After login, check:

✅ **SME Dashboard** - Shows "Premium Member" badge  
✅ **Farmer Directory** - Fully accessible without upgrade prompts  
✅ **Advanced Search** - All filter options available  
✅ **Bulk Messaging** - Can select and message multiple farmers  
✅ **Export Contacts** - Can download farmer lists as CSV

---

## 🔧 Alternative Methods

If you prefer automated approaches, see these files:

1. **Python Script**: `/home/user/unlock_premium_farmer_directory.py`
   - Requires: Firebase Admin SDK service account key
   - Usage: `python3 unlock_premium_farmer_directory.py`

2. **JavaScript/Node.js**: `/home/user/unlock_premium_firestore_manual.js`
   - Three methods: Console, Cloud Function, CLI
   - Full automation with logging

3. **Complete Guide**: `/home/user/UNLOCK_PREMIUM_FARMER_DIRECTORY_GUIDE.md`
   - Detailed instructions for all methods
   - Troubleshooting section
   - Testing guidelines

---

## 📊 What Gets Unlocked

After completing the steps above, Abby Rukundo will have:

| Feature | Description | Status |
|---------|-------------|--------|
| **Farmer Directory** | View all registered farmers | ✅ Unlocked |
| **Advanced Search** | Filter by location, crops, ratings | ✅ Unlocked |
| **Bulk Messaging** | Send messages to multiple farmers | ✅ Unlocked |
| **Export Contacts** | Download farmer data as CSV | ✅ Unlocked |
| **Premium Support** | Priority customer support | ✅ Unlocked |

**Subscription Valid Until**: January 29, 2026 (1 year)

---

## 🚨 Troubleshooting

### Issue: Can't find user document

**Solution**: 
- Verify email is exactly: `datacollectorslimited@gmail.com`
- Check if user has registered in the app
- Try searching in Firestore manually

### Issue: Fields not saving

**Solution**:
- Ensure you're in the correct Firestore database
- Check Firebase project: `sayekataleapp`
- Verify you have write permissions

### Issue: Premium features not showing in app

**Solution**:
1. User should logout and login again
2. Clear app cache
3. Force refresh the app
4. Verify the Firestore fields were saved correctly

---

## ✅ Success Checklist

- [ ] Opened Firebase Console
- [ ] Found user document for datacollectorslimited@gmail.com
- [ ] Added `has_premium_access: true`
- [ ] Added `subscription_status: 'active'`
- [ ] Added `premium_features` map with all 4 features
- [ ] Set `subscription_expiry` to 1 year from now
- [ ] Clicked "Update" to save
- [ ] User logged out and back in
- [ ] Farmer Directory is accessible
- [ ] No "Upgrade to Premium" prompts

---

**Created**: 2025-01-29  
**Status**: ⚠️ Manual Action Required  
**Time Required**: 5-10 minutes
