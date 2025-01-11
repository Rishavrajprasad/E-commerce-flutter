import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/client/pages/profile/profile_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth/login.dart';
import 'categories_page.dart';
import 'category_detail_page.dart';
import 'orders_page.dart';
import 'service_detail_page.dart';
import 'cart_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Cart tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CartPage(),
        ),
      );
      return;
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OrdersPage(),
        ),
      );
      return;
    }
    if (index == 3) {
      print('Profile Page');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      // Sign out from Google
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to login page after signing out
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Login()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signout Successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTopServices() async {
    List<Map<String, dynamic>> topServices = [];

    // Get all vendors
    final vendorsSnapshot =
        await FirebaseFirestore.instance.collection('vendors').get();

    // For each vendor
    for (var vendorDoc in vendorsSnapshot.docs) {
      final vendorData = vendorDoc.data();
      final businessName = vendorData['businessName'] ?? 'Unknown Salon';

      // Get services for this vendor
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorDoc.id)
          .collection('services')
          .limit(3) // Limit to 3 services per vendor
          .get();

      // Add each service with its vendor's business name
      for (var serviceDoc in servicesSnapshot.docs) {
        topServices.add({
          'service': serviceDoc,
          'businessName': businessName,
        });
      }
    }

    // Limit the total number of services if needed
    if (topServices.length > 6) {
      topServices = topServices.sublist(0, 6);
    }

    return topServices;
  }

  Future<List<Map<String, dynamic>>> _fetchServicesByCategory(
      String categoryName) async {
    List<Map<String, dynamic>> services = [];

    // Get all vendors
    final vendorsSnapshot =
        await FirebaseFirestore.instance.collection('vendors').get();

    // For each vendor
    for (var vendorDoc in vendorsSnapshot.docs) {
      final vendorData = vendorDoc.data();
      final businessName = vendorData['businessName'] ?? 'Unknown Salon';

      // Get services for this vendor that match the category
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorDoc.id)
          .collection('services')
          .where('category', isEqualTo: categoryName)
          .limit(5)
          .get();

      // Add matching services with vendor info
      for (var serviceDoc in servicesSnapshot.docs) {
        services.add({
          'service': serviceDoc,
          'businessName': businessName,
          'vendorId': vendorDoc.id,
        });
      }
    }

    return services;
  }

  Widget _buildCategoriesAndServices() {
    final categories = [
      'Haircare',
      'Skincare',
      'Makeup',
      'Pedicure',
      'Home Service',
      // Add more categories as needed
    ];

    return Column(
      children: categories.map((category) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              category,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CategoryDetailPage(categoryName: category),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchServicesByCategory(category),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final services = snapshot.data ?? [];
                  if (services.isEmpty) {
                    return const Center(
                        child: Text('No services in this category'));
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final serviceData = services[index];
                      return _buildServiceCard(
                        serviceData['service'],
                        serviceData['businessName'],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCartIcon() {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF8E6CEF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.shopping_cart, color: Color(0xFF8E6CEF)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartPage()),
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('cart')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            int itemCount = snapshot.data?.docs.length ?? 0;
            if (itemCount == 0) return const SizedBox();

            return Positioned(
              right: 4,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  itemCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Amirat',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          _buildCartIcon(),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF8E6CEF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFF8E6CEF)),
              onPressed: () => _signOut(context),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories Section Header
                  _buildSectionHeader('Categories', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoriesPage(),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Categories List
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryItem('Haircare', Icons.cut),
                        _buildCategoryItem('Skincare', Icons.face),
                        _buildCategoryItem('Makeup', Icons.brush),
                        _buildCategoryItem('Pedicure', Icons.spa),
                        _buildCategoryItem('Home Service', Icons.hot_tub),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Top Selling Section
                  _buildSectionHeader('Top Selling', () {
                    // Navigate to all top selling
                  }),
                  const SizedBox(height: 16),

                  // Top Selling List
                  SizedBox(
                    height: 220,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchTopServices(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Something went wrong');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final services = snapshot.data ?? [];
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final serviceData = services[index];
                            return _buildServiceCard(
                              serviceData['service'],
                              serviceData['businessName'],
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Categories and Services Section
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildCategoriesAndServices(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: const Color(0xFF4A90E2),
              unselectedItemColor: const Color(0xFFADB5BD),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Cart',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: MediaQuery.of(context).size.width * 0.63,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('cart')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  int itemCount = snapshot.data?.docs.length ?? 0;
                  if (itemCount == 0) return const SizedBox();

                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            'See All',
            style: TextStyle(
              color: Color(0xFF8E6CEF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailPage(categoryName: title),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 32,
                color: const Color(0xFF8E6CEF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E1E1E),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(DocumentSnapshot service, String businessName) {
    final serviceData = service.data() as Map<String, dynamic>;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailPage(
              service: service,
              businessName: businessName,
              vendorId: service.reference.parent.parent!.id,
            ),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF8E6CEF).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.spa,
                  size: 40,
                  color: const Color(0xFF8E6CEF),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceData['name'] ?? 'Unnamed Service',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF2A2B3D),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    businessName,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF4A90E2).withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${serviceData['price'] ?? '0'}',
                        style: const TextStyle(
                          color: Color(0xFF2A2B3D),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E6CEF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
