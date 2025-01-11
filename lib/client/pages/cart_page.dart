import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'checkout_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  // Updated color constants
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color accentColor = Color(0xFF8B8EFF);
  static const Color textDarkColor = Color(0xFF2D3142);
  static const Color textLightColor = Color(0xFF9DA3B4);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shopping Cart',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textDarkColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final cartItem = snapshot.data!.docs[index];
                    return _buildCartItem(cartItem, userId!, context);
                  },
                ),
              ),
              _buildCartSummary(snapshot.data!.docs, context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/parcel.png',
            height: 200,
          ),
          const SizedBox(height: 32),
          Text(
            'Your Cart is Empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: textDarkColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add items to start shopping',
            style: TextStyle(
              fontSize: 16,
              color: textLightColor,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Explore Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
      DocumentSnapshot cartItem, String userId, BuildContext context) {
    final data = cartItem.data() as Map<String, dynamic>;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(
                      data['imageUrl'] ?? 'https://picsum.photos/100'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Unknown Service',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 16, color: textLightColor),
                      const SizedBox(width: 4),
                      Text(
                        data['businessName'] ?? 'Unknown Vendor',
                        style: TextStyle(
                          fontSize: 14,
                          color: textLightColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        data['gender']?.toLowerCase() == 'female'
                            ? Icons.female
                            : Icons.male,
                        size: 16,
                        color: textLightColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['gender'] ?? 'Not specified',
                        style: TextStyle(
                          fontSize: 14,
                          color: textLightColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${data['price'] ?? '0'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: textLightColor),
              onPressed: () {
                final BuildContext currentContext = context;
                showDialog(
                  context: currentContext,
                  builder: (context) => AlertDialog(
                    title: Text('Remove Item'),
                    content: Text('Are you sure you want to remove this item?'),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: Text('Remove'),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('cart')
                              .doc(cartItem.id)
                              .delete();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(
      List<DocumentSnapshot> cartItems, BuildContext context) {
    // Get vendorId from the first cart item
    final vendorId = cartItems.isNotEmpty
        ? (cartItems.first.data() as Map<String, dynamic>)['vendorId'] ?? ''
        : '';

    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) =>
          sum + ((item.data() as Map<String, dynamic>)['price'] ?? 0),
    );

    // Added fixed charges (you can modify these values as needed)
    const shippingCharge = 49.0;
    const taxRate = 0.18; // 18% GST
    final tax = subtotal * taxRate;
    final total = subtotal + shippingCharge + tax;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 16,
                    color: textLightColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: textDarkColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Shipping Charges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shipping Charges',
                  style: TextStyle(
                    fontSize: 16,
                    color: textLightColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${shippingCharge.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: textDarkColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tax
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tax (18% GST)',
                  style: TextStyle(
                    fontSize: 16,
                    color: textLightColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${tax.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: textDarkColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            // Total Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    color: textLightColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutPage(
                      vendorId: vendorId,
                      subtotal: subtotal,
                      shippingCharge: shippingCharge,
                      tax: tax,
                      total: total,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
