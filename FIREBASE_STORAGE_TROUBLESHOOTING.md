# Firebase Storage "Not Authorized" Error - Troubleshooting Guide

## Error Message
```
Exception: Failed to upload image: [firebase_storage/unauthorized] User is not authorized to perform the desired action.
```

## Root Causes & Solutions

### 1. ⚠️ **Firebase Storage Rules Not Updated (Most Common)**

**Problem:** The default Firebase Storage rules still deny all access.

**Solution:**
1. Go to **Firebase Console** → **Storage** → **Rules** tab
2. **Delete ALL existing rules** (including the default `allow read, write: if false;`)
3. Copy the rules from `/home/user/flutter_app/storage_rules_development.txt`
4. Paste into the Firebase Console
5. Click **"Publish"**
6. **Wait 30-60 seconds** for rules to propagate globally

**Simplified Development Rules** (from storage_rules_development.txt):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profiles/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.resource.size < 5 * 1024 * 1024;
    }
    match /national_ids/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.resource.size < 10 * 1024 * 1024;
    }
    match /products/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.resource.size < 5 * 1024 * 1024;
    }
  }
}
```

**Key Differences from Previous Rules:**
- ✅ Removed `request.auth.uid == userId` check (was too restrictive during testing)
- ✅ Removed `contentType.matches('image/.*')` check (was causing issues)
- ✅ Only checks: User is authenticated + File size limit
- ⚠️ **Note:** These are permissive development rules. Use production rules later.

---

### 2. 🔐 **User Not Authenticated**

**Problem:** User is not logged in when trying to upload.

**How to Check:**
- Open browser console (F12)
- Look for diagnostic logs starting with `🔍`
- Check if you see: `❌ NOT AUTHENTICATED - User is null!`

**Solution:**
1. Make sure you're logged in to the app
2. Go to Profile → Edit Profile
3. If not logged in, logout and login again
4. Try upload again

---

### 3. 🆔 **User ID Mismatch**

**Problem:** The authenticated user's ID doesn't match the storage path.

**How to Check:**
- Browser console should show:
  ```
  ❌ Upload check failed: User ID mismatch
     - Authenticated user: abc123
     - Requested userId: xyz789
  ```

**Solution:**
- This is a code bug. Contact developer if you see this.

---

### 4. ⏱️ **Rules Propagation Delay**

**Problem:** Rules were just published but haven't taken effect yet.

**Solution:**
- Wait 30-60 seconds after publishing rules
- Refresh the browser page
- Try upload again

---

### 5. 🌐 **Browser Cache Issues**

**Problem:** Old authentication tokens cached in browser.

**Solution:**
1. Open browser console (F12)
2. Go to **Application** tab (Chrome) or **Storage** tab (Firefox)
3. Click **"Clear storage"** or **"Clear site data"**
4. Refresh the page
5. Login again
6. Try upload again

---

## 🔍 How to View Diagnostic Logs

When you try to upload a photo, the app now shows detailed diagnostics in the browser console:

1. Open browser **Developer Tools** (F12 or Right-click → Inspect)
2. Go to **Console** tab
3. Try uploading a photo
4. Look for logs starting with these emojis:
   - `🔍` - Diagnostic information
   - `✅` - Success messages
   - `❌` - Error messages
   - `📂`, `📁`, `☁️` - Upload progress

**Example of Good Diagnostics:**
```
🔍 ==========================================
🔍 FIREBASE STORAGE DIAGNOSTICS
✅ User is authenticated
   - User ID: abc123def456
   - Email: farmer@example.com
📦 Firebase Storage Configuration:
   - Bucket: sayekataleapp.appspot.com
📁 Expected Storage Paths:
   - Profile: profiles/abc123def456/profile_xxx.jpg
🔑 ID Token Status:
   - Token exists: true
✅ Upload check passed for: profiles/abc123def456
☁️ Uploading to Firebase Storage...
✅ Image uploaded successfully: https://...
```

**Example of Problem (Not Authenticated):**
```
🔍 ==========================================
❌ NOT AUTHENTICATED - User is null!
⚠️ This is likely the problem. User must be logged in to upload.
```

---

## ✅ Testing Checklist

After updating Firebase Storage rules:

- [ ] Wait 30-60 seconds for rules to propagate
- [ ] Refresh browser page (Ctrl+F5 or Cmd+Shift+R)
- [ ] Ensure you're logged in to the app
- [ ] Open browser console (F12) to view diagnostics
- [ ] Try uploading a profile photo
- [ ] Check console for diagnostic logs
- [ ] If successful, test product photos
- [ ] Verify photos appear in Firebase Console → Storage

---

## 🆘 Still Not Working?

1. **Verify Rules are Published:**
   - Go to Firebase Console → Storage → Rules
   - Check if the rules match `storage_rules_development.txt`
   - Look for the timestamp "Last modified: ..." to confirm publication

2. **Check Authentication:**
   - Browser console should show: `✅ User is authenticated`
   - If it shows `❌ NOT AUTHENTICATED`, logout and login again

3. **Clear Everything and Start Fresh:**
   ```
   1. Logout from the app
   2. Clear browser cache (Settings → Clear browsing data)
   3. Close and reopen browser
   4. Open app and login again
   5. Try upload with console open
   ```

4. **Check Firebase Storage is Enabled:**
   - Go to Firebase Console → Storage
   - If you see "Get Started" button, click it to enable Storage
   - Follow the wizard to set up Storage

---

## 📊 Expected Behavior After Fix

✅ **Profile photo upload**: Completes in 5-10 seconds
✅ **Console shows**: Diagnostic logs with ✅ success messages
✅ **No errors**: No "not authorized" or "permission denied" errors
✅ **Photo persists**: Photo shows after page reload
✅ **Firebase Storage**: Files appear in organized folders

---

## 🔒 Production Rules (Use Later)

Once testing is complete, replace development rules with production rules that include:
- User ID matching: `request.auth.uid == userId`
- Content type validation: `contentType.matches('image/.*')`
- Stricter access controls

Production rules are in: `/home/user/flutter_app/storage.rules`

---

**Last Updated:** After implementing Firebase Storage diagnostics
**Project:** Sayekatale App - Photo Upload System
