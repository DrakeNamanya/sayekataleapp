# Cloud Functions Permission Error Fix

**Error Date:** November 20, 2025  
**Function:** pawaPayWebhook  
**Status:** ❌ FAILED TO DEPLOY  
**Severity:** ERROR

---

## 🐛 **Error Analysis**

### **Error Message:**
```
Failed to create 1st Gen function projects/sayekataleapp/locations/us-central1/functions/pawaPayWebhook: 
Unable to retrieve the repository metadata for projects/sayekataleapp/locations/us-central1/repositories/gcf-artifacts. 

Ensure that the Cloud Functions service account has 'artifactregistry.repositories.list' 
and 'artifactregistry.repositories.get' permissions. 

You can add the permissions by granting the role 'roles/artifactregistry.reader'.
```

### **Error Details:**
- **Project:** sayekataleapp
- **Function:** pawaPayWebhook
- **Location:** us-central1
- **Environment:** GEN_1 (1st Gen Cloud Function)
- **Runtime:** nodejs20
- **Error Code:** 7 (PERMISSION_DENIED)

---

## 🔍 **Root Cause**

### **Problem:**
The Cloud Functions service account doesn't have permission to access Artifact Registry, which is required to store and retrieve function builds.

### **Why This Happens:**
1. **New Project Setup:** Permissions not automatically granted in new projects
2. **Service Account:** Cloud Functions uses a service account that needs explicit permissions
3. **Artifact Registry:** Required for storing Docker images and function code

### **Service Account:**
```
{project-id}@appspot.gserviceaccount.com
```
For your project:
```
sayekataleapp@appspot.gserviceaccount.com
```

---

## ✅ **Solution: Grant Artifact Registry Permissions**

### **Option 1: Using Google Cloud Console (Recommended)**

#### **Step 1: Navigate to IAM**
```
1. Go to: https://console.cloud.google.com/iam-admin/iam
2. Make sure project "sayekataleapp" is selected
```

#### **Step 2: Find Service Account**
```
1. Look for: sayekataleapp@appspot.gserviceaccount.com
2. This is your App Engine default service account
3. Used by Cloud Functions
```

#### **Step 3: Add Role**
```
1. Click the pencil icon (Edit) next to the service account
2. Click "+ ADD ANOTHER ROLE"
3. Search for: "Artifact Registry Reader"
4. Select: roles/artifactregistry.reader
5. Click "SAVE"
```

**Role Details:**
- **Name:** Artifact Registry Reader
- **ID:** roles/artifactregistry.reader
- **Permissions Granted:**
  - artifactregistry.repositories.list
  - artifactregistry.repositories.get
  - artifactregistry.dockerimages.list
  - artifactregistry.dockerimages.get

---

### **Option 2: Using gcloud CLI** (Faster)

#### **Prerequisites:**
- gcloud CLI installed
- Authenticated to Google Cloud
- Project set to sayekataleapp

#### **Command:**
```bash
gcloud projects add-iam-policy-binding sayekataleapp \
  --member="serviceAccount:sayekataleapp@appspot.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

**Expected Output:**
```
Updated IAM policy for project [sayekataleapp].
bindings:
- members:
  - serviceAccount:sayekataleapp@appspot.gserviceaccount.com
  role: roles/artifactregistry.reader
```

---

### **Option 3: Using Firebase CLI**

```bash
# Authenticate
firebase login

# Set project
firebase use sayekataleapp

# Deploy function (will prompt for permissions)
firebase deploy --only functions:pawaPayWebhook
```

**Note:** Firebase CLI may automatically grant permissions during deployment if you have sufficient privileges.

---

## 🔧 **Additional Permissions (If Needed)**

If you encounter other permission errors, you may need to grant additional roles:

### **Cloud Build Service Account:**
```bash
gcloud projects add-iam-policy-binding sayekataleapp \
  --member="serviceAccount:sayekataleapp@appspot.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.builder"
```

### **Cloud Functions Invoker (for HTTP functions):**
```bash
gcloud projects add-iam-policy-binding sayekataleapp \
  --member="serviceAccount:sayekataleapp@appspot.gserviceaccount.com" \
  --role="roles/cloudfunctions.invoker"
```

### **Service Account User:**
```bash
gcloud projects add-iam-policy-binding sayekataleapp \
  --member="serviceAccount:sayekataleapp@appspot.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

---

## 🧪 **Verify Permissions**

### **Check Current Permissions:**
```bash
gcloud projects get-iam-policy sayekataleapp \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:sayekataleapp@appspot.gserviceaccount.com"
```

**Expected Output:**
```
bindings:
  role: roles/artifactregistry.reader
  members:
  - serviceAccount:sayekataleapp@appspot.gserviceaccount.com
```

---

## 🚀 **Redeploy Function**

After granting permissions, redeploy your function:

### **Method 1: Firebase CLI**
```bash
cd /home/user/flutter_app
firebase deploy --only functions:pawaPayWebhook
```

### **Method 2: gcloud CLI**
```bash
gcloud functions deploy pawaPayWebhook \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=. \
  --entry-point=pawaPayWebhook \
  --trigger-http \
  --allow-unauthenticated
```

**Note:** Wait 2-3 minutes for permissions to propagate before deploying.

---

## 📝 **Full IAM Roles Recommended for Cloud Functions**

For smooth Cloud Functions operation, ensure these roles are granted:

| Role | Purpose | Required? |
|------|---------|-----------|
| **roles/artifactregistry.reader** | Access build artifacts | ✅ YES |
| **roles/cloudbuild.builds.builder** | Build functions | ✅ YES |
| **roles/cloudfunctions.developer** | Deploy functions | ✅ YES |
| **roles/logging.logWriter** | Write logs | ⚠️ Recommended |
| **roles/storage.objectViewer** | Access Cloud Storage | ⚠️ If needed |

### **Grant All at Once:**
```bash
# Artifact Registry Reader
gcloud projects add-iam-policy-binding sayekataleapp \
  --member="serviceAccount:sayekataleapp@appspot.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"

# Cloud Build Builder
gcloud projects add-iam-policy-binding sayekataleapp \
  --member="serviceAccount:sayekataleapp@appspot.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.builder"

# Log Writer
gcloud projects add-iam-policy-binding sayekataleapp \
  --member="serviceAccount:sayekataleapp@appspot.gserviceaccount.com" \
  --role="roles/logging.logWriter"
```

---

## 🔍 **Understanding the pawaPayWebhook Function**

### **What This Function Does:**
The `pawaPayWebhook` function is a webhook endpoint for PawaPay payment notifications.

**Purpose:**
- Receives payment status updates from PawaPay
- Updates wallet balances in Firestore
- Processes deposit and withdrawal completions
- Handles payment failures and cancellations

**Trigger:** HTTP POST requests from PawaPay servers

**Related Code:**
- Flutter app calls PawaPay API for payments
- PawaPay processes payment
- PawaPay sends webhook to this Cloud Function
- Function updates database with payment status

---

## ⚠️ **Important Notes**

### **About Gen 1 vs Gen 2 Functions:**

Your error shows **GEN_1** (1st generation) function. Consider upgrading to Gen 2:

**Gen 1 (Current):**
- Older architecture
- Limited scaling
- Some permission issues

**Gen 2 (Recommended):**
- Better performance
- Improved security
- Easier permission management
- More features

**Upgrade Command:**
```bash
firebase deploy --only functions:pawaPayWebhook --gen2
```

---

## 🐛 **Troubleshooting**

### **Issue 1: Permission Denied After Granting Role**

**Cause:** Permissions take 2-3 minutes to propagate

**Solution:**
```bash
# Wait 3 minutes, then retry
sleep 180
firebase deploy --only functions:pawaPayWebhook
```

---

### **Issue 2: Service Account Not Found**

**Cause:** App Engine service account not created

**Solution:**
```bash
# Enable App Engine API
gcloud services enable appengine.googleapis.com

# Create App Engine app (if doesn't exist)
gcloud app create --region=us-central
```

---

### **Issue 3: Artifact Registry Not Enabled**

**Error:** "API [artifactregistry.googleapis.com] not enabled"

**Solution:**
```bash
gcloud services enable artifactregistry.googleapis.com
```

---

### **Issue 4: Cloud Build Not Enabled**

**Error:** "Cloud Build API has not been used"

**Solution:**
```bash
gcloud services enable cloudbuild.googleapis.com
```

---

## 📊 **Deployment Checklist**

Before deploying Cloud Functions, ensure:

- [x] **Project Setup**
  - [ ] Project created: sayekataleapp
  - [ ] Billing enabled
  - [ ] App Engine initialized

- [x] **APIs Enabled**
  - [ ] Cloud Functions API
  - [ ] Cloud Build API
  - [ ] Artifact Registry API
  - [ ] Cloud Logging API

- [x] **Permissions Granted**
  - [ ] roles/artifactregistry.reader
  - [ ] roles/cloudbuild.builds.builder
  - [ ] roles/logging.logWriter

- [x] **Function Configuration**
  - [ ] Runtime: nodejs20
  - [ ] Region: us-central1
  - [ ] Entry point: pawaPayWebhook
  - [ ] Trigger: HTTP

- [x] **Deployment**
  - [ ] Code deployed successfully
  - [ ] Function URL accessible
  - [ ] Logs showing no errors

---

## ✅ **Quick Fix Summary**

**Problem:** Cloud Functions can't access Artifact Registry

**Solution:** Grant Artifact Registry Reader role

**Commands:**
```bash
# 1. Grant permission
gcloud projects add-iam-policy-binding sayekataleapp \
  --member="serviceAccount:sayekataleapp@appspot.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"

# 2. Wait for propagation
sleep 180

# 3. Redeploy function
firebase deploy --only functions:pawaPayWebhook

# 4. Verify deployment
gcloud functions describe pawaPayWebhook --region=us-central1
```

**Expected Time:** 5-10 minutes total

---

## 📞 **Support Resources**

**Google Cloud Documentation:**
- IAM: https://cloud.google.com/iam/docs
- Cloud Functions: https://cloud.google.com/functions/docs
- Artifact Registry: https://cloud.google.com/artifact-registry/docs

**Firebase Documentation:**
- Cloud Functions: https://firebase.google.com/docs/functions
- Deployment: https://firebase.google.com/docs/functions/get-started

**Troubleshooting:**
- Permission Errors: https://cloud.google.com/functions/docs/troubleshooting
- IAM Issues: https://cloud.google.com/iam/docs/troubleshooting

---

## ✨ **Summary**

**Error:** Permission denied for Artifact Registry  
**Service Account:** sayekataleapp@appspot.gserviceaccount.com  
**Missing Role:** roles/artifactregistry.reader  
**Fix Time:** 5-10 minutes  
**Priority:** HIGH (blocks payment webhook)

**Next Steps:**
1. Grant Artifact Registry Reader role (5 mins)
2. Wait for permission propagation (3 mins)
3. Redeploy function (2 mins)
4. Test webhook endpoint
5. Verify payment processing works

---

**Document Created:** November 22, 2024  
**Error Date:** November 20, 2025  
**Status:** SOLUTION PROVIDED  
**Action Required:** Grant IAM permissions in Google Cloud Console
