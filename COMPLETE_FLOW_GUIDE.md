# 🎯 Complete PSA → SHG Order Flow Guide

## Overview
This guide demonstrates the complete end-to-end flow from PSA product creation to SHG order placement and delivery.

---

## 📱 Part 1: PSA Creates Products

### Step 1: PSA Login
1. Open app: https://5060-i25ra390rl3tp6c83ufw7-de59bda9.sandbox.novita.ai
2. Login with PSA credentials
3. Navigate to PSA Dashboard

### Step 2: Add New Product
1. Click on **"Products"** in the navigation
2. Click **"Add Product"** button (floating action button)
3. Fill in product details:

   ```
   Product Name: Hybrid Maize Seeds (10kg)
   Category: Crop (or select appropriate category)
   Description: High-yield hybrid maize seeds suitable for Uganda climate
   Price: 450000 (UGX)
   Unit: bag
   Unit Size: 10
   Stock Quantity: 120
   ```

4. Optional: Add product image (tap on image placeholder)
5. Click **"Add Product"** button
6. ✅ Success message appears: "✅ Product added successfully!"
7. Product appears in the products list immediately

### Step 3: Verify Product is Saved
**In the App:**
- Product appears in your Products list
- Product count in category tab increases
- Product details are correct

**In Firebase Console (if you have access):**
- Go to Firestore Database
- Navigate to `products` collection
- Find your product document
- Verify all fields are present: farmer_id, name, price, stock_quantity, etc.

### Step 4: Add More Products (Optional)
Repeat Step 2 to add more products across different categories:
- **Crop Inputs:** Fertilizers, Seeds, Pesticides, Tools
- **Poultry Inputs:** Feeds, Day-old Chicks, Vaccines, Supplements
- **Goat Inputs:** Feeds, Veterinary supplies
- **Cow Inputs:** Feeds, Veterinary supplies

---

## 🛒 Part 2: SHG Browses and Orders Products

### Step 1: SHG Login
1. Logout from PSA account (or use different browser/incognito)
2. Login with SHG credentials
3. Navigate to SHG Dashboard

### Step 2: Browse PSA Products
1. Click on **"Buy Inputs"** tab
2. View products organized by category:
   - **Crop** - Farming inputs (seeds, fertilizers, tools)
   - **Poultry** - Poultry farming inputs (feeds, chicks, vaccines)
   - **Goats** - Goat farming inputs (feeds, veterinary)
   - **Cows** - Cattle farming inputs (feeds, veterinary)
3. Switch between category tabs to see filtered products
4. ✅ All PSA products are visible in real-time

### Step 3: Add Products to Cart
1. Browse products in any category
2. For each product you want to order:
   - Click the product card
   - Or click **"Add to Cart"** button
3. Cart badge in top-right shows item count
4. Add multiple products from different PSAs (multi-seller support)

### Step 4: Review Cart
1. Click cart icon in top-right corner
2. Review all items in cart:
   - Product name and description
   - PSA seller name
   - Quantity and price
   - Total amount
3. Adjust quantities if needed:
   - Tap **+** to increase quantity
   - Tap **-** to decrease quantity
   - Tap trash icon to remove item
4. Cart total updates automatically

### Step 5: Checkout
1. Click **"Checkout"** button
2. Checkout modal appears with:
   - Payment method selection (Cash on Delivery / Mobile Money)
   - Delivery address input
   - Optional delivery notes
3. Fill in required information:
   ```
   Payment Method: Mobile Money (or Cash on Delivery)
   Delivery Address: Your farm/business address
   Delivery Notes: Any special instructions (optional)
   ```
4. Review order summary with total amount
5. Click **"Place Order"** button
6. ✅ Success dialog appears
7. Orders are created (one per PSA seller)
8. Cart is cleared automatically
9. Navigate to "My Purchases" to track orders

### Step 6: Track Your Orders
1. From success dialog, click **"View My Purchases"**
2. Or navigate to **"My Purchases"** from dashboard
3. See all your orders with:
   - Order ID and date
   - PSA seller name and contact
   - Order items and total amount
   - Current order status
   - Payment method and delivery address
4. ✅ Orders appear with "Pending" status

---

## 📦 Part 3: PSA Manages Orders

### Step 1: PSA Views Orders
1. Logout from SHG account
2. Login as PSA user
3. Navigate to **"Orders"** screen
4. ✅ New order(s) appear in **"Pending"** tab

### Step 2: Accept/Reject Order
1. Review order details:
   - Buyer name and contact
   - Order items and quantities
   - Total amount
   - Delivery address
   - Payment method
2. Decision options:
   - **Accept Order:** Click green checkmark button
   - **Reject Order:** Click red X button (provide reason)

### Step 3: Update Order Status (If Accepted)
1. After accepting, order moves to **"Active"** tab
2. Update status as you fulfill the order:
   - **Pending** → **Confirmed** (order accepted)
   - **Confirmed** → **Preparing** (preparing items)
   - **Preparing** → **Ready** (ready for pickup/delivery)
   - **Ready** → **In Transit** (out for delivery)
   - **In Transit** → **Delivered** (delivered to buyer)
   - **Delivered** → **Completed** (buyer confirmed receipt)

3. Click status update button for each order
4. Select next status from dropdown
5. ✅ Status updates in real-time

### Step 4: Contact Buyer (Optional)
1. In order details, find buyer contact information
2. Call or message buyer for:
   - Order confirmation
   - Delivery coordination
   - Payment collection
   - Issue resolution

---

## ✅ Part 4: SHG Confirms Receipt

### Step 1: Track Delivery
1. Login as SHG user
2. Go to **"My Purchases"**
3. Find your order
4. ✅ Order status updates in real-time:
   - Watch status change from Pending → Confirmed → Preparing → Ready → In Transit → Delivered

### Step 2: Confirm Receipt
1. When order status shows **"Delivered"**
2. Click **"Confirm Receipt"** button
3. Confirmation dialog appears:
   ```
   Did you receive your order?
   - All items delivered as ordered
   - Quality is satisfactory
   - Ready to mark as completed
   ```
4. Click **"Yes, Confirm"**
5. ✅ Receipt is generated

### Step 3: View/Share Receipt
1. Professional receipt appears with:
   - Order ID and dates
   - PSA seller information
   - Buyer (SHG) information
   - Itemized product list
   - Payment details
   - Delivery address
   - Order timeline
2. Receipt actions:
   - **Copy to Clipboard:** Copy receipt text
   - **Share Receipt:** Share via system share sheet
   - **Close:** Return to purchases list
3. Order status changes to **"Completed"**
4. Order moves to **"Completed"** tab

---

## 🔄 Complete Flow Diagram

```
PSA SIDE                          SHG SIDE
═══════                          ═══════

1. Login as PSA                  
2. Navigate to Products          
3. Click "Add Product"           
4. Fill product details          
5. Save to Firebase ✅           
                                 6. Login as SHG
                                 7. Navigate to "Buy Inputs"
                                 8. See PSA products ✅
                                 9. Add to cart
                                 10. Checkout
                                 11. Place order ✅
12. Receive order notification ✅
13. Accept order                 
14. Update status                15. Track order status ✅
15. Prepare items                
16. Mark as "In Transit"         
17. Deliver to SHG               
18. Mark as "Delivered"          
                                 19. Confirm receipt ✅
                                 20. Generate receipt
19. Order completed ✅           21. Order completed ✅
```

---

## 🧪 Quick Test Checklist

### PSA Product Creation
- [ ] PSA can login successfully
- [ ] "Add Product" button works
- [ ] Product form validates required fields
- [ ] Product saves to Firebase
- [ ] Success message appears
- [ ] Product appears in products list
- [ ] Product appears in correct category tab
- [ ] Product count increases in tab badge

### SHG Product Browsing
- [ ] SHG can login successfully
- [ ] "Buy Inputs" tab shows products
- [ ] Products are organized by category
- [ ] Category tabs filter correctly
- [ ] PSA products appear in real-time
- [ ] Product details are correct
- [ ] Add to cart works

### Shopping Cart
- [ ] Cart badge shows item count
- [ ] Cart displays all items
- [ ] Quantity adjustment works
- [ ] Remove from cart works
- [ ] Total amount calculates correctly
- [ ] Cart persists during session

### Checkout & Order
- [ ] Checkout modal opens
- [ ] Payment method selection works
- [ ] Delivery address input works
- [ ] Order placement succeeds
- [ ] Success dialog appears
- [ ] Cart clears after order
- [ ] Orders created in Firebase

### PSA Order Management
- [ ] PSA sees new orders
- [ ] Orders appear in "Pending" tab
- [ ] Accept/reject buttons work
- [ ] Status update dropdown works
- [ ] Status changes reflect in real-time
- [ ] Buyer contact info visible

### SHG Order Tracking
- [ ] Orders appear in "My Purchases"
- [ ] Order details are correct
- [ ] Status updates in real-time
- [ ] Confirm receipt button works
- [ ] Receipt generates correctly
- [ ] Receipt can be copied/shared

---

## 📊 Expected Results

After completing this flow, you should have:

1. ✅ **PSA products in Firestore** - All products saved with correct structure
2. ✅ **Products visible to SHG** - Real-time streaming via `streamPSAProducts()`
3. ✅ **Orders in Firestore** - One order per PSA seller
4. ✅ **Real-time status updates** - Both PSA and SHG see updates instantly
5. ✅ **Professional receipts** - Complete transaction records
6. ✅ **Stock management** - Stock quantities updated automatically
7. ✅ **Complete audit trail** - All transactions tracked in Firebase

---

## 🚨 Troubleshooting

### Product Not Appearing in SHG Buy Inputs
- **Check:** Is product `is_available` set to `true`?
- **Check:** Is PSA user role correctly set to `'psa'` in users collection?
- **Check:** Does product have valid `farmer_id` matching PSA user ID?

### Order Not Appearing for PSA
- **Check:** Is order `farmer_id` matching PSA user ID?
- **Check:** Is order status set correctly?
- **Check:** Is Firebase connection stable?

### Cart Not Working
- **Check:** Is CartProvider initialized in main.dart?
- **Check:** Are products added with correct structure?
- **Check:** Is cart state persisting?

### Receipt Not Generating
- **Check:** Is order status "Delivered"?
- **Check:** Has receipt already been confirmed?
- **Check:** Are all order fields present (items, buyer, seller info)?

---

## 🎉 Success Indicators

You'll know everything is working when:

1. ✅ PSA adds product → Product appears in list immediately
2. ✅ SHG opens Buy Inputs → PSA product visible
3. ✅ SHG adds to cart → Cart badge shows count
4. ✅ SHG places order → Order appears in My Purchases
5. ✅ PSA opens Orders → New order in Pending tab
6. ✅ PSA updates status → SHG sees update in real-time
7. ✅ PSA marks Delivered → SHG can confirm receipt
8. ✅ SHG confirms → Receipt generated with all details

**All 8 indicators = Complete functional PSA → SHG supply chain! 🎉**

---

## 📱 Live App URL

**Test the complete flow here:**
https://5060-i25ra390rl3tp6c83ufw7-de59bda9.sandbox.novita.ai

**Remember:**
- Use different browsers or incognito mode for PSA and SHG accounts
- Or logout between role switches
- All changes sync in real-time via Firestore

---

**✅ This completes the full PSA → SHG ordering and delivery flow!**
