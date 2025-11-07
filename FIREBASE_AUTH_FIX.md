# 🔥 Firebase Authentication Error - Complete Fix Guide

## 🔴 Error You're Seeing

**Common Firebase Auth Errors:**
- "Firebase: Error (auth/unauthorized-domain)"
- "This domain is not authorized for OAuth operations"
- "Firebase Auth error" in console

---

## ✅ SOLUTION: Add Sandbox Domain to Firebase

The sandbox domain needs to be authorized in your Firebase Console.

### **Step 1: Go to Firebase Console**

1. Open: https://console.firebase.google.com/
2. Select project: **sayekataleapp**
3. If you don't see your project, check you're logged in with the correct Google account

---

### **Step 2: Navigate to Authentication Settings**

1. In left sidebar, click **"Build"** → **"Authentication"**
2. Click the **"Settings"** tab (top of page)
3. Scroll down to **"Authorized domains"** section

---

### **Step 3: Add Sandbox Domain**

**Domain to Add:**
```
sandbox.novita.ai
```

**Steps:**
1. Click **"Add domain"** button
2. Enter: `sandbox.novita.ai`
3. Click **"Add"**
4. Wait a few seconds for changes to propagate

**Screenshot Guide:**
```
┌─ Authorized domains ──────────────────────┐
│                                            │
│ These domains are authorized to show      │
│ OAuth identity provider sign-in flows:    │
│                                            │
│ ✓ localhost                                │
│ ✓ sayekataleapp.firebaseapp.com          │
│ ✓ sandbox.novita.ai  ← ADD THIS          │
│                                            │
│ [+ Add domain]                             │
└────────────────────────────────────────────┘
```

---

### **Step 4: Verify the Fix**

After adding the domain:

1. **Hard refresh** your browser: `Ctrl + Shift + R` (Windows) or `Cmd + Shift + R` (Mac)
2. **Clear browser cache** completely
3. **Reopen the app**: https://5060-i25ra390rl3tp6c83ufw7-583b4d74.sandbox.novita.ai
4. **Try registering** a new account

**Expected Result:** ✅ Registration/Login works without errors!

---

## 🔍 How to Check What Domain to Add

If you need to find the exact domain:

1. Look at your app URL in the browser
2. Extract the domain part after `https://`

**Example:**
- App URL: `https://5060-i25ra390rl3tp6c83ufw7-583b4d74.sandbox.novita.ai`
- Domain to add: `sandbox.novita.ai`

**OR use wildcard:**
- Add: `*.sandbox.novita.ai` (allows all subdomains)

---

## 🐛 Alternative: Check Other Common Issues

If adding the domain doesn't fix it, check these:

### **Issue 1: API Key Invalid**

**Check:**
```dart
// In lib/firebase_options.dart
apiKey: 'AIzaSyAR4WdX7MsctO7aSX_vfqKMZbIUOxrnMlg'
```

**Fix:** 
1. Go to Firebase Console → Project Settings → General
2. Copy Web API key
3. Update `firebase_options.dart` with correct key

---

### **Issue 2: Authentication Not Enabled**

**Check:**
1. Firebase Console → Authentication → Sign-in method
2. Verify **Email/Password** is enabled (toggle should be ON)

**Fix:**
1. Click on "Email/Password"
2. Toggle **Enable** switch to ON
3. Click **Save**

---

### **Issue 3: Browser Cookies Blocked**

**Check:** Browser settings allow third-party cookies

**Fix:**
1. Chrome: Settings → Privacy and security → Cookies
2. Allow: "Include all cookies"
3. Or add exception for `firebaseapp.com`

---

## 🔧 Quick Fixes to Try

### **Fix 1: Hard Refresh Browser**
```
Windows/Linux: Ctrl + Shift + R
Mac: Cmd + Shift + R
```

### **Fix 2: Clear Browser Cache**
```
Chrome: Ctrl + Shift + Delete
Select: "Cached images and files"
Click: "Clear data"
```

### **Fix 3: Try Incognito/Private Mode**
- Opens without cache or extensions
- Good for testing if issue is browser-related

### **Fix 4: Try Different Browser**
- **Recommended:** Chrome (best Firebase support)
- Alternative: Firefox, Edge
- Avoid: Safari, old browsers

---

## 📝 Step-by-Step Firebase Console Guide

### **Complete Walkthrough:**

1. **Open Firebase Console**
   - URL: https://console.firebase.google.com/
   - Login with Google account

2. **Select Project**
   - Click on project card: "sayekataleapp"
   - Or use dropdown at top if multiple projects

3. **Go to Authentication**
   - Left sidebar → "Build" section
   - Click "Authentication"

4. **Open Settings Tab**
   - At top of Authentication page
   - Click "Settings" tab (next to "Users")

5. **Find Authorized Domains**
   - Scroll down the Settings page
   - Look for "Authorized domains" section

6. **Add Domain**
   - Click blue "+ Add domain" button
   - Type: `sandbox.novita.ai`
   - Click "Add" button

7. **Wait & Test**
   - Wait 10-30 seconds for propagation
   - Hard refresh your app
   - Try registration/login

---

## ✅ Verification Checklist

After adding the domain, verify:

- [ ] Domain appears in "Authorized domains" list
- [ ] Shows green checkmark or "verified" status
- [ ] No error message next to domain
- [ ] Can see the domain in the list

Then test the app:

- [ ] Hard refresh browser (Ctrl+Shift+R)
- [ ] Open app fresh
- [ ] Try to register new account
- [ ] No Firebase auth errors in console
- [ ] Registration completes successfully

---

## 🎯 Success Indicators

**You'll know it's fixed when:**
- ✅ No "unauthorized-domain" errors
- ✅ Registration form works
- ✅ Login works
- ✅ No Firebase errors in browser console
- ✅ Can create and login with test accounts

---

## 📞 Still Not Working?

If you've added the domain and still see errors:

### **1. Check Browser Console**
1. Press F12 to open DevTools
2. Click "Console" tab
3. Look for red error messages
4. Copy the **exact error message**

### **2. Common Error Messages:**

**"auth/invalid-api-key"**
→ API key in firebase_options.dart is wrong

**"auth/network-request-failed"**
→ Internet connection or firewall issue

**"auth/unauthorized-domain"**
→ Domain not added yet (wait longer or refresh)

**"auth/operation-not-allowed"**
→ Email/Password auth not enabled in Firebase Console

### **3. Get Help:**
Share these details:
- Exact error message from console
- Screenshot of error
- Screenshot of Firebase Authorized Domains list
- Confirm you added `sandbox.novita.ai`

---

## 🚀 Quick Test After Fix

**Test Registration:**
```
Email: test@example.com
Phone: +256700000099
Password: Test123!
Role: SME
```

**Expected Result:**
- ✅ Registration form submits
- ✅ Account created in Firebase
- ✅ Redirected to dashboard
- ✅ No errors in console

---

## 📊 Firebase Configuration Summary

**Your Current Setup:**
- **Project ID:** sayekataleapp
- **Auth Domain:** sayekataleapp.firebaseapp.com
- **API Key:** AIzaSyAR4WdX7MsctO7aSX_vfqKMZbIUOxrnMlg
- **Storage:** sayekataleapp.firebasestorage.app

**Required Authorized Domains:**
1. ✅ localhost (already there)
2. ✅ sayekataleapp.firebaseapp.com (already there)
3. ⚠️ **sandbox.novita.ai** (YOU NEED TO ADD THIS!)

---

## 🎯 Summary

**Problem:** Firebase doesn't allow auth from sandbox.novita.ai domain

**Solution:** Add `sandbox.novita.ai` to Firebase authorized domains

**Steps:**
1. Firebase Console → Authentication → Settings
2. Scroll to "Authorized domains"
3. Click "+ Add domain"
4. Enter: `sandbox.novita.ai`
5. Click "Add"
6. Hard refresh app

**Time to fix:** 2-3 minutes

**After fix:** All Firebase auth will work perfectly! ✅

---

## 📱 App URL

**Current App:** https://5060-i25ra390rl3tp6c83ufw7-583b4d74.sandbox.novita.ai

**Domain to authorize:** `sandbox.novita.ai`

**Firebase Console:** https://console.firebase.google.com/project/sayekataleapp/authentication/settings

---

**That's it! Once you add the domain, Firebase authentication will work! 🎉**
