# 🚀 Phase 5: Marketplace Flow Improvements

## ✅ Completed Changes (Backend Services)

### 1. ✅ Delivery Confirmation & Stock Reduction
**Status:** Backend implementation complete

**What Was Added:**
- **Order Model Updates:**
  - Added `receivedAt` field (DateTime?) - When buyer confirms receipt
  - Added `isReceivedByBuyer` field (bool) - Buyer confirmation flag
  
- **OrderService New Methods:**
  ```dart
  Future<void> confirmReceipt(String orderId)
  ```
  - Marks order as completed
  - Sets `isReceivedByBuyer = true`
  - Records `received_at` timestamp
  - **Automatically reduces stock** for all products in order
  - Updates product `is_available` flag if stock reaches 0

- **ProductService New Methods:**
  ```dart
  Future<void> reduceStock(String productId, int quantity)
  Future<Product?> getProductWithStock(String productId)
  ```

**How It Works:**
1. Farmer marks order as "Delivered" → `deliveredAt` timestamp set
2. SME/Buyer sees order in "Delivered" status
3. SME clicks "Confirm Receipt" button
4. System:
   - Changes order status to "Completed"
   - Sets `isReceivedByBuyer = true`
   - Records `receivedAt` timestamp
   - **Reduces stock** for each product in the order
   - Marks products as unavailable if stock = 0

---

### 2. ✅ Order Status Redefinition
**Status:** Backend implementation complete

**New Order Status Meanings:**
- **Completed Orders**: Orders where buyer confirmed receipt (`isReceivedByBuyer = true`)
- **Active Orders**: Orders not yet received (pending, confirmed, preparing, ready, in_transit, delivered but not confirmed)
- **Recent Orders**: Completed orders with `receivedAt` within last 24 hours

**OrderService New Methods:**
```dart
// SME/Buyer statistics
Future<double> getBuyerMonthlySpending(String buyerId)    // Current month spending
Future<int> getBuyerCompletedOrdersCount(String buyerId)  // Received orders count
Future<int> getBuyerActiveOrdersCount(String buyerId)     // Not yet received count
Future<List<Order>> getBuyerRecentOrders(String buyerId)  // Last 24 hours completed
```

---

## 🔄 In Progress

### 3. 🔄 SME Dashboard Real Statistics
**Status:** Backend methods ready, UI update needed

**What Needs to Be Done:**
Update `lib/screens/sme/sme_dashboard_screen.dart` to use real Firestore data:

**Before (Mock Data):**
```dart
final _stats = {
  'monthSpending': 'UGX 850,000',
  'completedOrders': '12',
  'activeOrders': '3',
};
```

**After (Real Data):**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadRealStatistics();
  });
}

Future<void> _loadRealStatistics() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final userId = authProvider.currentUser?.id;
  
  if (userId == null) return;
  
  final orderService = OrderService();
  
  final monthSpending = await orderService.getBuyerMonthlySpending(userId);
  final completedCount = await orderService.getBuyerCompletedOrdersCount(userId);
  final activeCount = await orderService.getBuyerActiveOrdersCount(userId);
  
  setState(() {
    _stats = {
      'monthSpending': 'UGX ${monthSpending.toStringAsFixed(0)}',
      'completedOrders': completedCount.toString(),
      'activeOrders': activeCount.toString(),
    };
    _isLoading = false;
  });
}
```

**Files to Update:**
- `lib/screens/sme/sme_dashboard_screen.dart` - Replace mock stats with real data

---

## ⏳ Pending Implementation

### 4. ⏳ Distance-Based Product Sorting
**Status:** Model ready, implementation needed

**Available Resources:**
- `Location.distanceTo(Location other)` - Haversine formula distance calculation
- `Location.distanceTextTo(Location other)` - Formatted distance string
- User location stored in `AppUser.location` field
- GPS coordinates: `latitude` and `longitude` available

**What Needs to Be Done:**
1. **Update Product Browse Screen** (`lib/screens/sme/sme_browse_products_screen.dart`):
   - Get current user's location from `AuthProvider`
   - Fetch farmer details for each product
   - Calculate distance from buyer to each farmer
   - Sort products by distance (nearest first)
   - Display distance in product card

**Implementation Steps:**
```dart
// 1. Create ProductWithFarmer list
List<ProductWithFarmer> productsWithFarmers = [];

for (final product in products) {
  // Get farmer details
  final farmerDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(product.farmId)
      .get();
  
  if (farmerDoc.exists) {
    final farmer = AppUser.fromFirestore(farmerDoc.data()!, farmerDoc.id);
    
    // Calculate distance
    double? distance;
    if (currentUser.location != null && farmer.location != null) {
      distance = currentUser.location!.distanceTo(farmer.location!);
    }
    
    productsWithFarmers.add(ProductWithFarmer(
      product: product,
      farmer: farmer,
      distanceKm: distance,
    ));
  }
}

// 2. Sort by distance
productsWithFarmers.sort((a, b) {
  if (a.distanceKm == null) return 1;
  if (b.distanceKm == null) return -1;
  return a.distanceKm!.compareTo(b.distanceKm!);
});

// 3. Display with distance badge
ListTile(
  title: Text(productWithFarmer.product.name),
  subtitle: Text('${productWithFarmer.distanceText} • ${productWithFarmer.farmerDistrict}'),
  trailing: Chip(
    label: Text(productWithFarmer.distanceText),
    backgroundColor: productWithFarmer.isLocal ? Colors.green : Colors.orange,
  ),
);
```

**Files to Update:**
- `lib/screens/sme/sme_browse_products_screen.dart`

---

### 5. ⏳ Show SHG Details in Product Cards
**Status:** Model ready, UI update needed

**What to Display:**
- ✅ Farmer name (already shown)
- 📍 District location
- 📦 Current stock quantity
- 📞 Telephone number (click to call)
- 📏 Distance from buyer

**Implementation:**
Update product card in browse screen to show farmer details:

```dart
Card(
  child: Column(
    children: [
      // Product image
      Image.network(product.images.first),
      
      // Product name and price
      Text(product.name),
      Text('UGX ${product.price}/kg'),
      
      // NEW: Farmer details section
      Divider(),
      Row(
        children: [
          Icon(Icons.person, size: 16),
          Text(farmerName),
        ],
      ),
      Row(
        children: [
          Icon(Icons.location_on, size: 16),
          Text(farmerDistrict),
          Spacer(),
          Text(distanceText, style: TextStyle(color: Colors.green)),
        ],
      ),
      Row(
        children: [
          Icon(Icons.inventory, size: 16),
          Text('Stock: ${stockQuantity} kg'),
          Spacer(),
          IconButton(
            icon: Icon(Icons.phone),
            onPressed: () => _callFarmer(farmerPhone),
          ),
        ],
      ),
    ],
  ),
)
```

**Files to Update:**
- `lib/screens/sme/sme_browse_products_screen.dart`

---

### 6. ⏳ Delivery Confirmation UI (SME/Buyer Side)
**Status:** Backend ready, UI needed

**Where to Add:**
- `lib/screens/customer/order_tracking_screen.dart`
- Or create new screen: `lib/screens/customer/order_detail_screen.dart`

**What to Show:**
When order status is "Delivered":
```dart
if (order.status == OrderStatus.delivered && !order.isReceivedByBuyer) {
  ElevatedButton(
    onPressed: () => _confirmReceipt(order.id),
    child: Text('✅ Confirm Receipt'),
  );
}

Future<void> _confirmReceipt(String orderId) async {
  // Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm Receipt'),
      content: Text('Have you received this order in good condition?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Not Yet'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Yes, Received'),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    final orderService = OrderService();
    await orderService.confirmReceipt(orderId);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Order marked as received'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Generate receipt (see next task)
    _generateReceipt(orderId);
  }
}
```

**Files to Update:**
- `lib/screens/customer/order_tracking_screen.dart`

---

### 7. ⏳ Receipt Generation
**Status:** Not started

**What to Generate:**
A PDF or shareable text receipt with:
- Order number
- Date and time
- Farmer details
- Products list with quantities and prices
- Total amount
- Payment method
- Delivery address
- "Received by: [Buyer name]"
- "Received on: [DateTime]"

**Implementation Options:**

**Option 1: Text Receipt (Simple)**
```dart
String generateTextReceipt(Order order) {
  return '''
═══════════════════════════
   SAYEKATALE MARKETPLACE
        RECEIPT
═══════════════════════════

Order #${order.id.substring(0, 8)}
Date: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}

FARMER DETAILS:
Name: ${order.farmerName}
Phone: ${order.farmerPhone}

BUYER DETAILS:
Name: ${order.buyerName}
Phone: ${order.buyerPhone}

═══════════════════════════
ITEMS:
═══════════════════════════
${order.items.map((item) => '${item.productName}\n  ${item.quantity} ${item.unit} × UGX ${item.price}\n  Subtotal: UGX ${item.price * item.quantity}').join('\n\n')}

═══════════════════════════
TOTAL: UGX ${order.totalAmount.toStringAsFixed(0)}
Payment: ${order.paymentMethod.displayName}

Delivered: ${DateFormat('dd/MM/yyyy HH:mm').format(order.deliveredAt!)}
Received: ${DateFormat('dd/MM/yyyy HH:mm').format(order.receivedAt!)}

Received by: ${order.buyerName}

═══════════════════════════
  Thank you for your order!
═══════════════════════════
''';
}

// Share receipt
void _shareReceipt(String receipt) {
  Share.share(receipt, subject: 'Order Receipt');
}
```

**Option 2: PDF Receipt (Advanced)**
Use `pdf` package to generate professional PDF receipt.

**Files to Create:**
- `lib/services/receipt_service.dart`
- Add to `pubspec.yaml`: `share_plus: ^7.0.0` (for sharing)

---

### 8. ⏳ Favorites System
**Status:** Not started

**What to Implement:**
- **Favorite Farmers**: SME can "like" farmers who delivered products
- **Display**: Show favorites in a dedicated section
- **Filter**: Browse products from favorite farmers only

**Data Structure:**
New Firestore collection: `favorites`
```json
{
  "buyer_id": "SME-00001",
  "farmer_id": "SHG-00001",
  "farmer_name": "John Nama",
  "created_at": "2024-11-02T10:30:00Z",
  "orders_completed": 5,
  "total_spent": 125000
}
```

**UI Components:**
1. **Favorite Button**: In product card or order detail screen
2. **Favorites Tab**: In SME dashboard
3. **Filter Toggle**: "Show only favorites" in browse screen

**Implementation:**
```dart
// FavoritesService
class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> addFavorite(String buyerId, String farmerId, String farmerName) async {
    await _firestore.collection('favorites').add({
      'buyer_id': buyerId,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
  
  Future<void> removeFavorite(String buyerId, String farmerId) async {
    final docs = await _firestore
        .collection('favorites')
        .where('buyer_id', isEqualTo: buyerId)
        .where('farmer_id', isEqualTo: farmerId)
        .get();
    
    for (final doc in docs.docs) {
      await doc.reference.delete();
    }
  }
  
  Future<List<String>> getFavoriteFarmerIds(String buyerId) async {
    final docs = await _firestore
        .collection('favorites')
        .where('buyer_id', isEqualTo: buyerId)
        .get();
    
    return docs.docs.map((doc) => doc.data()['farmer_id'] as String).toList();
  }
  
  Stream<List<String>> streamFavoriteFarmerIds(String buyerId) {
    return _firestore
        .collection('favorites')
        .where('buyer_id', isEqualTo: buyerId)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => doc.data()['farmer_id'] as String).toList()
        );
  }
}
```

**Files to Create:**
- `lib/services/favorites_service.dart`
- `lib/screens/sme/sme_favorites_screen.dart`

---

## 📋 Implementation Priority

### High Priority (Complete First):
1. ✅ **Delivery confirmation & stock reduction** (DONE)
2. 🔄 **SME dashboard real statistics** (Backend done, UI needed)
3. ⏳ **Delivery confirmation UI** (Backend ready)
4. ⏳ **Receipt generation** (Simple text version first)

### Medium Priority (Complete After High):
5. ⏳ **Distance-based sorting** (Improves user experience)
6. ⏳ **Show SHG details** (Enhances product cards)

### Low Priority (Nice to Have):
7. ⏳ **Favorites system** (Additional feature)

---

## 🧪 Testing Plan

### Test Scenario 1: Complete Order Flow with Stock Reduction
1. **Login as Sarah (Buyer)**
   - Email: sarah.achieng@test.com
   - Password: password123

2. **Check Product Stock**
   - Go to Browse products
   - Find "Fresh Tomatoes" from John Nama
   - Note current stock (e.g., 100 kg)

3. **Place Order**
   - Add 10 kg to cart
   - Complete checkout
   - Place order

4. **Farmer Delivers** (Login as John)
   - Accept order
   - Mark as "Preparing"
   - Mark as "Ready"
   - Mark as "Delivered"

5. **Buyer Confirms Receipt** (Login as Sarah)
   - Go to Orders tab
   - Find delivered order
   - Click "Confirm Receipt"
   - Confirm in dialog

6. **Verify Stock Reduced**
   - Go back to Browse
   - Find "Fresh Tomatoes" again
   - **VERIFY**: Stock should be 90 kg (100 - 10)

### Test Scenario 2: Dashboard Statistics
1. **Login as Sarah**
2. **Complete 3 orders** in current month
   - Order 1: 25,000 UGX
   - Order 2: 30,000 UGX
   - Order 3: 45,000 UGX

3. **Check Dashboard**
   - **Month's Spending**: Should show 100,000 UGX
   - **Completed Orders**: Should show 3
   - **Active Orders**: Should show 0 (all confirmed)

---

## 📝 Summary

**✅ Completed (Backend):**
- Delivery confirmation flow
- Automatic stock reduction
- Order status redefinition
- SME statistics methods

**🔄 In Progress:**
- SME dashboard UI update

**⏳ Pending:**
- Distance-based sorting UI
- SHG details in product cards
- Delivery confirmation UI
- Receipt generation
- Favorites system

**Estimated Completion Time:**
- High Priority: 4-6 hours
- Medium Priority: 3-4 hours
- Low Priority: 2-3 hours
- **Total: 9-13 hours**

---

**Next Steps:**
1. Update SME dashboard to use real statistics
2. Add delivery confirmation button in order tracking
3. Implement receipt generation (text version)
4. Add distance calculation and sorting
5. Enhance product cards with farmer details
6. Implement favorites system
