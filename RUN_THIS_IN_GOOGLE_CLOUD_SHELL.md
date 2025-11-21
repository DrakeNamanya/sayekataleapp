# 🚀 RUN THIS IN GOOGLE CLOUD SHELL

## ⚡ Quick Fix for Missing `initiatePayment` Function

Copy and paste these commands into **Google Cloud Shell**:

```bash
cd ~/sayekataleapp
git pull origin main
./force_deploy_all_functions.sh
```

That's it! The script will:
- ✅ Clean cache
- ✅ Pull latest code
- ✅ Verify all 4 functions
- ✅ Force redeploy
- ✅ Test endpoints
- ✅ Show results

---

## ✅ Expected Result

After running the script, you should see:

```
============================================
📋 Summary
============================================

Check Firebase Console to verify all 4 functions are listed:
  https://console.firebase.google.com/project/sayekataleapp/functions

Expected functions:
  1. ✅ initiatePayment
  2. ✅ pawaPayWebhook
  3. ✅ pawaPayWebhookHealth
  4. ✅ manualActivateSubscription
```

---

## 📱 After Successful Deployment

### **Test Payment Flow:**

1. **Download APK:** [app-release.apk](https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=8bd01bd7-e1d6-45a8-86f6-ad3953c185e9&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk&file_name=app-release.apk)

2. **Install:** `adb install app-release.apk`

3. **Test:**
   - Login: `drnamanya@gmail.com`
   - Go to: SME Directory → Upgrade to Premium
   - Enter YOUR mobile money number
   - Click "Pay with Mobile Money"
   - **EXPECTED: Mobile money prompt on your phone**

---

## 🆘 If Script Fails

See detailed manual steps in: **MISSING_FUNCTION_FIX.md**

Or run manually:

```bash
cd ~/sayekataleapp
rm -rf functions/node_modules functions/.firebase
git pull origin main
cd functions && npm install && cd ..
npx firebase deploy --only functions --force
npx firebase functions:list
```

---

**That's all you need to do!** 🎉
