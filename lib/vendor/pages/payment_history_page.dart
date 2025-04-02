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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Payment History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: vendorService.getPayments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return _buildEmptyState(context);
                }

                if (snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(context);
                }

                return _buildPaymentsList(context, snapshot);
              },
            ),
          ),
          _buildPaymentSummary(context, vendorService),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(
      BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    final validPayments = snapshot.data!.docs.where((doc) {
      final payment = doc.data() as Map;
      return payment['status']?.toLowerCase() != 'cancelled';
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      itemCount: validPayments.length,
      itemBuilder: (context, index) {
        final payment = validPayments[index].data() as Map;
        final DateTime orderDate = payment['orderDate'].toDate();
        final shippingAddress = payment['shippingAddress'] as Map? ?? {};
        final paymentMethod = payment['paymentMethod'] as Map? ?? {};
        final orderSummary = payment['orderSummary'] as Map? ?? {};

        // Update this section to check vendorPayment status
        final vendorPayment = payment['vendorPayment'] as Map?;
        final isPaid =
            vendorPayment != null && vendorPayment['status'] == 'completed';
        final paidDate = vendorPayment?['paidDate']?.toDate();

        // Calculate payment date only if not paid
        final DateTime paymentDate =
            isPaid ? paidDate! : _calculatePaymentDate(orderDate);

        // Calculate vendor's earnings (75% of total)
        final totalAmount = orderSummary['total'] ?? 0.0;
        final vendorEarnings = totalAmount * 0.75;

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
                                '₹${vendorEarnings.toStringAsFixed(2)}',
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
                                'Your Earnings (75%)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
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
                          _buildPaymentStatusChip(isPaid, paymentDate),
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

  DateTime _calculatePaymentDate(DateTime orderDate) {
    final day = orderDate.day;
    var paymentDate = orderDate;

    // If day is before 15th, payment on 15th
    // If day is after 15th, payment on 30th (or month end)
    if (day < 15) {
      paymentDate = DateTime(orderDate.year, orderDate.month, 15);
    } else {
      // Get the last day of the current month
      final lastDay = DateTime(orderDate.year, orderDate.month + 1, 0).day;
      paymentDate = DateTime(orderDate.year, orderDate.month, lastDay);
    }

    // If payment date is in the past, move to next payment cycle
    if (paymentDate.isBefore(DateTime.now())) {
      if (day < 15) {
        final lastDay = DateTime(orderDate.year, orderDate.month + 1, 0).day;
        paymentDate = DateTime(orderDate.year, orderDate.month, lastDay);
      } else {
        paymentDate = DateTime(orderDate.year, orderDate.month + 1, 15);
      }
    }

    return paymentDate;
  }

  Widget _buildPaymentStatusChip(bool isPaid, DateTime paymentDate) {
    if (isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
            const SizedBox(width: 6),
            Text(
              'Paid on ${DateFormat('MMM d').format(paymentDate)}',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 6),
            Text(
              'Due on ${DateFormat('MMM d').format(paymentDate)}',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
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

  Widget _buildPaymentSummary(
      BuildContext context, VendorService vendorService) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: vendorService.currentVendorId)
          .where('status',
              whereIn: ['confirmed', 'completed']) // Only count valid orders
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        double totalPending = 0;
        double totalCompleted = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final orderSummary = data['orderSummary'] as Map<String, dynamic>?;
          final vendorPayment = data['vendorPayment'] as Map<String, dynamic>?;

          if (orderSummary != null) {
            final totalAmount = orderSummary['total'] as num? ?? 0;
            final vendorShare =
                totalAmount * 0.75; // Calculate vendor's 75% share

            // Check vendorPayment status
            if (vendorPayment != null) {
              if (vendorPayment['status'] == 'completed') {
                totalCompleted += vendorShare;
              } else {
                // Add to pending if payment is not completed
                totalPending += vendorShare;
              }
            } else {
              // If vendorPayment doesn't exist, consider it pending
              totalPending += vendorShare;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Payments',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${totalPending.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[200],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Completed Payments',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${totalCompleted.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
