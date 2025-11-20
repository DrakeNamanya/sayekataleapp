# 🚨 PawaPay API Failure - Diagnostic Guide

## 📊 Current Status

**Problem:** Payment initiated but mobile money prompt NOT reaching phone

**Evidence:**
- Transaction Status: `failed` ❌
- Subscription Status: `pending` (correct)
- Phone: 0744646069 (Airtel)
- Amount: 50,000 UGX
- Deposit ID: 0075d655-a812-49df-9f2f-3da28dbc16d6

**Root Cause:** PawaPay API is **rejecting** all payment requests

---

## 🔍 Why Payments Are Failing

The transaction status `failed` means the PawaPay API returned an error response. Common causes:

### 1. **API Token Issue (Most Likely)**
**Problem:** Token might be:
- Invalid or expired
- For wrong environment (sandbox token but calling production API)
- Not authorized for Uganda correspondents

**How to Check:**
- Go to: https://dashboard.pawapay.io/
- Settings → API Keys
- Verify token matches what's in the app
- Check if token is for SANDBOX or PRODUCTION

**Current Token in App:**
```
eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc5MTY2MzYxLCJpYXQiOjE3NjM2MzM1NjEsInBtIjoiREFGLFBBRiIsImp0aSI6IjBlYmU3NDAwLWYxNzgtNGIyMi04ODRjLWZkZmJlODdmNjNjZiJ9.omxE-Q_5xu3wL8bq90REgP8FTPB7uWtJFgjtOZAUamuIYlOF9QlHn719zmi-kk0r7OFQUzBU3LiTi4nJdF_Tqw
```

---

### 2. **Correspondent Not Activated**
**Problem:** `AIRTEL_OAPI_UGA` or `MTN_MOMO_UGA` not enabled in your PawaPay account

**How to Check:**
- Go to: https://dashboard.pawapay.io/
- Check account settings for enabled correspondents
- Uganda correspondents must be explicitly activated
- May require contacting PawaPay support

---

### 3. **Sandbox vs Production Mismatch**
**Problem:** App might be using sandbox token but calling production API (or vice versa)

**Current API Endpoints:**
- Sandbox: `https://api.sandbox.pawapay.cloud`
- Production: `https://api.pawapay.cloud`

**App Configuration:**
- Debug mode determines which endpoint is used
- `debugMode: false` → Production API
- `debugMode: true` → Sandbox API

**Question:** Is your PawaPay token for SANDBOX or PRODUCTION?

---

### 4. **Account Not Fully Set Up**
**Problem:** PawaPay account might need:
- KYC verification
- Business documentation
- Activation by PawaPay team
- Deposit limits configured

---

## 🔧 How to Get Exact Error Details

The app logs PawaPay API responses. To see them:

### Method 1: Browser Console (Web App)
1. Open the web app: https://5060-i25ra390rl3tp6c83ufw7-8f57ffe2.sandbox.novita.ai
2. Press F12 to open Developer Tools
3. Go to "Console" tab
4. Initiate a payment
5. Look for these logs:
   ```
   🌐 Calling PawaPay API: https://api.sandbox.pawapay.cloud/deposits
   📤 Request body: {...}
   📥 Response status: ???
   📥 Response body: {...}
   ```

### Method 2: Check Flutter Web Build Logs
```bash
# If running locally, check console output
flutter run -d chrome --release
```

### Method 3: Add More Detailed Logging
The app should log PawaPay errors. Check for:
- HTTP status codes (401, 403, 400, etc.)
- Error messages from PawaPay
- Validation errors

---

## 📋 PawaPay API Error Codes

**401 Unauthorized:**
- API token is invalid
- Token expired
- Token not found

**403 Forbidden:**
- Token doesn't have permission for this action
- Correspondent not activated for your account
- Account not authorized for this country

**400 Bad Request:**
- Invalid phone number format
- Correspondent ID incorrect
- Amount out of range
- Missing required fields

**404 Not Found:**
- Wrong API endpoint
- Correspondent doesn't exist

**500 Internal Server Error:**
- PawaPay service issue
- Try again later

---

## 🧪 Testing with PawaPay Sandbox

If using **SANDBOX mode**, try these test numbers:

**MTN Test Number:** `0772000001`
- Always returns success
- Simulates approved payment

**Airtel Test Number:** `0702000001`
- Always returns success
- Simulates approved payment

**Important:** Sandbox test numbers won't actually send mobile money prompts!

---

## ✅ Recommended Actions (In Order)

### 1. Verify API Token (Priority 1)
Go to PawaPay Dashboard and:
- Copy your API token
- Check if it's for SANDBOX or PRODUCTION
- Verify it hasn't expired
- Regenerate if needed

### 2. Check Correspondents (Priority 2)
Verify in PawaPay Dashboard:
- Is `MTN_MOMO_UGA` activated? ✓
- Is `AIRTEL_OAPI_UGA` activated? ✓
- Are there any restrictions on your account?

### 3. Check Sandbox vs Production (Priority 3)
Confirm:
- Which environment is your token for?
- Is the app calling the correct API endpoint?
- Do they match?

### 4. Contact PawaPay Support (If Above Fails)
Provide them with:
- Your account email
- Transaction ID: `0075d655-a812-49df-9f2f-3da28dbc16d6`
- Phone number: 0744646069
- Error message from API response

---

## 🔄 Quick Test to Identify Issue

**Test with curl directly:**
```bash
curl -X POST https://api.sandbox.pawapay.cloud/deposits \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "depositId": "test-12345",
    "amount": "1000.00",
    "currency": "UGX",
    "country": "UGA",
    "correspondent": "AIRTEL_OAPI_UGA",
    "payer": {
      "type": "MSISDN",
      "address": {
        "value": "+256744646069"
      }
    },
    "customerTimestamp": "2025-11-20T19:00:00Z",
    "statementDescription": "Test Payment"
  }'
```

**Expected Responses:**

**✅ Success (200/201):**
```json
{
  "depositId": "test-12345",
  "status": "SUBMITTED",
  ...
}
```

**❌ Unauthorized (401):**
```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
```

**❌ Forbidden (403):**
```json
{
  "error": "Forbidden",
  "message": "Correspondent not activated"
}
```

---

## 📞 Next Steps

**Please provide:**

1. **PawaPay Environment:**
   - Are you using SANDBOX or PRODUCTION?
   - Is your API token for the correct environment?

2. **Correspondent Status:**
   - Check PawaPay dashboard
   - Are Uganda correspondents activated?

3. **Browser Console Logs:**
   - Open web app with F12
   - Copy the `📥 Response status` and `📥 Response body`

**With this information, I can identify the exact issue and provide a solution!**

---

## 🎯 Expected Fix Timeline

Once we identify the issue:
- **Token issue:** 5 minutes (regenerate and rebuild)
- **Correspondent not activated:** Contact PawaPay support
- **Sandbox test:** Use test numbers (0772000001, 0702000001)
- **Production setup:** May require PawaPay account verification

