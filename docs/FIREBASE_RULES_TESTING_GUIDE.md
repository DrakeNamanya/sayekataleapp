# 🧪 Firebase Security Rules Testing Guide - Google Cloud Shell

**Complete guide to testing your Firestore security rules using Firebase Emulator**

---

## 📋 **Table of Contents**

1. [Option 1: Firebase Console Rules Playground (Easiest)](#option-1-firebase-console-rules-playground)
2. [Option 2: Firebase Emulator in Cloud Shell](#option-2-firebase-emulator-in-cloud-shell)
3. [Option 3: Local Testing with Firebase CLI](#option-3-local-testing-with-firebase-cli)
4. [Test Scenarios for Your Rules](#test-scenarios)

---

## 🎯 **Option 1: Firebase Console Rules Playground (Easiest)**

**No setup required! Test directly in Firebase Console.**

### **Step 1: Access Rules Playground**

1. Go to Firebase Console: https://console.firebase.google.com/project/sayekataleapp/firestore/rules
2. Click the **"Rules Playground"** tab (next to "Rules" tab)

### **Step 2: Configure Test Environment**

**Simulator Type**: Choose between:
- **`get`** - Test reading a single document
- **`list`** - Test querying/listing documents
- **`create`** - Test creating new documents
- **`update`** - Test updating existing documents
- **`delete`** - Test deleting documents

### **Step 3: Set Up Authentication**

**Authenticated User:**
```
Location: /users/abc123
Auth: Authenticated
Provider: Custom
UID: abc123
```

**Admin User:**
```
Location: /psa_verifications/xyz789
Auth: Authenticated
Provider: Custom
UID: admin-uid-123
```

### **Step 4: Run Test Scenarios**

#### **Test 1: PSA Approval (Admin Operation)**

**Setup:**
- **Operation**: `update`
- **Location**: `/psa_verifications/test-verification-001`
- **Authentication**: 
  - Provider: `Custom`
  - UID: `admin-user-123`
- **Existing Data** (Before):
```json
{
  "psa_id": "psa-user-456",
  "status": "pending",
  "business_name": "Test Business",
  "submitted_at": "2025-11-30T00:00:00Z"
}
```
- **New Data** (After):
```json
{
  "psa_id": "psa-user-456",
  "status": "approved",
  "business_name": "Test Business",
  "submitted_at": "2025-11-30T00:00:00Z",
  "reviewed_by": "admin-user-123",
  "reviewed_at": "2025-11-30T12:00:00Z"
}
```

**Expected Result**: ✅ **Allowed** (if admin document exists in `admin_users`)

---

#### **Test 2: User Profile Update**

**Setup:**
- **Operation**: `update`
- **Location**: `/users/user-123`
- **Authentication**: 
  - Provider: `Custom`
  - UID: `user-123`
- **Existing Data**:
```json
{
  "uid": "user-123",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "customer",
  "district": "IGANGA"
}
```
- **New Data**:
```json
{
  "uid": "user-123",
  "name": "John Doe Updated",
  "email": "john@example.com",
  "role": "customer",
  "district": "JINJA"
}
```

**Expected Result**: ✅ **Allowed** (user updating own profile, role unchanged)

---

#### **Test 3: Unauthorized Role Change (Should Fail)**

**Setup:**
- **Operation**: `update`
- **Location**: `/users/user-123`
- **Authentication**: 
  - Provider: `Custom`
  - UID: `user-123`
- **Existing Data**:
```json
{
  "uid": "user-123",
  "role": "customer"
}
```
- **New Data**:
```json
{
  "uid": "user-123",
  "role": "admin"
}
```

**Expected Result**: ❌ **Denied** (users cannot change their own role)

---

#### **Test 4: Product Creation**

**Setup:**
- **Operation**: `create`
- **Location**: `/products/new-product-123`
- **Authentication**: 
  - Provider: `Custom`
  - UID: `farmer-456`
- **New Data**:
```json
{
  "farmerId": "farmer-456",
  "name": "Fresh Tomatoes",
  "price": 5000,
  "stock_quantity": 100,
  "created_at": "2025-11-30T12:00:00Z"
}
```

**Expected Result**: ✅ **Allowed** (authenticated user creating product with self as farmer)

---

#### **Test 5: Order Creation**

**Setup:**
- **Operation**: `create`
- **Location**: `/orders/new-order-789`
- **Authentication**: 
  - Provider: `Custom`
  - UID: `buyer-789`
- **New Data**:
```json
{
  "buyer_id": "buyer-789",
  "farmerId": "farmer-456",
  "productId": "product-123",
  "quantity": 10,
  "total_amount": 50000,
  "status": "pending",
  "created_at": "2025-11-30T12:00:00Z"
}
```

**Expected Result**: ✅ **Allowed** (authenticated user creating order as buyer)

---

## 🖥️ **Option 2: Firebase Emulator in Google Cloud Shell**

**Test rules locally with real Firebase SDK calls**

### **Step 1: Open Google Cloud Shell**

1. Go to: https://console.cloud.google.com/
2. Click the **Cloud Shell** icon (top right, looks like `>_`)
3. Wait for shell to initialize

### **Step 2: Install Firebase CLI**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Verify installation
firebase --version
```

**Expected Output**: `13.x.x` or similar

### **Step 3: Login to Firebase**

```bash
# Login with your Google account
firebase login --no-localhost

# Copy the URL shown and open in browser
# Authorize access
# Copy the authorization code
# Paste back in Cloud Shell
```

**Alternative (if login issues):**
```bash
# Use CI token (get from: firebase login:ci)
export FIREBASE_TOKEN="your-ci-token-here"
```

### **Step 4: Clone Your Project (Optional)**

```bash
# Clone your GitHub repo
git clone https://github.com/DrakeNamanya/sayekataleapp.git
cd sayekataleapp
```

**Or create a new test directory:**
```bash
mkdir firebase-rules-test
cd firebase-rules-test
```

### **Step 5: Initialize Firebase Project**

```bash
# Initialize Firebase
firebase init

# Select:
# - Firestore (use arrow keys, space to select)
# - Use existing project: sayekataleapp
# - Firestore rules file: firestore.rules (or press Enter)
# - Firestore indexes file: firestore.indexes.json (or press Enter)
# - Emulators: YES
#   - Select: Firestore Emulator
#   - Port: 8080 (default)
#   - Enable UI: YES
#   - UI Port: 4000 (default)
```

### **Step 6: Copy Your Rules File**

If you cloned the repo, the rules are already there. Otherwise:

```bash
# Create rules file
cat > firestore.rules << 'EOF'
# Paste the complete rules here (from previous message)
# ... (copy all 583 lines)
EOF
```

Or upload your local `firestore.rules` file using Cloud Shell's upload feature.

### **Step 7: Start Firebase Emulator**

```bash
# Start emulator
firebase emulators:start

# Expected output:
# ┌─────────────────────────────────────────────────────────────┐
# │ ✔  All emulators ready! It is now safe to connect your app. │
# │ i  View Emulator UI at http://127.0.0.1:4000                │
# └─────────────────────────────────────────────────────────────┘
# 
# ┌────────────┬────────────────┬─────────────────────────────────┐
# │ Emulator   │ Host:Port      │ View in Emulator UI             │
# ├────────────┼────────────────┼─────────────────────────────────┤
# │ Firestore  │ 127.0.0.1:8080 │ http://127.0.0.1:4000/firestore │
# └────────────┴────────────────┴─────────────────────────────────┘
```

### **Step 8: Access Emulator UI**

**In Cloud Shell:**
```bash
# Cloud Shell provides a web preview
# Click "Web Preview" button (top right)
# Select "Preview on port 4000"
```

**Or use Cloud Shell proxy:**
```bash
# Get Cloud Shell web preview URL
echo "https://4000-$DEVSHELL_PROJECT_ID.cloudshell.dev/"
```

### **Step 9: Test Rules in Emulator UI**

1. **Open Emulator UI** (from step 8)
2. Navigate to **"Firestore"** tab
3. Click **"Rules"** subtab
4. You'll see your loaded rules
5. Create test data and try operations

---

## 🧪 **Option 3: Automated Testing with Firebase CLI**

**Write test scripts to validate rules programmatically**

### **Step 1: Install Firebase Testing Dependencies**

```bash
# In Cloud Shell or local terminal
npm install -D @firebase/rules-unit-testing
```

### **Step 2: Create Test File**

```bash
# Create test directory
mkdir test
cd test

# Create test file
cat > firestore.test.js << 'EOF'
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'sayekataleapp-test',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe('Firestore Security Rules', () => {
  
  // Test 1: PSA Verification - Admin can approve
  test('Admin can approve PSA verification', async () => {
    const adminDb = testEnv.authenticatedContext('admin-user-123').firestore();
    
    // Setup: Create admin user document
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('admin_users').doc('admin-user-123').set({
        role: 'admin',
        email: 'admin@example.com'
      });
      
      await context.firestore().collection('psa_verifications').doc('verification-001').set({
        psa_id: 'psa-user-456',
        status: 'pending'
      });
    });
    
    // Test: Admin updates verification status
    await assertSucceeds(
      adminDb.collection('psa_verifications').doc('verification-001').update({
        status: 'approved',
        reviewed_by: 'admin-user-123'
      })
    );
  });
  
  // Test 2: PSA Verification - Non-admin cannot approve
  test('Non-admin cannot approve PSA verification', async () => {
    const userDb = testEnv.authenticatedContext('regular-user-789').firestore();
    
    await assertFails(
      userDb.collection('psa_verifications').doc('verification-001').update({
        status: 'approved'
      })
    );
  });
  
  // Test 3: User can update own profile
  test('User can update own profile', async () => {
    const userDb = testEnv.authenticatedContext('user-123').firestore();
    
    // Setup: Create user profile
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('user-123').set({
        uid: 'user-123',
        name: 'John Doe',
        role: 'customer'
      });
    });
    
    // Test: User updates own profile
    await assertSucceeds(
      userDb.collection('users').doc('user-123').update({
        name: 'John Updated'
      })
    );
  });
  
  // Test 4: User cannot change own role
  test('User cannot change own role', async () => {
    const userDb = testEnv.authenticatedContext('user-123').firestore();
    
    await assertFails(
      userDb.collection('users').doc('user-123').update({
        role: 'admin'
      })
    );
  });
  
  // Test 5: User can create product as farmer
  test('User can create product with self as farmer', async () => {
    const farmerDb = testEnv.authenticatedContext('farmer-456').firestore();
    
    await assertSucceeds(
      farmerDb.collection('products').add({
        farmerId: 'farmer-456',
        name: 'Fresh Tomatoes',
        price: 5000
      })
    );
  });
  
  // Test 6: User cannot create product for another farmer
  test('User cannot create product for another farmer', async () => {
    const userDb = testEnv.authenticatedContext('user-789').firestore();
    
    await assertFails(
      userDb.collection('products').add({
        farmerId: 'farmer-456',
        name: 'Fake Product'
      })
    );
  });
  
  // Test 7: User can create order as buyer
  test('User can create order as buyer', async () => {
    const buyerDb = testEnv.authenticatedContext('buyer-123').firestore();
    
    await assertSucceeds(
      buyerDb.collection('orders').add({
        buyer_id: 'buyer-123',
        farmerId: 'farmer-456',
        productId: 'product-789',
        quantity: 10
      })
    );
  });
  
  // Test 8: Cloud Function can create transaction (no auth)
  test('Cloud Function can create transaction', async () => {
    const unauthDb = testEnv.unauthenticatedContext().firestore();
    
    await assertSucceeds(
      unauthDb.collection('transactions').add({
        userId: 'user-123',
        amount: 50000,
        status: 'initiated',
        type: 'deposit'
      })
    );
  });
  
  // Test 9: User can manage own cart
  test('User can manage own cart items', async () => {
    const userDb = testEnv.authenticatedContext('user-123').firestore();
    
    await assertSucceeds(
      userDb.collection('cart_items').add({
        user_id: 'user-123',
        productId: 'product-456',
        quantity: 5
      })
    );
  });
  
  // Test 10: User cannot access another user's cart
  test('User cannot read another user cart items', async () => {
    const userDb = testEnv.authenticatedContext('user-789').firestore();
    
    // Setup: Create cart item for another user
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('cart_items').doc('cart-001').set({
        user_id: 'user-123',
        productId: 'product-456'
      });
    });
    
    await assertFails(
      userDb.collection('cart_items').doc('cart-001').get()
    );
  });
  
});
EOF
```

### **Step 3: Update package.json**

```bash
cd ..  # Back to project root

# Create or update package.json
cat > package.json << 'EOF'
{
  "name": "firebase-rules-test",
  "version": "1.0.0",
  "scripts": {
    "test": "jest --testEnvironment=node --detectOpenHandles"
  },
  "devDependencies": {
    "@firebase/rules-unit-testing": "^3.0.0",
    "jest": "^29.0.0"
  }
}
EOF
```

### **Step 4: Install Dependencies**

```bash
npm install
```

### **Step 5: Run Tests**

```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific test
npm test -- --testNamePattern="Admin can approve"
```

**Expected Output:**
```
PASS  test/firestore.test.js
  Firestore Security Rules
    ✓ Admin can approve PSA verification (125ms)
    ✓ Non-admin cannot approve PSA verification (45ms)
    ✓ User can update own profile (38ms)
    ✓ User cannot change own role (42ms)
    ✓ User can create product with self as farmer (51ms)
    ✓ User cannot create product for another farmer (39ms)
    ✓ User can create order as buyer (47ms)
    ✓ Cloud Function can create transaction (33ms)
    ✓ User can manage own cart items (41ms)
    ✓ User cannot read another user cart items (44ms)

Test Suites: 1 passed, 1 total
Tests:       10 passed, 10 total
Time:        2.345s
```

---

## 🎯 **Test Scenarios for Your Rules**

### **Critical Test Cases**

#### **1. Admin Operations**

✅ **Should Pass:**
- Admin can read all PSA verifications
- Admin can approve PSA verification
- Admin can reject PSA verification
- Admin can delete any user
- Admin can update any complaint

❌ **Should Fail:**
- Regular user cannot approve PSA verification
- Regular user cannot access admin logs
- Unauthenticated user cannot read admin_users

---

#### **2. PSA Verification**

✅ **Should Pass:**
- PSA user can create verification with own psa_id
- PSA user can read own verification status
- PSA user can update own pending verification
- Admin can update any verification

❌ **Should Fail:**
- PSA user cannot create verification for another user
- PSA user cannot read another user's verification
- Regular user cannot update PSA verification

---

#### **3. User Profile**

✅ **Should Pass:**
- User can create own profile during signup
- User can update own profile (name, location, etc.)
- User can delete own account
- Admin can update any user profile

❌ **Should Fail:**
- User cannot change own role
- User cannot change own uid
- User cannot update another user's profile
- Unauthenticated user cannot read profiles

---

#### **4. Products**

✅ **Should Pass:**
- User can create product with self as farmer
- Product owner can update own product
- Product owner can delete own product
- Any authenticated user can read products

❌ **Should Fail:**
- User cannot create product for another farmer
- User cannot update another farmer's product
- User cannot delete another farmer's product

---

#### **5. Orders**

✅ **Should Pass:**
- Buyer can create order with self as buyer
- Buyer can update own order status
- Seller can update order for their products
- Any authenticated user can list orders

❌ **Should Fail:**
- User cannot create order for another buyer
- User cannot read orders they're not part of
- User cannot update orders they're not part of

---

#### **6. Transactions (Webhooks)**

✅ **Should Pass:**
- Cloud Function (no auth) can create transactions
- Cloud Function can update transaction status
- User can read own transactions
- User can list own transactions

❌ **Should Fail:**
- User cannot create transactions directly
- User cannot update transaction status
- User cannot read another user's transactions

---

#### **7. Cart & Favorites**

✅ **Should Pass:**
- User can add items to own cart
- User can update own cart items
- User can delete own cart items
- User can manage own favorites

❌ **Should Fail:**
- User cannot read another user's cart
- User cannot modify another user's cart
- User cannot access another user's favorites

---

## 📊 **Test Results Interpretation**

### **Success Indicators**

✅ All admin operations pass  
✅ All ownership checks work correctly  
✅ All permission denials work as expected  
✅ Cloud Functions can access webhook collections  
✅ Users are isolated from each other's data  

### **Common Issues**

❌ **"Permission denied" on valid operation**
- Check if user document exists
- Verify authentication context
- Confirm field names match (userId vs user_id)

❌ **"Unauthenticated" error**
- Ensure test context includes auth
- Check if UID is properly set

❌ **Admin operations fail**
- Verify admin document exists in `admin_users`
- Check admin role is 'admin' or 'superAdmin'

---

## 🔧 **Debugging Tips**

### **Enable Debug Logging**

```javascript
// In test file
const { setLogLevel } = require('@firebase/rules-unit-testing');
setLogLevel('debug');
```

### **Check Rule Evaluation**

```bash
# In Cloud Shell
firebase emulators:start --debug

# Shows detailed rule evaluation
```

### **Inspect Emulator Data**

1. Open Emulator UI
2. Go to Firestore tab
3. View all collections and documents
4. Manually test operations

---

## ✅ **Best Practices**

1. **Test all user roles** - Admin, PSA, SHG, SME, Customer
2. **Test negative cases** - Ensure unauthorized access is blocked
3. **Test edge cases** - Empty data, missing fields, null values
4. **Test Cloud Functions** - Webhook operations without auth
5. **Test cascading operations** - Account deletion, order updates
6. **Keep tests updated** - When rules change, update tests

---

## 🔗 **Resources**

- **Firebase Emulator Docs**: https://firebase.google.com/docs/emulator-suite
- **Rules Unit Testing**: https://firebase.google.com/docs/rules/unit-tests
- **Rules Language**: https://firebase.google.com/docs/rules/rules-language
- **Cloud Shell**: https://console.cloud.google.com/cloudshell

---

## 📝 **Quick Command Reference**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login --no-localhost

# Initialize project
firebase init firestore

# Start emulator
firebase emulators:start

# Run tests
npm test

# Stop emulator
Ctrl+C
```

---

**🎯 Start with Option 1 (Rules Playground) for quick testing, then move to Option 2 (Emulator) for comprehensive testing!**

---

**End of Guide**
