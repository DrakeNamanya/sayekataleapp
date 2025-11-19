# Deploy PawaPay Webhook from Browser (No PowerShell Needed!)

## 🎯 Overview

This guide shows you how to deploy your Firebase Cloud Functions webhook **directly from your browser** using **GitHub Actions** or **Firebase Console**. No PowerShell or local terminal required!

---

## ✅ **Option 1: Deploy via GitHub Actions** (RECOMMENDED - Fully Automated)

### What is GitHub Actions?
- Automated deployment from your GitHub repository
- Runs in the cloud (no local setup needed)
- One-time setup, then deploy with a single button click

### Step-by-Step Setup

#### **Step 1: Generate Firebase CI Token**

You need to generate a Firebase CI token **once**. Here's how:

**Option A: Using Google Cloud Console (Browser-only)**

1. Go to **Google Cloud Console**: https://console.cloud.google.com/
2. Select your Firebase project from the dropdown
3. Navigate to **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**:
   - Name: `github-actions-deployer`
   - Description: `Service account for GitHub Actions to deploy Cloud Functions`
5. Click **Create and Continue**
6. Grant these roles:
   - **Firebase Admin**
   - **Cloud Functions Admin**
   - **Service Account User**
7. Click **Continue** → **Done**
8. Find your new service account in the list
9. Click the **⋮** menu → **Manage Keys**
10. Click **Add Key** → **Create new key** → **JSON**
11. Download the JSON key file
12. **IMPORTANT**: Copy the entire JSON content - you'll need it in Step 2

**Option B: Using Firebase CLI (if you have access to a terminal anywhere)**

```bash
firebase login:ci
```
- This opens a browser for authentication
- Copy the token it generates

#### **Step 2: Add Firebase Token to GitHub Secrets**

1. Go to your GitHub repository: https://github.com/DrakeNamanya/sayekataleapp
2. Click **Settings** (top menu)
3. In left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Create secret:
   - **Name**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: Paste the entire JSON key from Step 1
6. Click **Add secret**

#### **Step 3: Create GitHub Actions Workflow**

Create a new file in your repository:

**File path**: `.github/workflows/deploy-functions.yml`

**Content**:
```yaml
name: Deploy Firebase Functions

on:
  # Trigger on push to main branch
  push:
    branches:
      - main
    paths:
      - 'functions/**'
  
  # Manual trigger from GitHub Actions tab
  workflow_dispatch:

jobs:
  deploy:
    name: Deploy to Firebase
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: |
          cd functions
          npm ci
      
      - name: Setup Firebase CLI
        run: npm install -g firebase-tools
      
      - name: Deploy to Firebase
        env:
          GOOGLE_APPLICATION_CREDENTIALS_JSON: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
        run: |
          # Create credentials file from secret
          echo "$GOOGLE_APPLICATION_CREDENTIALS_JSON" > $HOME/gcloud-key.json
          export GOOGLE_APPLICATION_CREDENTIALS="$HOME/gcloud-key.json"
          
          # Activate service account
          gcloud auth activate-service-account --key-file=$HOME/gcloud-key.json
          
          # Deploy functions
          firebase deploy --only functions --project YOUR_PROJECT_ID
          
          # Cleanup
          rm $HOME/gcloud-key.json
      
      - name: Deployment complete
        run: |
          echo "✅ Cloud Functions deployed successfully!"
          echo "🔗 Check your Firebase Console for the webhook URL"
```

**IMPORTANT**: Replace `YOUR_PROJECT_ID` with your actual Firebase project ID.

#### **Step 4: Commit and Push Workflow File**

You can create this file directly in GitHub:

1. Go to your repository: https://github.com/DrakeNamanya/sayekataleapp
2. Click **Add file** → **Create new file**
3. Name: `.github/workflows/deploy-functions.yml`
4. Paste the content from Step 3
5. Update `YOUR_PROJECT_ID` with your actual project ID
6. Click **Commit new file**

#### **Step 5: Deploy with One Click!** 🚀

**Option A: Automatic (on every code change)**
- Any push to `main` branch that modifies `functions/**` triggers deployment
- Just commit your changes and GitHub Actions deploys automatically

**Option B: Manual deployment**
1. Go to your repository
2. Click **Actions** tab (top menu)
3. Click **Deploy Firebase Functions** workflow (left sidebar)
4. Click **Run workflow** button (right side)
5. Click green **Run workflow** button
6. Watch the deployment progress in real-time!

#### **Step 6: Get Your Webhook URL**

After deployment completes:

1. Go to **Firebase Console**: https://console.firebase.google.com/
2. Select your project
3. Click **Functions** (left sidebar)
4. You'll see three deployed functions:
   - **pawaPayWebhook** ← This is your main webhook
   - **pawaPayWebhookHealth** ← Health check endpoint
   - **manualActivateSubscription** ← Admin utility

5. Click **pawaPayWebhook**
6. Copy the **Trigger URL** (looks like):
   ```
   https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/pawaPayWebhook
   ```

7. **Configure this URL in PawaPay Dashboard** (see main guide)

---

## ✅ **Option 2: Deploy via Firebase Console** (Manual Upload)

If GitHub Actions doesn't work, you can deploy directly through Firebase Console.

### Step 1: Prepare Your Functions Code

The code is already ready in `/home/user/flutter_app/functions/`

### Step 2: Create Deployment Package

I'll create a deployment package for you:

```bash
cd /home/user/flutter_app
tar -czf functions-deploy.tar.gz functions/
```

### Step 3: Upload to Firebase Console

**⚠️ Note**: As of 2024, Firebase Console doesn't support direct function uploads through the UI. You must use one of these methods:
- GitHub Actions (Option 1 above) - RECOMMENDED
- Google Cloud Console (Option 3 below)
- Firebase CLI from any machine with internet access

---

## ✅ **Option 3: Deploy via Google Cloud Console** (Cloud Shell)

This method uses Google Cloud's built-in browser terminal - no local setup needed!

### Step 1: Open Cloud Shell

1. Go to **Google Cloud Console**: https://console.cloud.google.com/
2. Select your Firebase project
3. Click the **Activate Cloud Shell** button (top-right, looks like `>_`)
4. A terminal opens at the bottom of your browser

### Step 2: Clone Your Repository

In Cloud Shell, run:
```bash
git clone https://github.com/DrakeNamanya/sayekataleapp.git
cd sayekataleapp
```

### Step 3: Install Dependencies

```bash
cd functions
npm install
cd ..
```

### Step 4: Deploy Functions

```bash
firebase deploy --only functions
```

If prompted to login:
```bash
firebase login --no-localhost
```
- Click the provided URL
- Authorize in your browser
- Copy the token back to Cloud Shell

### Step 5: Get Webhook URL

After deployment completes, the output shows:
```
✔  Deploy complete!

Functions URL (pawaPayWebhook):
https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/pawaPayWebhook
```

Copy this URL and configure it in PawaPay Dashboard.

---

## 🎯 **Which Option Should You Choose?**

### **GitHub Actions (Option 1)** - RECOMMENDED ✅
**Best for:**
- Long-term maintenance
- Automatic deployments
- Team collaboration
- No need to remember deployment commands

**Pros:**
- ✅ One-time setup
- ✅ Deploy with one button click
- ✅ Automatic on code changes
- ✅ No local setup required
- ✅ Deployment history and logs

**Cons:**
- ❌ Initial setup takes 10-15 minutes
- ❌ Requires GitHub repository access

---

### **Google Cloud Shell (Option 3)** - EASIEST FOR FIRST TIME ✅
**Best for:**
- Quick one-time deployment
- Testing before setting up automation
- Don't want to set up GitHub Actions yet

**Pros:**
- ✅ No local setup required
- ✅ Built into Google Cloud Console
- ✅ Works immediately
- ✅ Familiar terminal experience

**Cons:**
- ❌ Must deploy manually each time
- ❌ Requires remembering commands

---

## 🚀 **Quick Start: Deploying Right Now**

### **Fastest Method: Google Cloud Shell**

1. Open: https://console.cloud.google.com/
2. Click Cloud Shell icon (`>_`) in top-right
3. Run these commands:
   ```bash
   git clone https://github.com/DrakeNamanya/sayekataleapp.git
   cd sayekataleapp/functions
   npm install
   cd ..
   firebase deploy --only functions
   ```
4. Copy the webhook URL from the output
5. Configure in PawaPay Dashboard

**Time: 5-10 minutes**

---

## 🔍 **Verify Deployment**

After deploying with any method, verify it worked:

### Check 1: Firebase Console
1. Go to https://console.firebase.google.com/
2. Select your project
3. Click **Functions**
4. You should see 3 functions deployed

### Check 2: Health Endpoint
Open in browser:
```
https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/pawaPayWebhookHealth
```

Should return:
```json
{
  "status": "healthy",
  "message": "PawaPay webhook handler is running",
  "timestamp": "2025-11-19T..."
}
```

### Check 3: View Logs
In Firebase Console → Functions → Select function → Logs tab

---

## 🐛 **Troubleshooting**

### Issue: "Permission denied" in GitHub Actions

**Solution:**
- Verify service account has correct roles:
  - Firebase Admin
  - Cloud Functions Admin
  - Service Account User
- Re-generate service account key
- Update GitHub secret

---

### Issue: "Project not found" in Cloud Shell

**Solution:**
```bash
# Set the correct project
gcloud config set project YOUR_PROJECT_ID

# Verify
gcloud config get-value project
```

---

### Issue: GitHub Actions workflow not running

**Solution:**
- Check workflow file is in `.github/workflows/` directory
- Check file has `.yml` or `.yaml` extension
- Go to Actions tab → Check for errors
- Verify secret name matches workflow (`FIREBASE_SERVICE_ACCOUNT`)

---

### Issue: "Firebase command not found" in Cloud Shell

**Solution:**
```bash
# Install Firebase CLI in Cloud Shell
npm install -g firebase-tools

# Verify installation
firebase --version
```

---

## 📊 **GitHub Actions Monitoring**

Once set up, monitor your deployments:

1. Go to repository → **Actions** tab
2. See all deployment runs with status
3. Click any run to see detailed logs
4. Green checkmark = successful deployment
5. Red X = failed deployment (click for error details)

---

## 🎓 **Summary**

You have **3 options** to deploy without PowerShell:

1. **GitHub Actions** (Best for production) - Automated, one-click deployment
2. **Firebase Console** (Not available) - UI upload not supported yet
3. **Google Cloud Shell** (Easiest right now) - Browser terminal, works immediately

**My recommendation**: 
- Use **Google Cloud Shell** (Option 3) to deploy RIGHT NOW
- Then set up **GitHub Actions** (Option 1) for future deployments

---

## 🔗 **Next Steps After Deployment**

1. ✅ Get webhook URL from Firebase Console
2. ✅ Configure URL in PawaPay Dashboard
3. ✅ Test with small payment
4. ✅ Monitor logs in Firebase Console
5. ✅ Verify subscription activation works

---

## 💡 **Pro Tips**

### Auto-deploy on Every Commit
Add this to your GitHub Actions workflow:
```yaml
on:
  push:
    branches:
      - main
```
Now every push to main deploys automatically!

### Email Notifications
Add this to workflow:
```yaml
- name: Send deployment notification
  if: always()
  run: |
    echo "Deployment status: ${{ job.status }}"
    # Add email notification here
```

### Slack Notifications
Use Slack action:
```yaml
- name: Slack notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 📞 **Need Help?**

- Firebase Console: https://console.firebase.google.com/
- Google Cloud Console: https://console.cloud.google.com/
- GitHub Actions Docs: https://docs.github.com/en/actions
- Firebase CI/CD: https://firebase.google.com/docs/cli#cli-ci-systems

---

**Ready to deploy? Choose your method and let's get your webhook live!** 🚀

**Questions? Let me know which option you want to use and I'll help you through it step-by-step.**
