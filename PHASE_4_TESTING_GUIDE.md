# 🧪 Phase 4 Testing Guide - Complete Transaction Flow

## 📱 Testing Environment

**App URL:** https://5060-i25ra390rl3tp6c83ufw7-de59bda9.sandbox.novita.ai  
**Server Status:** ✅ Running on port 5060  
**Build:** Release mode (optimized)

**⚠️ IMPORTANT:** Press `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac) to hard refresh browser and load latest build!

---

## 🎯 Testing Objectives

We need to verify:
1. ✅ Complete authentication flow works
2. ✅ Farmers can receive orders in real-time
3. ✅ Farmers can accept/reject orders
4. ✅ Order status progression works
5. ✅ Revenue tracking updates correctly
6. ✅ Buyers see real-time order updates
7. ✅ Multi-farmer orders split correctly

---

## 🔐 Test Accounts Setup

### **Account 1: Buyer (Sarah)**
Use these details to create a buyer account:
```
Role: SME/Buyer
Email: sarah.buyer@test.com
Password: Test123456!
Name: Sarah Buyer
Phone: +256700000001
```

### **Account 2: Farmer (John Nama)**
Use these details to create farmer account:
```
Role: SHG/Farmer
Email: john.nama@test.com
Password: Test123456!
Name: John Nama
Phone: +256700111111
District: Kampala
```

### **Account 3: Farmer (Ngobi Peter)**
Use these details to create farmer account:
```
Role: SHG/Farmer
Email: ngobi.peter@test.com
Password: Test123456!
Name: Ngobi Peter
Phone: +256700222222
District: Wakiso
```

---

## 📋 Test Scenarios

### **Test 1: Authentication Flow** ⏸️ START HERE

**Objective:** Verify email authentication works for all roles

**Steps:**

1. **Create Buyer Account (Sarah):**
   - Open app URL in browser
   - Click "Create Account"
   - Select role: "SME/Buyer"
   - Enter email: sarah.buyer@test.com
   - Enter password: Test123456!
   - Enter name: Sarah Buyer
   - Enter phone: +256700000001
   - Click "Create Account"
   
   **✅ Expected Result:**
   - Account created successfully
   - Redirected to SME dashboard
   - Dashboard shows "Welcome, Sarah Buyer"

2. **Logout and Test Login:**
   - Click profile icon → Logout
   - Click "Sign In"
   - Enter email: sarah.buyer@test.com
   - Enter password: Test123456!
   - Click "Sign In"
   
   **✅ Expected Result:**
   - Login successful
   - Back to SME dashboard

3. **Create Farmer Account (John Nama):**
   - Logout
   - Click "Create Account"
   - Select role: "SHG/Farmer"
   - Enter details (see Account 2 above)
   - Click "Create Account"
   
   **✅ Expected Result:**
   - Account created successfully
   - Redirected to SHG (Farmer) dashboard
   - Dashboard shows "Welcome, John Nama"

4. **Create Farmer Account (Ngobi Peter):**
   - Logout
   - Repeat steps for Account 3
   
   **✅ Expected Result:**
   - Account created successfully
   - Farmer dashboard visible

**Status:** ⏸️ NOT STARTED  
**Issues Found:** _______________

---

### **Test 2: Product Setup** 

**Objective:** Farmers add products to their inventory

**Steps:**

1. **Login as John Nama:**
   - Email: john.nama@test.com
   - Password: Test123456!

2. **Navigate to Products:**
   - Click "My Products" from dashboard
   - Click "Add Product" button (+ icon)

3. **Add Product 1: Tomatoes**
   ```
   Product Name: Fresh Tomatoes
   Category: Vegetables
   Price: 5000 (UGX per kg)
   Unit: kg
   Stock: 100
   Description: Fresh organic tomatoes from my farm
   ```
   - Take/upload photo (or use placeholder)
   - Click "Save"
   
   **✅ Expected Result:**
   - Product saved successfully
   - Appears in "My Products" list

4. **Add Product 2: Cabbage**
   ```
   Product Name: Green Cabbage
   Category: Vegetables
   Price: 3000 (UGX per kg)
   Unit: kg
   Stock: 50
   Description: Fresh green cabbage
   ```
   - Click "Save"

5. **Repeat for Ngobi Peter:**
   - Logout, login as ngobi.peter@test.com
   - Add Product 1: Beans (8000 UGX/kg, stock: 80)
   - Add Product 2: Maize (6000 UGX/kg, stock: 120)

**✅ Expected Results:**
- Both farmers have products in inventory
- Products show correct prices and details

**Status:** ⏸️ NOT STARTED  
**Issues Found:** _______________

---

### **Test 3: Shopping Cart Flow** 

**Objective:** Buyer can browse products and add to cart

**Steps:**

1. **Login as Sarah (Buyer):**
   - Email: sarah.buyer@test.com
   - Password: Test123456!

2. **Browse Products:**
   - Dashboard shows "Shop" or product browsing section
   - Should see products from both John Nama and Ngobi Peter
   
   **✅ Expected Result:**
   - Can see all available products
   - Products show farmer name
   - Products show price per unit

3. **Add Products to Cart:**
   - Find "Fresh Tomatoes" (John Nama) → Click "Add to Cart"
   - Set quantity: 10 kg → Confirm
   - Find "Green Cabbage" (John Nama) → Add 5 kg to cart
   - Find "Beans" (Ngobi Peter) → Add 8 kg to cart
   
   **✅ Expected Result:**
   - Cart badge shows "3 items"
   - Items added successfully

4. **View Cart:**
   - Click cart icon
   - Should see all 3 items listed
   
   **✅ Expected Result:**
   - Cart shows:
     * Fresh Tomatoes (John Nama) - 10 kg × 5,000 = 50,000 UGX
     * Green Cabbage (John Nama) - 5 kg × 3,000 = 15,000 UGX
     * Beans (Ngobi Peter) - 8 kg × 8,000 = 64,000 UGX
   - Total: 129,000 UGX

5. **Test Cart Functions:**
   - Increase quantity of Tomatoes to 12 kg
   - Decrease quantity of Beans to 6 kg
   
   **✅ Expected Result:**
   - Quantities update
   - Totals recalculate correctly
   - New total: 50,000 + 15,000 + 48,000 = 113,000 UGX

**Status:** ⏸️ NOT STARTED  
**Issues Found:** _______________

---

### **Test 4: Checkout and Order Placement** 🔥 CRITICAL

**Objective:** Complete checkout creates orders correctly

**Steps:**

1. **From Cart Screen:**
   - Click "Proceed to Checkout" button
   
   **✅ Expected Result:**
   - Navigates to checkout screen
   - Shows order summary

2. **Enter Delivery Details:**
   ```
   Delivery Address: Kampala Central, Plot 123, Main Street
   Delivery Notes: Please call when you arrive at the gate
   ```

3. **Select Payment Method:**
   - Choose "Cash on Delivery"

4. **Review Order:**
   - Check all items are listed
   - Verify totals are correct
   
   **✅ Expected Result:**
   - Shows 2 separate order summaries:
     * Order 1 (John Nama): Tomatoes + Cabbage = 65,000 UGX
     * Order 2 (Ngobi Peter): Beans = 48,000 UGX

5. **Place Order:**
   - Click "Place Order" button
   
   **✅ Expected Result:**
   - Success message: "2 order(s) placed successfully!"
   - Cart is cleared (badge shows 0)
   - Redirected to dashboard or orders screen

**Status:** ⏸️ NOT STARTED  
**Issues Found:** _______________

---

### **Test 5: Farmer Receives Order (Real-time)** 🔥 CRITICAL

**Objective:** Verify real-time order notifications work

**Steps:**

1. **Keep Buyer Session Open:**
   - Leave Sarah's browser tab open

2. **Open New Browser Tab/Window:**
   - Go to app URL
   - Login as John Nama

3. **Navigate to Orders Screen:**
   - Click "Orders" from dashboard menu
   - Should land on "Pending" tab
   
   **✅ Expected Result:**
   - NEW order appears automatically (no refresh needed!)
   - Order shows:
     * Buyer: Sarah Buyer (+256700000001)
     * Items: Tomatoes (12 kg), Cabbage (5 kg)
     * Total: 65,000 UGX
     * Status: PENDING (orange badge)
     * Action buttons: "Accept" and "Reject"

4. **Check Order Details:**
   - Click on the order card
   
   **✅ Expected Result:**
   - Dialog opens with complete order details
   - Shows delivery address and notes
   - Shows payment method: Cash on Delivery

5. **Test Ngobi Peter's Order:**
   - Open another tab
   - Login as Ngobi Peter
   - Go to Orders screen
   
   **✅ Expected Result:**
   - Sees his order (Beans - 6 kg)
   - Total: 48,000 UGX
   - Separate from John Nama's order

**Status:** ⏸️ NOT STARTED  
**Issues Found:** _______________

---

### **Test 6: Accept Order Flow** 🔥 CRITICAL

**Objective:** Farmer can accept orders

**Steps:**

1. **As John Nama (Orders Screen):**
   - Find the pending order
   - Click "Accept Order" button
   
   **✅ Expected Result:**
   - Success message: "Order accepted successfully!"
   - Order moves from "Pending" tab to "Active" tab
   - Status changes to "CONFIRMED" (blue badge)
   - New action button appears: "Mark as Preparing"

2. **Check Buyer Sees Update:**
   - Switch to Sarah's browser tab
   - Navigate to "My Orders" (if not already there)
   
   **✅ Expected Result:**
   - Order status shows "CONFIRMED" (no page refresh needed!)
   - Real-time update visible

**Status:** ⏸️ NOT STARTED  
**Issues Found:** _______________

---

### **Test 7: Reject Order Flow**

**Objective:** Farmer can reject orders with reason

**Steps:**

1. **As Ngobi Peter (Orders Screen):**
   - Find the pending order (Beans)
   - Click "Reject" button
   
   **✅ Expected Result:**
   - Dialog appears asking for rejection reason

2. **Enter Rejection Reason:**
   ```
   Reason: Currently out of stock. Will have more beans next week.
   ```
   - Click "Reject Order" button
   
   **✅ Expected Result:**
   - Order status changes to "REJECTED" (red badge)
   - Order moves to "History" tab
   - Success message shown

3. **Check Buyer Sees Rejection:**
   - Switch to Sarah's browser tab
   - View order details for Beans order
   
   **✅ Expected Result:**
   - Order shows "REJECTED" status
   - Rejection reason is visible: "Currently out of stock..."

**Status:** ⏸️ NOT STARTED  
**Issues Found:** _______________

---

### **Test 8: Order Status Progression** 🔥 CRITICAL

**Objective:** Complete order lifecycle works

**Steps:**

1. **As John Nama (Active Orders Tab):**
   - Find the confirmed order
   - Current status: "CONFIRMED"

2. **Mark as Preparing:**
   - Click "Mark as Preparing" button
   
   **✅ Expected Result:**
   - Status changes to "PREPARING" (blue badge)
   - Next button appears: "Mark as Ready"

3. **Mark as Ready:**
   - Click "Mark as Ready" button
   
   **✅ Expected Result:**
   - Status changes to "READY" (purple badge)
   - Next button: "Mark as In Transit"

4. **Mark as In Transit:**
   - Click "Mark as In Transit" button
   
   **✅ Expected Result:**
   - Status changes to "IN TRANSIT" (purple badge)
   - Next button: "Mark as Delivered"

5. **Mark as Delivered:**
   - Click "Mark as Delivered" button
   
   **✅ Expected Result:**
   - Status changes to "DELIVERED" (green badge)
   - Order moves to "History" tab
   - Success message shown

6. **Verify Each Status Update on Buyer Side:**
   - Switch to Sarah's tab after each status change
   
   **✅ Expected Result:**
   - Status updates appear in real-time (no refresh needed!)
   - Buyer sees: CONFIRMED → PREPARING → READY → IN TRANSIT → DELIVERED

**Status:** ⏸️ NOT STARTED  
**Issues Found:** _______________

---

### **Test 9: Revenue Tracking** 🔥 CRITICAL

**Objective:** Revenue card updates correctly

**Steps:**

1. **As John Nama (Orders Screen):**
   - Look at the top of the screen
   - Find "Total Revenue" card
   
   **✅ Expected Result BEFORE delivery:**
   - Shows: UGX 0 (or previous revenue)

2. **After Marking Order as Delivered:**
   - Order total: 65,000 UGX
   - Check revenue card
   
   **✅ Expected Result:**
   - Revenue card updates to show: UGX 65,000
   - Card has green gradient design
   - Shows wallet icon

3. **Place Another Order and Complete:**
   - Have Sarah place another order
   - Accept and deliver it
   
   **✅ Expected Result:**
   - Revenue increments correctly
   - Shows sum of all delivered orders

**Status:** ⏸️ NOT STARTED  
**Issues Found:** _______________

---

### **Test 10: Order History**

**Objective:** Order history preserved correctly

**Steps:**

1. **As John Nama:**
   - Navigate to "History" tab
   
   **✅ Expected Result:**
   - Shows all completed/delivered orders
   - Shows delivered order with green status

2. **As Sarah (Buyer):**
   - Navigate to "My Orders"
   - Click "Completed" tab
   
   **✅ Expected Result:**
   - Shows delivered order
   - Can view order details
   - Shows final status

**Status:** ⏸️ NOT STARTED  
**Issues Found:** _______________

---

### **Test 11: Multi-Farmer Order Splitting** 🔥 CRITICAL

**Objective:** Orders split correctly by farmer

**Steps:**

1. **As Sarah (Buyer):**
   - Clear cart if needed
   - Add products from BOTH farmers:
     * From John Nama: Tomatoes (5 kg)
     * From Ngobi Peter: Maize (10 kg)
   - Proceed to checkout
   - Place order

2. **Check Order Splitting:**
   
   **✅ Expected Result:**
   - Success message says "2 order(s) placed"
   - Two separate orders created

3. **Verify Each Farmer Sees Their Order:**
   - Login as John Nama → Should see Tomatoes order only
   - Login as Ngobi Peter → Should see Maize order only
   
   **✅ Expected Result:**
   - Each farmer only sees their own items
   - Order totals calculated correctly per farmer

**Status:** ⏸️ NOT STARTED  
**Issues Found:** _______________

---

### **Test 12: Real-time Synchronization**

**Objective:** Multiple devices sync properly

**Steps:**

1. **Open Two Browser Windows Side-by-Side:**
   - Window 1: Login as John Nama (Orders screen)
   - Window 2: Login as Sarah (Orders screen)

2. **Place Order from Third Window:**
   - Open third window
   - Login as another buyer
   - Place order for John Nama's products

3. **Observe Real-time Update:**
   
   **✅ Expected Result:**
   - John Nama's window shows new order immediately (no refresh!)
   - Order appears in "Pending" tab automatically

4. **Accept Order in Window 1:**
   - Click "Accept Order"
   
   **✅ Expected Result:**
   - Sarah's window shows status change to "CONFIRMED" (no refresh!)

**Status:** ⏸️ NOT STARTED  
**Issues Found:** _______________

---

## 🐛 Bug Reporting Template

If you find issues, document them here:

### **Bug #1:**
- **Test:** [Test number and name]
- **Steps to Reproduce:** [What you did]
- **Expected Result:** [What should happen]
- **Actual Result:** [What actually happened]
- **Severity:** [Critical / High / Medium / Low]
- **Screenshot/Error:** [If available]

### **Bug #2:**
[Same format]

---

## ✅ Testing Checklist

Use this to track your progress:

- [ ] Test 1: Authentication Flow
- [ ] Test 2: Product Setup
- [ ] Test 3: Shopping Cart Flow
- [ ] Test 4: Checkout and Order Placement
- [ ] Test 5: Farmer Receives Order (Real-time)
- [ ] Test 6: Accept Order Flow
- [ ] Test 7: Reject Order Flow
- [ ] Test 8: Order Status Progression
- [ ] Test 9: Revenue Tracking
- [ ] Test 10: Order History
- [ ] Test 11: Multi-Farmer Order Splitting
- [ ] Test 12: Real-time Synchronization

---

## 🎯 Success Criteria

Phase 4 is fully functional if:

✅ **Authentication:**
- All 3 accounts can be created and login successfully
- Correct dashboards shown for each role

✅ **Order Placement:**
- Buyers can add products to cart
- Checkout creates orders correctly
- Multi-farmer orders split automatically

✅ **Real-time Updates:**
- Farmers receive orders instantly (no refresh)
- Status changes appear immediately for buyers
- No delays or lag

✅ **Order Management:**
- Farmers can accept/reject orders
- Status progression works through all stages
- Rejection reasons stored and displayed

✅ **Revenue Tracking:**
- Revenue card updates when orders delivered
- Shows correct totals
- Increments properly with multiple orders

✅ **Data Integrity:**
- Orders stored correctly in Firestore
- All order details preserved
- History accessible for both buyers and farmers

---

## 🔧 Troubleshooting

### **Issue: Orders not appearing in real-time**
- **Solution:** Hard refresh browser (Ctrl+Shift+R)
- Check browser console for errors
- Verify Firestore connection

### **Issue: Cart not saving items**
- **Solution:** Check authentication status
- Verify buyer is logged in
- Check browser console for Firestore errors

### **Issue: Revenue not updating**
- **Solution:** Verify order status is "DELIVERED" or "COMPLETED"
- Only these statuses count toward revenue
- Refresh orders screen

### **Issue: Can't create account**
- **Solution:** Check Firebase Authentication is enabled
- Verify email format is correct
- Check password meets requirements (6+ chars)

---

## 📞 Support

**Documentation:**
- `PHASE_4_FARMER_ORDER_DASHBOARD_COMPLETE.md` - Feature documentation
- `TRANSACTION_FLOW_COMPLETE.md` - Complete flow guide

**App URL:** https://5060-i25ra390rl3tp6c83ufw7-de59bda9.sandbox.novita.ai

**Remember:** Always hard refresh (Ctrl+Shift+R) when testing!

---

## 📝 Testing Notes

Use this space for any additional observations:

```
[Your notes here]
```

---

**Happy Testing! 🎉**

Let me know when you've completed the tests and we can review results together!
