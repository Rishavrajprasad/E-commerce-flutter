import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

final List<Color> vendorCardColors = [
  const Color(0xFFE3F2FD), // Light Blue
  const Color(0xFFF3E5F5), // Light Purple
  const Color(0xFFFBE9E7), // Light Deep Orange
  const Color(0xFFF1F8E9), // Light Green
  const Color(0xFFFFF3E0), // Light Orange
  const Color(0xFFE8EAF6), // Light Indigo
];

final List<Color> vendorIconColors = [
  Colors.blue[700]!,
  Colors.purple[700]!,
  Colors.deepOrange[700]!,
  Colors.green[700]!,
  Colors.orange[700]!,
  Colors.indigo[700]!,
];

class AdminVendorsScreen extends StatelessWidget {
  const AdminVendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors Management'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final vendor = snapshot.data!.docs[index];
              return VendorCard(vendor: vendor);
            },
          );
        },
      ),
    );
  }
}

class VendorCard extends StatelessWidget {
  final DocumentSnapshot vendor;

  const VendorCard({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vendorData = vendor.data() as Map<String, dynamic>;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showVendorDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    radius: 24,
                    child: Text(
                      vendorData['businessName']
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          '?',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendorData['businessName'] ?? 'Unknown Vendor',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Owner: ${vendorData['businessOwnerName'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${vendorData['city']}, ${vendorData['state']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              vendorData['phone'] ?? 'N/A',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildQuickStats(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: vendor.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ));
        }

        final orders = snapshot.data!.docs;
        final completedOrders =
            orders.where((o) => o['status'] == 'completed').length;
        final totalEarnings = orders.fold<double>(
          0,
          // ignore: avoid_types_as_parameter_names
          (sum, order) {
            final orderData = order.data() as Map<String, dynamic>;
            final orderSummary =
                orderData['orderSummary'] as Map<String, dynamic>?;
            return sum + (orderSummary?['total'] as num? ?? 0);
          },
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              context,
              'Orders',
              orders.length.toString(),
              Icons.shopping_bag_outlined,
            ),
            _buildStatItem(
              context,
              'Completed',
              completedOrders.toString(),
              Icons.check_circle_outline,
            ),
            _buildStatItem(
              context,
              'Earnings',
              '₹${totalEarnings.toStringAsFixed(2)}',
              Icons.currency_rupee,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 20, color: theme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showVendorDetails(BuildContext context) {
    final vendorData = vendor.data() as Map<String, dynamic>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24.0),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vendor Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailItem('Business Name', vendorData['businessName']),
              _buildDetailItem('Owner Name', vendorData['businessOwnerName']),
              _buildDetailItem('Email', vendorData['email']),
              _buildDetailItem('Phone', vendorData['phone']),
              _buildDetailItem('Full Address', vendorData['fullAddress']),
              _buildDetailItem('City', vendorData['city']),
              _buildDetailItem('State', vendorData['state']),
              _buildDetailItem('ZIP', vendorData['zip']),
              _buildDetailItem('Joined', _formatDate(vendorData['createdAt'])),
              const SizedBox(height: 24),
              _buildServicesSection(),
              const SizedBox(height: 24),
              _buildOrdersSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendor.id)
          .collection('services')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Services Offered',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Chip(label: Text('${snapshot.data!.docs.length}')),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrdersSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: vendor.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final orders = snapshot.data!.docs;
        final completedOrders =
            orders.where((o) => o['status'] == 'completed').length;
        final confirmedOrders =
            orders.where((o) => o['status'] == 'confirmed').length;
        final pendingOrders =
            orders.where((o) => o['status'] == 'pending').length;
        final cancelledOrders =
            orders.where((o) => o['status'] == 'cancelled').length;

        final totalEarnings = orders.fold<double>(
          0,
          (sum, order) {
            final orderData = order.data() as Map<String, dynamic>;
            final orderSummary =
                orderData['orderSummary'] as Map<String, dynamic>?;
            return sum + (orderSummary?['total'] as num? ?? 0);
          },
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Orders Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOrderStat('Total', orders.length, Colors.blue),
                _buildOrderStat('Completed', completedOrders, Colors.green),
                _buildOrderStat('Confirmed', confirmedOrders, Colors.orange),
                _buildOrderStat('Pending', pendingOrders, Colors.amber),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOrderStat('Cancelled', cancelledOrders, Colors.red),
                Text(
                  'Total Earnings: ₹${totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return DateFormat('MMM d, yyyy').format(date.toDate());
    }
    return 'N/A';
  }
}
