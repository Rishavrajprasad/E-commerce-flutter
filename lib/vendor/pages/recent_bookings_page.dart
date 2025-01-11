import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/vendor_service.dart';

class RecentBookingsPage extends StatefulWidget {
  const RecentBookingsPage({super.key});

  @override
  State<RecentBookingsPage> createState() => _RecentBookingsPageState();
}

class _RecentBookingsPageState extends State<RecentBookingsPage> {
  String _statusFilter = 'all';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final VendorService _vendorService = VendorService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Recent Bookings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _statusFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Bookings')),
              const PopupMenuItem(value: 'confirmed', child: Text('Confirmed')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search bookings...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildBookingsStream(_vendorService),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print(snapshot.error);
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 60, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text('Something went wrong',
                              style: theme.textTheme.titleLarge),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final booking = doc.data() as Map;
                    final matchesStatus = _statusFilter == 'all' ||
                        booking['status'] == _statusFilter;
                    final matchesSearch = _searchController.text.isEmpty ||
                        doc.id
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase());
                    return matchesStatus && matchesSearch;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No bookings found',
                              style: theme.textTheme.titleLarge),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final booking = filteredDocs[index].data() as Map;
                      final bookingId = filteredDocs[index].id;
                      return _buildBookingCard(booking, bookingId, theme);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map booking, String bookingId, ThemeData theme) {
    final DateTime bookingDate =
        booking['orderDate']?.toDate() ?? DateTime.now();
    final String status = booking['status'] ?? 'pending';
    final Map orderSummary = booking['orderSummary'] ?? {};
    final Map paymentMethod = booking['paymentMethod'] ?? {};
    final Map shippingAddress = booking['shippingAddress'] ?? {};

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${bookingId.substring(0, 8)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(status, theme),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_month,
                      size: 20, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d, yyyy HH:mm').format(bookingDate),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Payment Details', theme),
                _buildDetailRow(
                    'Subtotal', '₹${orderSummary['subtotal']}', theme),
                _buildDetailRow(
                    'Shipping', '₹${orderSummary['shippingCharge']}', theme),
                _buildDetailRow('Tax', '₹${orderSummary['tax']}', theme),
                _buildDetailRow('Total', '₹${orderSummary['total']}', theme),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Payment Method',
                  '${paymentMethod['type']?.toString().split('.').last ?? 'N/A'} ${paymentMethod['cardEnding'] != null ? '(*${paymentMethod['cardEnding']})' : ''}',
                  theme,
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Shipping Address', theme),
                _buildAddressDetails(shippingAddress, theme),
                const SizedBox(height: 16),
                _buildSectionTitle('Customer Details', theme),
                _buildDetailRow(
                    'Name', shippingAddress['name'] ?? 'N/A', theme),
                _buildDetailRow(
                    'Phone', shippingAddress['phone'] ?? 'N/A', theme),
                if (status == 'pending') ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            _updateBookingStatus(bookingId, 'confirmed'),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Confirm Order',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _updateBookingStatus(bookingId, 'cancelled'),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text('Cancel Order',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildAddressDetails(Map address, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${address['streetAddress'] ?? ''}\n'
          '${address['city'] ?? ''}, ${address['state'] ?? ''}\n'
          '${address['postalCode'] ?? ''}',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _buildBookingsStream(VendorService vendorService) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('vendorId', isEqualTo: vendorService.currentVendorId)
        .orderBy('orderDate', descending: true)
        .snapshots();
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Text(value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(bookingId)
          .update({'status': newStatus});
    } catch (e) {
      // Handle error
    }
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color chipColor;
    Color textColor = Colors.white;

    switch (status.toLowerCase()) {
      case 'confirmed':
        chipColor = Colors.green;
        break;
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
