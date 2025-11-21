# ⚡ QUICK START - Server-Side PawaPay Integration

## 🚨 CRITICAL FIRST STEP

### 1. Rotate Exposed API Key (DO THIS NOW!)

1. **PawaPay Dashboard**: https://dashboard.pawapay.io/
2. **Settings → API Keys**
3. **Revoke** old key (starts with `eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ`)
4. **Create** new Production key
5. **Save** it securely

---

## 🔧 2. Configure Firebase Functions

```bash
# Set new API key
firebase functions:config:set pawapay.api_token="YOUR_NEW_KEY"
firebase functions:config:set pawapay.use_sandbox="false"

# Deploy functions
cd /home/user/flutter_app
firebase deploy --only functions
```

---

## 🌐 3. Configure PawaPay Webhook

1. **PawaPay Dashboard** → Settings → Webhooks
2. **URL**: `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook`
3. **Method**: POST
4. **Events**: `deposit.status.updated`
5. **Active**: ✅ Enabled

---

## 🧪 4. Test Payment Flow

```bash
# Install test APK
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Test Steps:**
1. Login: `drnamanya@gmail.com`
2. SME Directory → Upgrade to Premium
3. Enter Uganda number (e.g., `0774000001`)
4. Click "Pay with Mobile Money"
5. **EXPECT**: Mobile money prompt on phone
6. Enter PIN
7. **EXPECT**: Subscription activates

---

## 📊 5. Monitor

**Firebase Logs**: https://console.firebase.google.com/project/sayekataleapp/functions/logs

**Look for:**
- ✅ `🌐 Calling PawaPay API`
- ✅ `📥 Response status: 201`
- ✅ `✅ Premium subscription activated`

**Firestore**: https://console.firebase.google.com/project/sayekataleapp/firestore
- `transactions/{id}` - status: `initiated` → `completed`
- `subscriptions/{userId}` - status: `pending` → `active`

---

## ❌ Troubleshooting

**No mobile money prompt?**
1. Check Firebase logs for PawaPay error
2. Common: `401` = wrong API key, `403` = correspondent not activated

**Subscription not activating?**
1. Verify webhook URL in PawaPay Dashboard
2. Test webhook manually with curl (see DEPLOYMENT_INSTRUCTIONS.md)

---

## 📚 Full Documentation

- **Security Details**: `SECURITY_CRITICAL_FIXES.md`
- **Step-by-Step Deployment**: `DEPLOYMENT_INSTRUCTIONS.md`
- **GitHub**: https://github.com/DrakeNamanya/sayekataleapp

---

**Status**: ✅ Code ready - Deploy after API key rotation  
**Latest Commit**: `71b0838`  
**Updated**: November 20, 2025
