import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceDetailPage extends StatelessWidget {
  final DocumentSnapshot service;
  final String businessName;
  final String vendorId;
  final String address;
  final String phone;
  final String email;

  const ServiceDetailPage({
    super.key,
    required this.service,
    required this.businessName,
    required this.vendorId,
    required this.address,
    required this.phone,
    required this.email,
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'haircut':
        return Icons.content_cut;
      case 'massage':
        return Icons.spa;
      case 'facial':
        return Icons.face;
      case 'makeup':
        return Icons.brush;
      case 'nails':
        return Icons.clean_hands;
      default:
        return Icons.spa;
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceData = service.data() as Map<String, dynamic>;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Header with centered service icon
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(serviceData['category'] ?? 'other'),
                size: 120,
                color: theme.primaryColor,
              ),
            ),
          ),

          // Content
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Category Chip
                        Chip(
                          avatar: Icon(_getCategoryIcon(
                              serviceData['category'] ?? 'other')),
                          label: Text(serviceData['category'] ?? 'Service'),
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                        ),
                        const SizedBox(height: 16),

                        // Title and Business Name
                        Text(
                          serviceData['name'] ?? 'Unnamed Service',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.store,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              businessName,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                address,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Price and Duration
                        Row(
                          children: [
                            Text(
                              '₹${serviceData['price'] ?? '0'}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${serviceData['duration'] ?? '60'} mins',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description Section
                        _buildSection(
                          title: 'Description',
                          content: serviceData['description'] ??
                              'No description available',
                          theme: theme,
                        ),

                        // Business Owner Section
                        _buildSection(
                          title: 'Business Details',
                          content: 'Owner: $businessName\n'
                              'Contact: $phone\n'
                              'Email: $email',
                          theme: theme,
                        ),

                        // Reviews Section
                        _buildReviewsSection(theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _addToCart(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Book Now',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReviewsSection(ThemeData theme) {
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
