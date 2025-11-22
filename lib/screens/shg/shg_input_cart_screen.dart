import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart' as app_order;
import '../../utils/app_theme.dart';
import 'shg_my_purchases_screen.dart';

class SHGInputCartScreen extends StatefulWidget {
  const SHGInputCartScreen({super.key});

  @override
  State<SHGInputCartScreen> createState() => _SHGInputCartScreenState();
}

class _SHGInputCartScreenState extends State<SHGInputCartScreen> {
  final OrderService _orderService = OrderService();
  app_order.PaymentMethod _selectedPaymentMethod =
      app_order.PaymentMethod.mtnMobileMoney;
  final _deliveryAddressController = TextEditingController();
  final _deliveryNotesController = TextEditingController();
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _deliveryAddressController.dispose();
    _deliveryNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final cartItems = cartProvider.cartItems;

    // Calculate amounts (no service fees)
    final subtotal = cartProvider.subtotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Input Cart'), elevation: 0),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add farming inputs from PSA suppliers',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Browse Products'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.productImage,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'UGX ${NumberFormat('#,###').format(item.price)} per ${item.unit}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _QuantityControl(
                                      item: item,
                                      cartProvider: cartProvider,
                                    ),
                                  ],
                                ),
                              ),

                              // Price and Remove
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'UGX ${NumberFormat('#,###').format(item.price * item.quantity)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  IconButton(
                                    onPressed: () {
                                      cartProvider.removeItem(
                                        item.id,
                                      ); // ✅ Use cart item ID, not product ID
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Item removed from cart',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Checkout Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Total Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'UGX ${NumberFormat('#,###').format(subtotal)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Checkout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isPlacingOrder
                                ? null
                                : () => _showCheckoutDialog(
                                    authProvider,
                                    cartProvider,
                                  ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                            child: _isPlacingOrder
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Proceed to Checkout',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showCheckoutDialog(
    AuthProvider authProvider,
    CartProvider cartProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Checkout Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Payment Method
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                RadioGroup<app_order.PaymentMethod>(
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    }
                  },
                  child: Column(
                    children: [
                      _buildPaymentMethodOption(
                        app_order.PaymentMethod.mtnMobileMoney,
                        'MTN Mobile Money',
                        Icons.phone_android,
                      ),
                      _buildPaymentMethodOption(
                        app_order.PaymentMethod.cashOnDelivery,
                        'Cash on Delivery',
                        Icons.money,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Delivery Address
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _deliveryAddressController,
                  decoration: const InputDecoration(
                    hintText: 'Enter delivery address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Delivery Notes
                const Text(
                  'Delivery Notes (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _deliveryNotesController,
                  decoration: const InputDecoration(
                    hintText: 'Any special instructions',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _placeOrder(authProvider, cartProvider),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.successColor,
                    ),
                    child: const Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    app_order.PaymentMethod method,
    String label,
    IconData icon,
  ) {
    return RadioListTile<app_order.PaymentMethod>(
      value: method,
      title: Row(
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _placeOrder(
    AuthProvider authProvider,
    CartProvider cartProvider,
  ) async {
    final user = authProvider.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to place order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_deliveryAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    // Close checkout dialog
    Navigator.pop(context);

    try {
      // Place orders (groups by PSA seller)
      final orders = await _orderService.placeOrdersFromCart(
        buyerId: user.id,
        buyerName: user.name,
        buyerPhone: user.phone,
        cartItems: cartProvider.cartItems,
        paymentMethod: _selectedPaymentMethod,
        deliveryAddress: _deliveryAddressController.text.trim(),
        deliveryNotes: _deliveryNotesController.text.trim().isNotEmpty
            ? _deliveryNotesController.text.trim()
            : null,
      );

      // Clear cart
      await cartProvider.clear();

      setState(() {
        _isPlacingOrder = false;
      });

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${orders.length} order${orders.length > 1 ? 's' : ''} created',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'PSA suppliers will process your order soon',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to browse
              },
              child: const Text('Continue Shopping'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SHGMyPurchasesScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('View Orders'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isPlacingOrder = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _QuantityControl extends StatefulWidget {
  final dynamic item;
  final CartProvider cartProvider;

  const _QuantityControl({required this.item, required this.cartProvider});

  @override
  State<_QuantityControl> createState() => _QuantityControlState();
}

class _QuantityControlState extends State<_QuantityControl> {
  late TextEditingController _quantityController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
  }

  @override
  void didUpdateWidget(_QuantityControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.item.quantity != oldWidget.item.quantity) {
      _quantityController.text = widget.item.quantity.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantityFromTextField() {
    final newQuantity = int.tryParse(_quantityController.text);
    if (newQuantity != null && newQuantity > 0 && newQuantity <= 9999) {
      widget.cartProvider.updateQuantity(
        widget.item.id,
        newQuantity,
      ); // ✅ Use cart item ID
      setState(() {
        _isEditing = false;
      });
    } else {
      // Reset to current quantity if invalid
      setState(() {
        _quantityController.text = widget.item.quantity.toString();
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity (1-9999)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Decrease quantity
        IconButton(
          onPressed: widget.item.quantity > 1
              ? () {
                  widget.cartProvider.updateQuantity(
                    widget.item.id,
                    widget.item.quantity - 1,
                  ); // ✅ Use cart item ID
                }
              : null,
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        // Editable quantity input (tap to type large quantities)
        Tooltip(
          message: 'Tap to type quantity',
          child: InkWell(
            onTap: () {
              setState(() {
                _isEditing = true;
              });
            },
            child: Container(
              width: 70,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isEditing ? Colors.blue : Colors.grey.shade300,
                  width: _isEditing ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _isEditing ? Colors.blue.shade50 : Colors.grey.shade50,
              ),
              child: _isEditing
                  ? TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintText: '0',
                      ),
                      onSubmitted: (_) {
                        _updateQuantityFromTextField();
                      },
                      onEditingComplete: () {
                        _updateQuantityFromTextField();
                      },
                      onTapOutside: (_) {
                        _updateQuantityFromTextField();
                      },
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.item.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.edit_outlined,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
            ),
          ),
        ),
        // Increase quantity
        IconButton(
          onPressed: () {
            widget.cartProvider.updateQuantity(
              widget.item.id,
              widget.item.quantity + 1,
            ); // ✅ Use cart item ID
          },
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
