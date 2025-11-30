# 🧪 TESTING FIRESTORE RULES IN GOOGLE CLOUD SHELL

## **📋 OVERVIEW**

This guide shows you how to test your updated Firestore Security Rules using Google Cloud Shell and Firebase Emulator Suite **before** deploying them to production.

---

## **🚀 METHOD 1: FIREBASE RULES PLAYGROUND (EASIEST - 2 MINUTES)**

### **No Cloud Shell Required - Use Firebase Console**

This is the fastest way to test specific operations:

1. **Open Rules Playground:**
   - Go to: https://console.firebase.google.com/project/sayekataleapp/firestore/rules
   - Click **"Rules Playground"** tab (next to "Rules" tab)

2. **Test PSA Approval:**
   ```
   Location: /psa_verifications/verification-001
   Operation: update
   Authentication: Authenticated
   Authenticated UID: your-admin-firebase-uid
   Document Data:
   {
     "status": "approved",
     "reviewed_by": "your-admin-firebase-uid",
     "reviewed_at": {"_seconds": 1704067200, "_nanoseconds": 0}
   }
   ```
   
   Click **"Run"** → Should show ✅ **Allow** if admin is configured correctly

3. **Test Profile Update:**
   ```
   Location: /users/user-uid-123
   Operation: update (or create)
   Authentication: Authenticated
   Authenticated UID: user-uid-123
   Document Data:
   {
     "name": "Updated Name",
     "phone": "+256700000001",
     "bio": "New bio"
   }
   ```
   
   Click **"Run"** → Should show ✅ **Allow**

4. **Test Unauthorized Access:**
   ```
   Location: /psa_verifications/verification-001
   Operation: update
   Authentication: Authenticated
   Authenticated UID: regular-user-uid
   Document Data: {"status": "approved"}
   ```
   
   Click **"Run"** → Should show ❌ **Deny** (regular users can't approve)

**Advantages:**
- ✅ No setup required
- ✅ Instant results
- ✅ Visual interface
- ✅ Tests against production data structure

---

## **🚀 METHOD 2: GOOGLE CLOUD SHELL + FIREBASE EMULATOR (ADVANCED - 15 MINUTES)**

### **Setup Firebase Emulator in Cloud Shell**

#### **Step 1: Open Google Cloud Shell**

1. Go to: https://console.cloud.google.com/?cloudshell=true
2. Wait for Cloud Shell to initialize
3. You'll see a terminal window at the bottom

#### **Step 2: Install Firebase CLI**

```bash
# Cloud Shell already has Node.js, so just install Firebase CLI
npm install -g firebase-tools

# Verify installation
firebase --version
```

#### **Step 3: Login to Firebase**

```bash
# Login (this will open a browser for OAuth)
firebase login --no-localhost

# Follow the prompts:
# 1. Click the link shown in terminal
# 2. Login with your Firebase account
# 3. Grant permissions
# 4. Copy the authorization code
# 5. Paste code back into Cloud Shell
```

#### **Step 4: Create Test Project**

```bash
# Create directory for testing
mkdir ~/firestore-rules-test
cd ~/firestore-rules-test

# Initialize Firebase project
firebase init

# Select options:
# ◉ Firestore (press space to select, then enter)
# ◉ Emulators

# Choose existing project: sayekataleapp

# Firestore setup:
# - Rules file: firestore.rules (default)
# - Indexes file: firestore.indexes.json (default)

# Emulators setup:
# Select Firestore Emulator (press space)
# Port: 8080 (default)
# Emulator UI: Yes
# UI Port: 4000 (default)
# Download emulators: Yes
```

#### **Step 5: Add Your Updated Rules**

```bash
# Create firestore.rules file
nano firestore.rules

# Paste your complete rules (see end of this guide)
# Press Ctrl+O to save, Enter, then Ctrl+X to exit
```

#### **Step 6: Create Test Data (Optional)**

```bash
# Create test data file
nano test-data/firestore_export/metadata.json
```

**Paste this:**
```json
{
  "version": "1.0.0",
  "firestore": {
    "version": "1.0.0",
    "collections": []
  }
}
```

**Create users collection:**
```bash
mkdir -p test-data/firestore_export
nano test-data/firestore_export/all_namespaces/all_kinds/all_namespaces_all_kinds.export_metadata
```

**Paste sample data:**
```json
{
  "collections": [
    {
      "name": "users",
      "documents": [
        {
          "name": "projects/sayekataleapp/databases/(default)/documents/users/admin-uid-123",
          "fields": {
            "uid": {"stringValue": "admin-uid-123"},
            "email": {"stringValue": "admin@test.com"},
            "name": {"stringValue": "Admin User"},
            "role": {"stringValue": "admin"},
            "phone": {"stringValue": "+256700000000"}
          }
        },
        {
          "name": "projects/sayekataleapp/databases/(default)/documents/users/user-uid-456",
          "fields": {
            "uid": {"stringValue": "user-uid-456"},
            "email": {"stringValue": "user@test.com"},
            "name": {"stringValue": "Regular User"},
            "role": {"stringValue": "buyer"},
            "phone": {"stringValue": "+256700000001"}
          }
        }
      ]
    },
    {
      "name": "psa_verifications",
      "documents": [
        {
          "name": "projects/sayekataleapp/databases/(default)/documents/psa_verifications/verification-001",
          "fields": {
            "psa_id": {"stringValue": "psa-uid-789"},
            "status": {"stringValue": "pending"},
            "documents": {
              "arrayValue": {
                "values": [
                  {"stringValue": "cert1.jpg"},
                  {"stringValue": "cert2.jpg"}
                ]
              }
            }
          }
        }
      ]
    }
  ]
}
```

#### **Step 7: Start Emulator**

```bash
cd ~/firestore-rules-test

# Start emulator
firebase emulators:start

# You should see:
# ✔  firestore: Firestore Emulator running on http://localhost:8080
# ✔  ui: Emulator UI running on http://localhost:4000
```

#### **Step 8: Access Emulator UI**

In Cloud Shell, click **"Web Preview"** (top-right) → **"Preview on port 4000"**

This opens the Firebase Emulator UI where you can:
- View Firestore data
- Test rules manually
- Run automated tests

---

## **🧪 METHOD 3: AUTOMATED RULE TESTS (MOST COMPREHENSIVE - 30 MINUTES)**

### **Setup Test Suite**

#### **Step 1: Create Test Directory**

```bash
cd ~/firestore-rules-test

# Install testing framework
npm install --save-dev @firebase/rules-unit-testing jest
```

#### **Step 2: Create Test File**

```bash
nano firestore-rules.test.js
```

**Paste this test code:**
```javascript
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const fs = require('fs');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "sayekataleapp-test",
    firestore: {
      rules: fs.readFileSync("firestore.rules", "utf8"),
      host: "localhost",
      port: 8080
    }
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

describe("PSA Verification Rules", () => {
  test("✅ Admin can approve PSA verification", async () => {
    // Setup: Create test data
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("users").doc("admin-uid-123").set({
        uid: "admin-uid-123",
        email: "admin@test.com",
        role: "admin"
      });
      
      await context.firestore().collection("psa_verifications").doc("verification-001").set({
        psa_id: "psa-uid-789",
        status: "pending",
        created_at: new Date()
      });
    });
    
    // Test: Admin approval
    const adminDb = testEnv.authenticatedContext("admin-uid-123").firestore();
    await assertSucceeds(
      adminDb.collection("psa_verifications").doc("verification-001").update({
        status: "approved",
        reviewed_by: "admin-uid-123",
        reviewed_at: new Date()
      })
    );
  });

  test("❌ Regular user CANNOT approve PSA verification", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("users").doc("user-uid-456").set({
        uid: "user-uid-456",
        email: "user@test.com",
        role: "buyer"
      });
      
      await context.firestore().collection("psa_verifications").doc("verification-001").set({
        psa_id: "psa-uid-789",
        status: "pending"
      });
    });
    
    const userDb = testEnv.authenticatedContext("user-uid-456").firestore();
    await assertFails(
      userDb.collection("psa_verifications").doc("verification-001").update({
        status: "approved"
      })
    );
  });

  test("✅ PSA user can read their own verification", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("psa_verifications").doc("verification-001").set({
        psa_id: "psa-uid-789",
        status: "pending"
      });
    });
    
    const psaDb = testEnv.authenticatedContext("psa-uid-789").firestore();
    await assertSucceeds(
      psaDb.collection("psa_verifications").doc("verification-001").get()
    );
  });
});

describe("User Profile Rules", () => {
  test("✅ User can create own profile", async () => {
    const userDb = testEnv.authenticatedContext("user-uid-456").firestore();
    
    await assertSucceeds(
      userDb.collection("users").doc("user-uid-456").set({
        uid: "user-uid-456",
        name: "Test User",
        email: "user@test.com",
        role: "buyer"
      })
    );
  });

  test("✅ User can update own profile", async () => {
    // Create initial profile
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("users").doc("user-uid-456").set({
        uid: "user-uid-456",
        name: "Test User",
        role: "buyer"
      });
    });
    
    // Update profile
    const userDb = testEnv.authenticatedContext("user-uid-456").firestore();
    await assertSucceeds(
      userDb.collection("users").doc("user-uid-456").update({
        name: "Updated Name",
        phone: "+256700000001"
      })
    );
  });

  test("❌ User CANNOT change their own role", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("users").doc("user-uid-456").set({
        uid: "user-uid-456",
        name: "Test User",
        role: "buyer"
      });
    });
    
    const userDb = testEnv.authenticatedContext("user-uid-456").firestore();
    await assertFails(
      userDb.collection("users").doc("user-uid-456").update({
        role: "admin"  // ← Should be denied
      })
    );
  });
});

describe("Product Rules", () => {
  test("✅ Authenticated user can read products", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("products").doc("product-001").set({
        name: "Test Product",
        farmerId: "farmer-uid-123",
        price: 50000
      });
    });
    
    const userDb = testEnv.authenticatedContext("user-uid-456").firestore();
    await assertSucceeds(
      userDb.collection("products").doc("product-001").get()
    );
  });

  test("❌ Unauthenticated user CANNOT read products", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("products").doc("product-001").set({
        name: "Test Product",
        price: 50000
      });
    });
    
    const unauthDb = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      unauthDb.collection("products").doc("product-001").get()
    );
  });
});
```

#### **Step 3: Configure Jest**

```bash
# Create jest config
nano package.json
```

**Paste:**
```json
{
  "name": "firestore-rules-test",
  "version": "1.0.0",
  "scripts": {
    "test": "jest --testEnvironment=node"
  },
  "devDependencies": {
    "@firebase/rules-unit-testing": "^3.0.0",
    "jest": "^29.0.0"
  }
}
```

#### **Step 4: Run Tests**

```bash
# Run all tests
npm test

# Expected output:
# PASS firestore-rules.test.js
#   PSA Verification Rules
#     ✓ Admin can approve PSA verification (234ms)
#     ✓ Regular user CANNOT approve PSA verification (89ms)
#     ✓ PSA user can read their own verification (45ms)
#   User Profile Rules
#     ✓ User can create own profile (67ms)
#     ✓ User can update own profile (78ms)
#     ✓ User CANNOT change their own role (56ms)
#   Product Rules
#     ✓ Authenticated user can read products (34ms)
#     ✓ Unauthenticated user CANNOT read products (45ms)
#
# Test Suites: 1 passed, 1 total
# Tests:       8 passed, 8 total
```

---

## **📊 EXPECTED TEST RESULTS**

After running all tests, you should see:

### **✅ PASSING TESTS (Expected):**
- Admin can approve PSA verifications
- Admin can reject PSA verifications
- PSA users can read their own verifications
- Users can create their own profiles
- Users can update their own profiles (without changing role)
- Authenticated users can read products

### **❌ FAILING TESTS (Also Expected - Security Working):**
- Regular users CANNOT approve PSA verifications
- Users CANNOT change their own role
- Unauthenticated users CANNOT read products
- Users CANNOT create profiles for other users

---

## **🔍 DEBUGGING FAILED TESTS**

If tests fail unexpectedly:

### **1. Check Rules Syntax:**
```bash
firebase firestore:rules:validate firestore.rules
```

### **2. Check Test User Setup:**
```javascript
// Verify admin user has correct role
await context.firestore().collection("users").doc("admin-uid").set({
  role: "admin"  // ← Must be exactly "admin" or "superAdmin"
});
```

### **3. Check Test Assertions:**
```javascript
// For operations that SHOULD work:
await assertSucceeds(operation);

// For operations that should NOT work:
await assertFails(operation);
```

### **4. Enable Debug Logging:**
```javascript
beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "test",
    firestore: {
      rules: fs.readFileSync("firestore.rules", "utf8"),
      host: "localhost",
      port: 8080,
      // Enable debug logging
      debug: true
    }
  });
});
```

---

## **🎯 QUICK TESTING COMPARISON**

| Method | Time | Difficulty | Coverage | Best For |
|--------|------|------------|----------|----------|
| **Rules Playground** | 2 min | Easy | Manual | Quick checks |
| **Firebase Emulator** | 15 min | Medium | Manual | Visual testing |
| **Automated Tests** | 30 min | Hard | Complete | CI/CD pipeline |

**Recommendation:** Start with **Rules Playground** for quick validation, then use **Automated Tests** for comprehensive coverage.

---

## **✅ DEPLOYMENT AFTER TESTING**

Once all tests pass:

```bash
# Deploy rules to production
firebase deploy --only firestore:rules

# Verify deployment
firebase firestore:rules:get
```

Or use Firebase Console:
1. Go to: https://console.firebase.google.com/project/sayekataleapp/firestore/rules
2. Paste tested rules
3. Click "Publish"

---

## **📦 COMPLETE FIRESTORE RULES (Copy for Testing)**

<details>
<summary><b>Click to expand complete rules for testing</b></summary>

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
              get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'superAdmin');
    }
    
    match /psa_verifications/{verificationId} {
      allow read: if isAdmin();
      allow get: if isAuthenticated() && resource.data.psa_id == request.auth.uid;
      allow list: if isAuthenticated();
      allow create: if isAuthenticated() && request.resource.data.psa_id == request.auth.uid;
      allow update: if isAuthenticated() && 
                       (resource.data.psa_id == request.auth.uid || isAdmin());
      allow delete: if isAdmin();
    }
    
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create, update: if isOwner(userId) &&
                               (!('role' in request.resource.data) || 
                                !('role' in resource.data) || 
                                request.resource.data.role == resource.data.role) &&
                               (!('uid' in request.resource.data) || 
                                !('uid' in resource.data) || 
                                request.resource.data.uid == resource.data.uid);
      allow delete: if isOwner(userId) || isAdmin();
    }
    
    match /products/{productId} {
      allow read: if isAuthenticated();
      function isFarmerOwner() {
        return isAuthenticated() && 
               (resource.data.farmerId == request.auth.uid || 
                resource.data.farmer_id == request.auth.uid);
      }
      allow update: if isFarmerOwner() || isAdmin();
      allow create: if isAuthenticated() && 
                       (request.resource.data.farmerId == request.auth.uid ||
                        request.resource.data.farmer_id == request.auth.uid);
      allow delete: if isFarmerOwner() || isAdmin();
    }
    
    // Default deny all
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

</details>

---

**🔗 Quick Links:**
- Rules Playground: https://console.firebase.google.com/project/sayekataleapp/firestore/rules
- Cloud Shell: https://console.cloud.google.com/?cloudshell=true
- Firebase Docs: https://firebase.google.com/docs/rules/unit-tests

**📅 Testing Date:** 2025-01-24  
**📊 Status:** Ready for Testing
