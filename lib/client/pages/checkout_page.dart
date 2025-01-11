import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutPage extends StatefulWidget {
  final String vendorId;
  final double subtotal;
  final double shippingCharge;
  final double tax;
  final double total;

  const CheckoutPage({
    super.key,
    required this.vendorId,
    required this.subtotal,
    required this.shippingCharge,
    required this.tax,
    required this.total,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Address? selectedAddress;
  PaymentMethod? selectedPaymentMethod;

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F9FB);
  static const Color textDarkColor = Color(0xFF2D3142);
  static const Color textLightColor = Color(0xFF9DA3B4);
  static const Color cardColor = Colors.white;

  void _handleAddressSelection() async {
    final result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddressBottomSheet(),
    );

    if (result != null) {
      setState(() => selectedAddress = result);
    }
  }

  void _handlePaymentMethodSelection() async {
    final result = await showModalBottomSheet<PaymentMethod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaymentMethodBottomSheet(),
    );

    if (result != null) {
      setState(() => selectedPaymentMethod = result);
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

  void _handlePlaceOrder() async {
    if (selectedAddress == null || selectedPaymentMethod == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create order data
      final order = {
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'vendorId': widget.vendorId,
        'status': 'pending',
        'orderDate': FieldValue.serverTimestamp(),
        'shippingAddress': {
          'name': selectedAddress!.name,
          'streetAddress': selectedAddress!.streetAddress,
          'city': selectedAddress!.city,
          'state': selectedAddress!.state,
          'postalCode': selectedAddress!.postalCode,
          'phone': selectedAddress!.phone,
        },
        'paymentMethod': {
          'type': selectedPaymentMethod!.type.toString(),
          'cardEnding': selectedPaymentMethod!.cardNumber
              .substring(selectedPaymentMethod!.cardNumber.length - 4),
        },
        'orderSummary': {
          'subtotal': widget.subtotal,
          'shippingCharge': widget.shippingCharge,
          'tax': widget.tax,
          'total': widget.total,
        }
      };

      // Add order to Firebase
      await FirebaseFirestore.instance.collection('orders').add(order);

      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order Placed Successfully'),
          content: const Text(
              'Your order has been placed and will be delivered soon.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Return to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: ${e.toString()}')),
      );
    }
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

  String get detailedAddress => '$streetAddress, $city, $state $postalCode';

  @override
  String toString() => name;
}

class PaymentMethod {
  final String id;
  final String cardNumber;
  final String cardHolderName;
  final String expiryDate;
  final PaymentType type;

  PaymentMethod({
    required this.id,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryDate,
    required this.type,
  });

  String get description =>
      'Card ending in ${cardNumber.substring(cardNumber.length - 4)}';

  @override
  String toString() =>
      type == PaymentType.creditCard ? 'Credit Card' : 'Debit Card';
}

enum PaymentType { creditCard, debitCard }

class AddressBottomSheet extends StatelessWidget {
  const AddressBottomSheet({super.key});

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
              'Select Address',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildAddressItem(
                  context,
                  Address(
                    id: '1',
                    name: 'Home',
                    streetAddress: '123 Main St',
                    city: 'Mumbai',
                    state: 'Maharashtra',
                    postalCode: '400001',
                    phone: '+91 9876543210',
                  ),
                ),
                _buildAddressItem(
                  context,
                  Address(
                    id: '2',
                    name: 'Office',
                    streetAddress: '456 Work Ave',
                    city: 'Mumbai',
                    state: 'Maharashtra',
                    postalCode: '400002',
                    phone: '+91 9876543211',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressItem(BuildContext context, Address address) {
    return ListTile(
      title: Text(address.name),
      subtitle: Text(address.detailedAddress),
      onTap: () => Navigator.pop(context, address),
    );
  }
}

class PaymentMethodBottomSheet extends StatelessWidget {
  const PaymentMethodBottomSheet({super.key});

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
              'Select Payment Method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildPaymentMethodItem(
                  context,
                  PaymentMethod(
                    id: '1',
                    cardNumber: '4111111111111111',
                    cardHolderName: 'John Doe',
                    expiryDate: '12/25',
                    type: PaymentType.creditCard,
                  ),
                ),
                _buildPaymentMethodItem(
                  context,
                  PaymentMethod(
                    id: '2',
                    cardNumber: '5555555555554444',
                    cardHolderName: 'John Doe',
                    expiryDate: '10/24',
                    type: PaymentType.debitCard,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(
      BuildContext context, PaymentMethod paymentMethod) {
    return ListTile(
      leading: Icon(
        paymentMethod.type == PaymentType.creditCard
            ? Icons.credit_card
            : Icons.credit_card_outlined,
      ),
      title: Text(paymentMethod.toString()),
      subtitle: Text(paymentMethod.description),
      onTap: () => Navigator.pop(context, paymentMethod),
    );
  }
}
