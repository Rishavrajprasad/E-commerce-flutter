import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'service_detail_page.dart';

class CategoryDetailPage extends StatefulWidget {
  final String categoryName;

  static const Color primaryPurple = Color(0xFF6B4EE8);
  static const Color backgroundColor = Color(0xFFF6F4FF);
  static const Color textDark = Color(0xFF2D2942);
  static const Color textLight = Color(0xFF6E6B7B);
  static const Color accentBlue = Color(0xFF4A90E2);

  const CategoryDetailPage({
    super.key,
    required this.categoryName,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredServices = [];
  List<Map<String, dynamic>> _allServices = [];

  void _filterServices(String query) {
    setState(() {
      _filteredServices = _allServices.where((service) {
        final serviceData = service['service'].data() as Map<String, dynamic>;
        return serviceData['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            service['businessName']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchServicesByCategory() async {
    List<Map<String, dynamic>> services = [];

    final vendorsSnapshot =
        await FirebaseFirestore.instance.collection('vendors').get();

    for (var vendorDoc in vendorsSnapshot.docs) {
      final vendorData = vendorDoc.data();
      final businessName = vendorData['businessName'] ?? 'Unknown Salon';
      final address = vendorData['fullAddress'] ?? 'Address not available';

      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorDoc.id)
          .collection('services')
          .where('category', isEqualTo: widget.categoryName)
          .get();

      for (var serviceDoc in servicesSnapshot.docs) {
        services.add({
          'service': serviceDoc,
          'businessName': businessName,
          'vendorId': vendorDoc.id,
          'address': address,
          'phone': vendorData['phone'] ?? 'Phone not available',
          'email': vendorData['email'] ?? 'Email not available',
        });
      }
    }

    return services;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CategoryDetailPage.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: CategoryDetailPage.textDark,
            fontSize: 24,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: CategoryDetailPage.primaryPurple, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterServices,
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchServicesByCategory(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData) {
                  _allServices = snapshot.data ?? [];
                  final services = _searchController.text.isEmpty
                      ? _allServices
                      : _filteredServices;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      return ServiceCard(serviceData: services[index]);
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> serviceData;

  const ServiceCard({
    super.key,
    required this.serviceData,
  });

  @override
  Widget build(BuildContext context) {
    final service = serviceData['service'].data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CategoryDetailPage.primaryPurple.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceData['businessName'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: CategoryDetailPage.accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service['name'] ?? 'Unnamed Service',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CategoryDetailPage.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: CategoryDetailPage.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    service['gender'] ?? 'All',
                    style: const TextStyle(
                      color: CategoryDetailPage.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${service['rating'] ?? '4.5'} (${service['reviews'] ?? '0'})',
                  style: const TextStyle(
                    color: CategoryDetailPage.textLight,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.schedule,
                  color: CategoryDetailPage.textLight,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${service['duration'] ?? '30'} min',
                  style: const TextStyle(
                    color: CategoryDetailPage.textLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${service['price'] ?? '0'}',
                  style: const TextStyle(
                    color: CategoryDetailPage.primaryPurple,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailPage(
                          service: serviceData['service'],
                          businessName: serviceData['businessName'],
                          vendorId: serviceData['vendorId'],
                          address:
                              serviceData['address'] ?? 'Address not available',
                          phone: serviceData['phone'] ?? 'Phone not available',
                          email: serviceData['email'] ?? 'Email not available',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CategoryDetailPage.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Book Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
