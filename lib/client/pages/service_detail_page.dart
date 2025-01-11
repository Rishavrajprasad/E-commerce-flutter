import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceDetailPage extends StatelessWidget {
  final DocumentSnapshot service;
  final String businessName;
  final String vendorId;

  const ServiceDetailPage({
    super.key,
    required this.service,
    required this.businessName,
    required this.vendorId,
  });

  Future<void> _addToCart(BuildContext context) async {
    try {
      final serviceData = service.data() as Map<String, dynamic>;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add items to cart')),
        );
        return;
      }

      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      // Check if item already exists in cart
      final existingItem = await cartRef
          .where('serviceId', isEqualTo: service.id)
          .limit(1)
          .get();

      if (existingItem.docs.isNotEmpty) {
        // Update quantity if item exists
        await cartRef.doc(existingItem.docs.first.id).update({
          'quantity': FieldValue.increment(1),
        });
      } else {
        // Add new item to cart with service and vendor details
        await cartRef.add({
          'serviceId': service.id,
          'name': serviceData['name'],
          'price': serviceData['price'],
          'imageUrl': serviceData['imageUrl'],
          'vendorId': vendorId,
          'businessName': businessName,
          'vendorName': serviceData['businessOwnerName'] ?? 'Unknown Vendor',
          'gender': serviceData['gender'] ?? 'Not specified',
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding to cart: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceData = service.data() as Map<String, dynamic>;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Service Image
                Image.network(
                  serviceData['imageUrl'] ?? 'https://placeholder.com/300x200',
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                ),
                // Back and Favorite buttons
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_border,
                              color: Colors.black),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceData['name'] ?? 'Unnamed Service',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${serviceData['price'] ?? '0'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    serviceData['description'] ?? 'No description available',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Shipping & Returns
                  const Text(
                    'Shipping & Returns',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Free standard shipping and free 60-day returns'),
                  const SizedBox(height: 24),

                  // Reviews
                  _buildReviewsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _addToCart(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E6CEF),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Add to Bag',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              '4.5',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Ratings'),
          ],
        ),
        const SizedBox(height: 16),
        // Add review items here
      ],
    );
  }
}
