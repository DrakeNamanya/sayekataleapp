# Deploy Firestore Rules with Google Cloud Shell

This guide shows you how to deploy the updated Firestore security rules using Google Cloud Shell Terminal.

---

## 🎯 What This Fixes

Deploying these rules will immediately fix:
- ✅ **Edit Profile permission errors** for SME and SHG users
- ✅ **Profile field updates** (images, location, partner info)
- ✅ Still protects critical fields (`id` and `role` cannot be changed)

---

## 📋 Prerequisites

- Access to Google Cloud Console
- Project: `sayekataleapp`
- Firebase CLI (will be installed automatically if missing)

---

## 🚀 Quick Deployment (5 minutes)

### Option 1: Automated Deployment (Recommended)

**Step 1: Open Google Cloud Shell**
1. Go to: https://console.cloud.google.com/
2. Make sure project `sayekataleapp` is selected
3. Click the **Cloud Shell** icon (>_) in the top-right corner
4. Wait for the terminal to open

**Step 2: Clone Your Repository**
```bash
# Clone the repository (if not already cloned)
git clone https://github.com/DrakeNamanya/sayekataleapp.git
cd sayekataleapp
```

**Step 3: Run the Deployment Script**
```bash
# Make sure you're in the project directory
cd ~/sayekataleapp

# Run the automated deployment script
bash deploy_firestore_rules.sh
```

**Step 4: Follow the Prompts**
- If asked to login to Firebase, run: `firebase login --no-localhost`
- Copy the login URL, open in browser, authorize
- Paste the authorization code back into Cloud Shell
- Script will automatically deploy the rules

**Step 5: Verify Deployment**
- Go to: https://console.firebase.google.com/project/sayekataleapp/firestore/rules
- You should see the new rules deployed
- Check the "Rules" tab shows the updated timestamp

---

### Option 2: Manual Deployment

If the automated script doesn't work, follow these manual steps:

**Step 1: Open Google Cloud Shell**
1. Go to: https://console.cloud.google.com/
2. Select project: `sayekataleapp`
3. Open Cloud Shell (>_ icon)

**Step 2: Install Firebase CLI (if not installed)**
```bash
npm install -g firebase-tools
```

**Step 3: Login to Firebase**
```bash
firebase login --no-localhost
```
- Copy the URL shown in terminal
- Open URL in your browser
- Authorize Firebase CLI
- Copy the authorization code
- Paste it back into Cloud Shell

**Step 4: Clone Repository**
```bash
git clone https://github.com/DrakeNamanya/sayekataleapp.git
cd sayekataleapp
```

**Step 5: Create Firebase Configuration**
```bash
# Create firebase.json
cat > firebase.json << 'EOF'
{
  "firestore": {
    "rules": "firestore.rules"
  }
}
EOF

# Create .firebaserc
cat > .firebaserc << 'EOF'
{
  "projects": {
    "default": "sayekataleapp"
  }
}
EOF
```

**Step 6: Copy Rules File**
```bash
# Copy the updated rules
cp FIRESTORE_RULES_FIX.txt firestore.rules
```

**Step 7: Deploy Rules**
```bash
# Deploy to Firebase
firebase deploy --only firestore:rules
```

**Step 8: Verify Deployment**
```bash
# Should see output like:
# ✔  Deploy complete!
# 
# Project Console: https://console.firebase.google.com/project/sayekataleapp/overview
# Firestore Rules: https://console.firebase.google.com/project/sayekataleapp/firestore/rules
```

---

## 🧪 Testing After Deployment

### Test 1: Edit Profile (SME User)
1. Open SayeKatale app
2. Login as Rita (SME user) or any SME account
3. Navigate to: **Profile → Edit Profile**
4. Try to update:
   - ✅ Profile image
   - ✅ Name, phone number
   - ✅ Location (district, subcounty, etc.)
   - ✅ Partner information
5. Click **Save Profile**
6. **Expected**: Profile updates successfully ✅
7. **Before fix**: "Permission denied" error ❌

### Test 2: Edit Profile (SHG User)
1. Login as SHG user
2. Navigate to: **Profile → Edit Profile**
3. Try to update profile fields
4. Click **Save Profile**
5. **Expected**: Profile updates successfully ✅

### Test 3: Verify Protected Fields
1. Try to modify `role` field manually (should fail)
2. Try to modify `id` field manually (should fail)
3. **Expected**: These critical fields remain protected ✅

---

## 📊 Deployment Verification

### Method 1: Firebase Console
1. Go to: https://console.firebase.google.com/project/sayekataleapp/firestore/rules
2. Check the **Rules** tab
3. Verify you see the new rules starting with:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // ============================================================================
       // HELPER FUNCTIONS
       // ============================================================================
   ```
4. Check the deployment timestamp (should be recent)

### Method 2: Cloud Shell
```bash
# Check if rules file exists
ls -la firestore.rules

# Show the current rules
cat firestore.rules | head -20

# Check Firebase project configuration
firebase use
# Should show: Now using project sayekataleapp
```

---

## ❌ Troubleshooting

### Issue: "firebase: command not found"
**Solution**:
```bash
npm install -g firebase-tools
```

### Issue: "Error: Failed to authenticate"
**Solution**:
```bash
firebase logout
firebase login --no-localhost
# Follow the authentication flow
```

### Issue: "Error: HTTP Error: 403"
**Solution**: Make sure you have Firebase Admin access
1. Go to: https://console.firebase.google.com/project/sayekataleapp/settings/iam
2. Verify your account has "Firebase Admin" role
3. If not, contact project owner to add you

### Issue: "Error: No project active"
**Solution**:
```bash
firebase use sayekataleapp
```

### Issue: Rules deployed but profile updates still fail
**Solution**: Check the error message in the app
1. Look for permission denied errors
2. Verify the user's UID matches their document ID
3. Check Firebase Functions logs for detailed errors

---

## 🔧 Advanced: Validate Rules Before Deployment

```bash
# Validate rules syntax (optional)
firebase deploy --only firestore:rules --dry-run

# This checks for syntax errors without deploying
```

---

## 📝 What Changed in the Rules

### Before (Old Rules - Too Strict):
```javascript
allow update: if request.auth != null && 
                 request.auth.uid == userId &&
                 request.resource.data.id == resource.data.id &&  // ❌ Fails if id missing
                 request.resource.data.role == resource.data.role;
```

**Problem**: If the update doesn't include `id` field, the rule fails even though the user isn't trying to change it.

### After (New Rules - More Flexible):
```javascript
allow update: if request.auth != null && 
                 request.auth.uid == userId &&
                 // Only prevent changing these specific fields
                 (!('id' in request.resource.data) || request.resource.data.id == resource.data.id) &&
                 (!('role' in request.resource.data) || request.resource.data.role == resource.data.role);
```

**Fix**: 
- If `id` is **not in the update** → ✅ Allow (user isn't trying to change it)
- If `id` is **in the update** → Only allow if it matches the original value
- Same logic for `role` field

---

## 📚 Additional Resources

- **Firebase Security Rules Guide**: https://firebase.google.com/docs/firestore/security/get-started
- **Cloud Shell Documentation**: https://cloud.google.com/shell/docs
- **Firebase CLI Reference**: https://firebase.google.com/docs/cli

---

## 🎉 Success Indicators

After successful deployment, you should see:

✅ **In Cloud Shell**:
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/sayekataleapp/overview
```

✅ **In Firebase Console**:
- Rules tab shows new deployment timestamp
- Rules contain the HELPER FUNCTIONS section
- Rules show flexible update logic

✅ **In the App**:
- SME users can edit profiles without errors
- SHG users can edit profiles without errors
- Profile images upload successfully
- Location updates work properly

---

## ⏱️ Estimated Time

- **First time setup**: 5-10 minutes (includes Firebase CLI installation)
- **Subsequent deployments**: 1-2 minutes
- **Testing**: 5 minutes

**Total**: ~15-20 minutes for complete deployment and testing

---

## 🆘 Need Help?

If you encounter issues:

1. **Check the deployment script output** for specific errors
2. **Review Firebase Console logs**: https://console.firebase.google.com/project/sayekataleapp/firestore/usage
3. **Run the diagnosis script**: `python3 diagnose_user_issues.py`
4. **Check the comprehensive guide**: `USER_ISSUES_FIX_GUIDE.md`

---

**Last Updated**: November 21, 2025  
**Status**: Ready for deployment ✅
