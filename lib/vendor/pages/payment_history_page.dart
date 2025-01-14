import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/vendor_service.dart';
import 'package:intl/intl.dart';

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final VendorService vendorService = VendorService();

    final theme = Theme.of(context);
    // Create a new payment collection reference
    final CollectionReference paymentsCollection = FirebaseFirestore.instance
        .collection('vendors')
        .doc(vendorService.currentVendorId)
        .collection('payments');

    // Execute the migration immediately when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Starting migration...');
      vendorService.getPayments().listen((QuerySnapshot snapshot) {
        print('Got ${snapshot.docs.length} payments to migrate');

        for (var doc in snapshot.docs) {
          final paymentData = doc.data() as Map<String, dynamic>;
          print('Processing payment: ${doc.id}');
          print('Payment data: $paymentData');

          // Add vendor ID to payment data
          paymentData['vendorId'] = vendorService.currentVendorId;

          // Store in payments collection with same document ID
          paymentsCollection
              .doc(doc.id)
              .set(paymentData, SetOptions(merge: true))
              .then((_) {
            print('Payment migrated successfully: ${doc.id}');
          }).catchError((error) {
            print('Error migrating payment ${doc.id}: $error');
          });
        }
      }, onError: (error) {
        print('Error in stream: $error');
      });
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Payment History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: vendorService.getPayments(),
        builder: (context, snapshot) {
          print('Connection State: ${snapshot.connectionState}');
          print('Has Data: ${snapshot.hasData}');
          print('Has Error: ${snapshot.hasError}');
          if (snapshot.hasData) {
            print('Number of docs: ${snapshot.data!.docs.length}');
          }

          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return _buildErrorState();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildPaymentsList(context, snapshot);
        },
      ),
    );
  }

  Widget _buildPaymentsList(
      BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    // Filter out cancelled orders
    final validPayments = snapshot.data!.docs.where((doc) {
      final payment = doc.data() as Map;
      return payment['status']?.toLowerCase() != 'cancelled';
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      itemCount: validPayments.length, // Use filtered list length
      itemBuilder: (context, index) {
        final payment = validPayments[index].data() as Map;
        final DateTime orderDate = payment['orderDate'].toDate();
        final shippingAddress = payment['shippingAddress'] as Map? ?? {};
        final paymentMethod = payment['paymentMethod'] as Map? ?? {};
        final orderSummary = payment['orderSummary'] as Map? ?? {};

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Show payment details modal
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${orderSummary['total']?.toStringAsFixed(2) ?? '0.00'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${paymentMethod['type']?.toString().split('.').last ?? 'N/A'} ${paymentMethod['cardEnding'] != null ? '(*${paymentMethod['cardEnding']})' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                          _buildStatusChip(payment['status']),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildInfoItem(
                            context,
                            Icons.person,
                            shippingAddress['name'],
                          ),
                          const SizedBox(width: 24),
                          _buildInfoItem(
                            context,
                            Icons.access_time,
                            DateFormat('MMM dd, yyyy hh:mm a')
                                .format(orderDate),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusConfig.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusConfig.icon,
            size: 16,
            color: statusConfig.color,
          ),
          const SizedBox(width: 6),
          Text(
            status.toLowerCase().capitalize(),
            style: TextStyle(
              color: statusConfig.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return StatusConfig(
          color: Colors.green[700]!,
          icon: Icons.check_circle,
        );
      case 'pending':
        return StatusConfig(
          color: Colors.orange[700]!,
          icon: Icons.pending,
        );
      case 'failed':
        return StatusConfig(
          color: Colors.red[700]!,
          icon: Icons.error,
        );
      case 'cancelled':
        return StatusConfig(
          color: Colors.grey[700]!,
          icon: Icons.cancel,
        );
      default:
        return StatusConfig(
          color: Colors.grey[700]!,
          icon: Icons.help,
        );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No payments yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please try again later',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusConfig {
  final Color color;
  final IconData icon;

  StatusConfig({required this.color, required this.icon});
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
