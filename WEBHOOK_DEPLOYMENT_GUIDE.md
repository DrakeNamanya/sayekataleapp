# PawaPay Webhook Deployment Guide

## 🎯 Overview

This guide walks you through deploying the PawaPay webhook handler to Firebase Cloud Functions. The webhook enables reliable, asynchronous payment confirmation and automatic premium subscription activation.

**What the Webhook Does:**
- ✅ Receives payment status updates from PawaPay
- ✅ Verifies webhook signatures (RFC-9421)
- ✅ Prevents duplicate processing (idempotency)
- ✅ Updates transaction status in Firestore
- ✅ Activates premium subscriptions automatically
- ✅ Handles retries gracefully

---

## 📋 Prerequisites

Before starting, ensure you have:

- [x] Firebase CLI installed (`firebase --version` shows 14.20.0 or higher)
- [x] Node.js v20 installed (`node --version` shows v20.x.x)
- [x] Firebase project initialized
- [x] Admin access to Firebase Console
- [x] PawaPay account and API credentials

---

## 🚀 Step 1: Install Dependencies

Navigate to the functions directory and install required packages:

```bash
cd /home/user/flutter_app/functions
npm install
```

This installs:
- `firebase-admin` - Firestore database access
- `firebase-functions` - Cloud Functions runtime
- `express` - HTTP server framework
- `cors` - Cross-origin resource sharing

---

## 🔐 Step 2: Firebase Authentication

Ensure you're logged into Firebase:

```bash
firebase login
```

If already logged in, verify your projects:

```bash
firebase projects:list
```

Select your project (if not already selected):

```bash
firebase use <your-project-id>
```

---

## 🧪 Step 3: Test Locally (Optional but Recommended)

Test the webhook locally before deploying:

```bash
cd /home/user/flutter_app
firebase emulators:start --only functions
```

This starts a local emulator at:
- Functions: `http://localhost:5001/<project-id>/us-central1/pawaPayWebhook`
- Health check: `http://localhost:5001/<project-id>/us-central1/pawaPayWebhookHealth`

**Test the health endpoint:**

```bash
curl http://localhost:5001/<project-id>/us-central1/pawaPayWebhookHealth
```

Expected response:
```json
{
  "status": "healthy",
  "message": "PawaPay webhook handler is running",
  "timestamp": "2025-11-19T...",
  "version": "2.0.0"
}
```

**Test webhook with sample payload:**

```bash
curl -X POST http://localhost:5001/<project-id>/us-central1/pawaPayWebhook \
  -H "Content-Type: application/json" \
  -H "Digest: sha-256=..." \
  -d '{
    "id": "test-deposit-id-123",
    "status": "COMPLETED",
    "amount": "50000.00",
    "currency": "UGX",
    "correspondent": "MTN_MOMO_UGA"
  }'
```

**Stop emulator when done:**
Press `Ctrl+C` in the terminal.

---

## 🚀 Step 4: Deploy to Firebase

Deploy the webhook to Firebase Cloud Functions:

```bash
cd /home/user/flutter_app
firebase deploy --only functions
```

**Expected output:**
```
✔  functions: Finished running predeploy script.
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (XX.XX KB) for uploading
✔  functions: functions folder uploaded successfully
i  functions: updating Node.js 20 function pawaPayWebhook(us-central1)...
i  functions: updating Node.js 20 function pawaPayWebhookHealth(us-central1)...
i  functions: updating Node.js 20 function manualActivateSubscription(us-central1)...
✔  functions[pawaPayWebhook(us-central1)]: Successful update operation.
✔  functions[pawaPayWebhookHealth(us-central1)]: Successful update operation.
✔  functions[manualActivateSubscription(us-central1)]: Successful update operation.

✔  Deploy complete!

Functions URL (pawaPayWebhook):
https://us-central1-<your-project-id>.cloudfunctions.net/pawaPayWebhook
```

**Save the Function URL** - you'll need it for PawaPay configuration.

---

## 🔗 Step 5: Configure PawaPay Webhook URL

### Option A: Via PawaPay Dashboard (Recommended)

1. Log into PawaPay Dashboard:
   - Production: https://dashboard.pawapay.io/
   - Sandbox: https://dashboard.sandbox.pawapay.io/

2. Navigate to **Settings** → **Webhooks** or **Callbacks**

3. Add your webhook URL:
   ```
   https://us-central1-<your-project-id>.cloudfunctions.net/pawaPayWebhook
   ```

4. Configure webhook events:
   - ✅ Deposit Status Updates
   - ✅ Payment Completed
   - ✅ Payment Failed

5. **Save** and **Test** the webhook connection

### Option B: Via PawaPay API

If webhook URL needs to be set via API:

```bash
curl -X POST https://api.pawapay.io/v1/config/callbacks \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "depositCallback": "https://us-central1-<your-project-id>.cloudfunctions.net/pawaPayWebhook"
  }'
```

---

## ✅ Step 6: Verify Deployment

### 6.1 Check Health Endpoint

```bash
curl https://us-central1-<your-project-id>.cloudfunctions.net/pawaPayWebhookHealth
```

Expected response:
```json
{
  "status": "healthy",
  "message": "PawaPay webhook handler is running",
  "timestamp": "2025-11-19T21:45:00.000Z",
  "version": "2.0.0"
}
```

### 6.2 View Function Logs

```bash
firebase functions:log --only pawaPayWebhook
```

Or view in Firebase Console:
1. Go to https://console.firebase.google.com/
2. Select your project
3. Navigate to **Functions** → **Logs**

### 6.3 Test with Real Payment

Make a small test payment (UGX 1,000) to verify:

1. Open SayeKatale app
2. Navigate to Premium Subscription screen
3. Enter phone number: `0772123456` (or your test number)
4. Click "Activate Subscription"
5. Approve payment on your phone

**Monitor logs:**
```bash
firebase functions:log --only pawaPayWebhook --follow
```

Expected log output:
```
📥 PawaPay Webhook Received
✅ Digest verified
✅ Signature verification passed
📋 Transaction found: {...}
✅ Payment COMPLETED: abc-123, Amount: UGX 50000.0
✅ Premium subscription activated for user: user_xyz
🎉 Premium subscription activated for user user_xyz
✅ Marked as processed: abc-123
```

---

## 🔧 Step 7: Configure Firestore Security (Already Done)

The webhook needs to write to Firestore. Security rules are already configured, but verify:

```bash
cat /home/user/flutter_app/firestore.rules
```

Ensure these collections allow backend writes:
- ✅ `transactions` - Allow updates
- ✅ `subscriptions` - Allow writes
- ✅ `webhook_logs` - Allow writes

---

## 📊 Step 8: Monitor & Maintain

### View Function Metrics

Firebase Console → Functions → Select function → View metrics:
- Invocations count
- Execution time
- Error rate
- Memory usage

### Set Up Alerts

1. Go to Firebase Console → **Alerting**
2. Create alert for:
   - Function errors exceeding threshold
   - High invocation count (possible attack)
   - Execution time exceeding 10 seconds

### View Webhook Logs in Firestore

All processed webhooks are logged to `webhook_logs` collection:

```javascript
// Query in Firebase Console or your admin panel
db.collection('webhook_logs')
  .orderBy('processed_at', 'desc')
  .limit(50)
  .get()
```

---

## 🐛 Troubleshooting

### Issue: Function Not Found

**Error:**
```
Cannot find function pawaPayWebhook
```

**Solution:**
```bash
# Redeploy functions
cd /home/user/flutter_app
firebase deploy --only functions
```

---

### Issue: Permission Denied

**Error:**
```
403 Forbidden - Missing permissions
```

**Solution:**
1. Check Firebase project permissions
2. Ensure service account has Firestore write access
3. Verify IAM roles in Google Cloud Console

---

### Issue: Signature Verification Failed

**Error in logs:**
```
❌ Signature verification failed
❌ Digest mismatch
```

**Solution:**
1. This is expected if testing manually (no valid signature)
2. Real PawaPay webhooks will have valid signatures
3. For testing, temporarily disable signature verification (NOT for production)

---

### Issue: Transaction Not Found

**Error in logs:**
```
⚠️ Transaction not found for depositId: xxx
```

**Possible causes:**
1. Transaction not created before payment (app flow issue)
2. Wrong depositId in webhook
3. Database connection issue

**Solution:**
1. Verify transaction is created in Firestore before payment
2. Check transaction document ID matches depositId
3. Review app payment flow logs

---

### Issue: Webhook Not Receiving Callbacks

**Symptoms:**
- Payment succeeds in app
- No webhook logs in Firebase
- Subscription not activated

**Solution:**

1. **Verify webhook URL in PawaPay Dashboard:**
   ```
   https://us-central1-<your-project-id>.cloudfunctions.net/pawaPayWebhook
   ```

2. **Test webhook endpoint manually:**
   ```bash
   curl https://us-central1-<your-project-id>.cloudfunctions.net/pawaPayWebhookHealth
   ```

3. **Check PawaPay webhook logs** (in PawaPay Dashboard)

4. **Verify function permissions:**
   - Function must be publicly accessible
   - No authentication required for webhook endpoint

5. **Check function status:**
   ```bash
   firebase functions:log --only pawaPayWebhook
   ```

---

## 🔒 Security Considerations

### Current Implementation

✅ **Implemented:**
- Digest verification (SHA-256)
- Timestamp validation (replay protection)
- Idempotency handling
- CORS headers
- Error handling

⚠️ **Pending (Production TODO):**
- Full RFC-9421 signature verification with PawaPay public key
- Rate limiting
- IP whitelist (PawaPay IP ranges)
- Request logging and monitoring

### Production Security Checklist

Before going live:

- [ ] Implement full RFC-9421 signature verification
- [ ] Add PawaPay IP whitelist
- [ ] Enable function authentication (with exception for webhook)
- [ ] Set up monitoring and alerting
- [ ] Test webhook retry logic
- [ ] Review Firestore security rules
- [ ] Implement rate limiting
- [ ] Set up backup webhook handler (redundancy)

---

## 📈 Performance Optimization

### Current Configuration

- Runtime: Node.js 20
- Memory: 256 MB (default)
- Timeout: 60 seconds (default)
- Max instances: Unlimited (default)

### Recommended Production Settings

Update `firebase.json`:

```json
{
  "functions": {
    "source": "functions",
    "runtime": "nodejs20",
    "memory": "512MB",
    "timeoutSeconds": 30,
    "maxInstances": 100,
    "minInstances": 1
  }
}
```

Benefits:
- Faster cold starts (min instances = 1)
- Better performance (512MB memory)
- Cost control (max instances = 100)
- Faster timeout (30s instead of 60s)

---

## 💰 Cost Estimation

### Firebase Cloud Functions Pricing

**Free Tier (per month):**
- 2 million invocations
- 400,000 GB-seconds
- 200,000 CPU-seconds
- 5 GB network egress

**Paid Tier:**
- $0.40 per million invocations
- $0.0000025 per GB-second
- $0.00001 per CPU-second

**Estimated costs for 1,000 subscriptions/month:**
- Invocations: ~3,000 (payment initiated + webhook callback + retry)
- Cost: ~$0.01/month (well within free tier)

---

## 🔄 Update & Redeploy

When making changes to webhook code:

1. **Edit** `/home/user/flutter_app/functions/index.js`

2. **Test locally** (optional):
   ```bash
   firebase emulators:start --only functions
   ```

3. **Deploy:**
   ```bash
   firebase deploy --only functions
   ```

4. **Verify deployment:**
   ```bash
   curl https://us-central1-<your-project-id>.cloudfunctions.net/pawaPayWebhookHealth
   ```

5. **Monitor logs:**
   ```bash
   firebase functions:log --only pawaPayWebhook --follow
   ```

---

## 📚 Additional Resources

### Firebase Documentation
- Cloud Functions: https://firebase.google.com/docs/functions
- Firestore: https://firebase.google.com/docs/firestore
- Function logs: https://firebase.google.com/docs/functions/writing-and-viewing-logs

### PawaPay Documentation
- Webhooks: https://docs.pawapay.io/implementation#handling-callbacks
- Callback URL config: https://docs.pawapay.io/using_the_api#callback-urls
- RFC-9421 signatures: https://docs.pawapay.io/v1/api-reference/deposits/deposit-callback

### Support
- Firebase Support: https://firebase.google.com/support
- PawaPay Support: support@pawapay.io
- GitHub Issues: https://github.com/DrakeNamanya/sayekataleapp/issues

---

## ✅ Deployment Checklist

Use this checklist to verify successful deployment:

**Pre-Deployment:**
- [ ] Code reviewed and tested locally
- [ ] Dependencies installed (`npm install`)
- [ ] Firebase CLI authenticated (`firebase login`)
- [ ] Correct project selected (`firebase use`)

**Deployment:**
- [ ] Functions deployed (`firebase deploy --only functions`)
- [ ] Health endpoint accessible
- [ ] Function logs show no errors

**Configuration:**
- [ ] Webhook URL configured in PawaPay Dashboard
- [ ] Webhook events enabled (Deposit Status Updates)
- [ ] Test webhook connection successful

**Testing:**
- [ ] Health check passes
- [ ] Test payment completes successfully
- [ ] Webhook logs show "COMPLETED" status
- [ ] Subscription activated in Firestore
- [ ] User can access premium directory

**Monitoring:**
- [ ] Function metrics visible in Firebase Console
- [ ] Alerts configured for errors
- [ ] Webhook logs collection monitored

**Production:**
- [ ] Full RFC-9421 signature verification implemented
- [ ] Rate limiting enabled
- [ ] IP whitelist configured
- [ ] Backup webhook handler deployed

---

## 🎉 Success!

Your PawaPay webhook is now deployed and ready to handle payment callbacks!

**Next steps:**
1. Make test payment
2. Verify subscription activation
3. Monitor logs for any issues
4. Implement remaining security features
5. Set up production monitoring

**Questions?** Refer to the troubleshooting section or contact support.

---

**Last Updated:** 2025-11-19  
**Version:** 2.0.0  
**Deployed Function URL:** `https://us-central1-<your-project-id>.cloudfunctions.net/pawaPayWebhook`
