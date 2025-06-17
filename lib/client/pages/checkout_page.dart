import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'order_placed_successfully_page.dart';

class CheckoutPage extends StatefulWidget {
  final String vendorId;
  final double subtotal;
  final double shippingCharge;
  final double tax;
  final double total;
  final List<CartItem> cartItems;

  const CheckoutPage({
    super.key,
    required this.vendorId,
    required this.subtotal,
    required this.shippingCharge,
    required this.tax,
    required this.total,
    required this.cartItems,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<Address> userAddresses = [];
  Address? selectedAddress;
  PaymentMethod? selectedPaymentMethod;
  late Razorpay _razorpay;

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F9FB);
  static const Color textDarkColor = Color(0xFF2D3142);
  static const Color textLightColor = Color(0xFF9DA3B4);
  static const Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadUserAddresses();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _loadUserAddresses() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .get();

    setState(() {
      userAddresses = snapshot.docs
          .map((doc) => Address.fromMap(doc.id, doc.data()))
          .toList();

      // Set the first address as default if available
      if (userAddresses.isNotEmpty && selectedAddress == null) {
        selectedAddress = userAddresses[0];
      }
    });
  }

  void _handleAddressSelection() async {
    final result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressSelectionSheet(
        addresses: userAddresses,
        onAddNewAddress: () async {
          final newAddress = await showModalBottomSheet<Address>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddressInputSheet(),
          );

          if (newAddress != null) {
            await _saveAddress(newAddress);
            await _loadUserAddresses();
          }
        },
      ),
    );

    if (result != null) {
      setState(() => selectedAddress = result);
    }
  }

  Future<void> _saveAddress(Address address) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .add(address.toMap());
  }

  void _handlePaymentMethodSelection() async {
    setState(() {
      selectedPaymentMethod = PaymentMethod(
        id: 'online',
        type: PaymentType.online,
      );
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Verify payment with your backend (recommended)
      // await _verifyPayment(response.paymentId!);

      // Create and save order
      final orderRef = await _createOrder(
        paymentId: response.paymentId!,
        orderId: response.orderId,
        signature: response.signature,
      );

      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog

      // Navigate to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderPlacedSuccessfullyPage(
            orderId: orderRef.id,
          ),
        ),
      );
    } catch (e) {
      print('Error creating order: $e');
      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating order: ${e.toString()}')),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Payment failed: ${response.message ?? "Error occurred"}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
      ),
    );
  }

  Future<DocumentReference> _createOrder({
    required String paymentId,
    String? orderId,
    String? signature,
  }) async {
    final order = {
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'vendorId': widget.vendorId,
      'status': 'confirmed',
      'orderDate': FieldValue.serverTimestamp(),
      'payment': {
        'id': paymentId,
        'orderId': orderId,
        'signature': signature,
        'status': 'completed',
        'method': 'Razorpay',
        'amount': widget.total,
        'currency': 'INR',
        'timestamp': FieldValue.serverTimestamp(),
      },
      'vendorPayment': {
        'status': 'pending',
        'amount': widget.total * 0.75,
        'dueDate': _calculateNextPaymentDate(),
        'paidDate': null,
        'transactionId': null,
      },
      'shippingAddress': {
        'name': selectedAddress!.name,
        'streetAddress': selectedAddress!.streetAddress,
        'city': selectedAddress!.city,
        'state': selectedAddress!.state,
        'postalCode': selectedAddress!.postalCode,
        'phone': selectedAddress!.phone,
      },
      'paymentMethod': {
        'type': 'online',
        'method': 'Razorpay',
      },
      'orderSummary': {
        'subtotal': widget.subtotal,
        'shippingCharge': widget.shippingCharge,
        'tax': widget.tax,
        'total': widget.total,
      },
      'items': widget.cartItems
          .map((item) => {
                'productId': item.productId,
                'name': item.name,
                'price': item.price,
                'quantity': item.quantity,
                'image': item.imageUrl,
              })
          .toList(),
    };

    return await FirebaseFirestore.instance.collection('orders').add(order);
  }

  DateTime _calculateNextPaymentDate() {
    final now = DateTime.now();
    final day = now.day;

    if (day < 15) {
      return DateTime(now.year, now.month, 15);
    } else {
      // Get the last day of the current month
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      return DateTime(now.year, now.month, lastDay);
    }
  }

  void _handlePlaceOrder() async {
    if (selectedAddress == null || selectedPaymentMethod == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      var options = {
        'key': 'rzp_live_XEClMOVTq7bg8n',
        'amount': (widget.total * 100).toInt(),
        'name': 'Amirat- All in one saloon App',
        'description': 'Order Payment',
        'prefill': {
          'contact': selectedAddress?.phone,
          'email': FirebaseAuth.instance.currentUser?.email,
        },
        'theme': {
          'color': '#6C63FF',
        }
      };

      Navigator.pop(context); // Remove loading dialog
      _razorpay.open(options);
    } catch (e) {
      print('Error initiating payment: $e');
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initiating payment: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: textDarkColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textDarkColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                      'Shipping Address', Icons.location_on_outlined),
                  const SizedBox(height: 8),
                  _buildClickableContainer(
                    selectedAddress?.toString() ?? 'Add Shipping Address',
                    selectedAddress?.detailedAddress ??
                        'Enter your shipping details',
                    selectedAddress != null
                        ? Icons.location_on
                        : Icons.add_location_alt_outlined,
                    onTap: _handleAddressSelection,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Payment Method', Icons.payment_outlined),
                  const SizedBox(height: 8),
                  _buildClickableContainer(
                    selectedPaymentMethod?.toString() ?? 'Add Payment Method',
                    selectedPaymentMethod?.description ??
                        'Add your payment details',
                    selectedPaymentMethod != null
                        ? Icons.credit_card
                        : Icons.credit_card_outlined,
                    onTap: _handlePaymentMethodSelection,
                  ),
                ],
              ),
            ),
          ),

          // Order Summary Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 0,
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPriceRow('Subtotal', widget.subtotal),
                  const SizedBox(height: 12),
                  _buildPriceRow('Shipping Cost', widget.shippingCharge),
                  const SizedBox(height: 12),
                  _buildPriceRow('Tax', widget.tax),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                        color: Colors.grey.withOpacity(0.2), thickness: 1),
                  ),
                  _buildPriceRow('Total', widget.total, isTotal: true),
                  const SizedBox(height: 24),
                  _buildPlaceOrderButton(
                    onPressed: (selectedAddress != null &&
                            selectedPaymentMethod != null)
                        ? _handlePlaceOrder
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: textDarkColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildClickableContainer(String title, String subtitle, IconData icon,
      {required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textDarkColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textLightColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: textLightColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            color: isTotal ? textDarkColor : textLightColor,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 24 : 16,
            color: isTotal ? primaryColor : textDarkColor,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton({required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Place Order',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}

class Address {
  final String id;
  final String name;
  final String streetAddress;
  final String city;
  final String state;
  final String postalCode;
  final String phone;

  Address({
    required this.id,
    required this.name,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'streetAddress': streetAddress,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'phone': phone,
    };
  }

  static Address fromMap(String id, Map<String, dynamic> map) {
    return Address(
      id: id,
      name: map['name'] ?? '',
      streetAddress: map['streetAddress'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  String get detailedAddress => '$streetAddress, $city, $state $postalCode';

  @override
  String toString() => name;
}

class PaymentMethod {
  final String id;
  final PaymentType type;

  PaymentMethod({
    required this.id,
    required this.type,
  });

  String get description => 'Pay Online via Cards/UPI/Wallets';

  @override
  String toString() => 'Online Payment';
}

enum PaymentType { online }

class AddressInputSheet extends StatefulWidget {
  const AddressInputSheet({super.key});

  @override
  State<AddressInputSheet> createState() => _AddressInputSheetState();
}

class _AddressInputSheetState extends State<AddressInputSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Enter Shipping Address',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextFormField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                    ),
                    _buildTextFormField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                    ),
                    _buildTextFormField(
                      controller: _streetController,
                      label: 'Street Address',
                      icon: Icons.home,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _cityController,
                            label: 'City',
                            icon: Icons.location_city,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _stateController,
                            label: 'State',
                            icon: Icons.map,
                          ),
                        ),
                      ],
                    ),
                    _buildTextFormField(
                      controller: _postalCodeController,
                      label: 'Postal Code',
                      icon: Icons.local_post_office,
                    ),
                    const SizedBox(height: 30),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          if (label == 'Postal Code' && !RegExp(r'^\d{6}$').hasMatch(value)) {
            return 'Enter a valid 6-digit postal code';
          }
          if (label == 'Phone Number' && !RegExp(r'^\d{10}$').hasMatch(value)) {
            return 'Enter a valid 10-digit phone number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            Navigator.pop(
              context,
              Address(
                id: DateTime.now().toString(),
                name: _nameController.text,
                streetAddress: _streetController.text,
                city: _cityController.text,
                state: _stateController.text,
                postalCode: _postalCodeController.text,
                phone: _phoneController.text,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Save Address',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class AddressSelectionSheet extends StatelessWidget {
  final List<Address> addresses;
  final VoidCallback onAddNewAddress;

  const AddressSelectionSheet({
    super.key,
    required this.addresses,
    required this.onAddNewAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Shipping Address',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: addresses.length + 1,
              itemBuilder: (context, index) {
                if (index == addresses.length) {
                  return ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: const Text('Add New Address'),
                    onTap: () {
                      Navigator.pop(context);
                      onAddNewAddress();
                    },
                  );
                }

                final address = addresses[index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(address.name),
                  subtitle: Text(address.detailedAddress),
                  onTap: () => Navigator.pop(context, address),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CartItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });
}
