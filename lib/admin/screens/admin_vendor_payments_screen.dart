import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminVendorPaymentsScreen extends StatelessWidget {
  const AdminVendorPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Payments'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('vendorPayment.status', isEqualTo: 'pending')
            .orderBy('vendorPayment.dueDate')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final vendorPayment =
                  data['vendorPayment'] as Map<String, dynamic>;
              final dueDate = (vendorPayment['dueDate'] as Timestamp).toDate();

              return ListTile(
                title: Text('Order #${doc.id.substring(0, 8)}'),
                subtitle: Text(
                  'Due: ${DateFormat('MMM d, yyyy').format(dueDate)}\n'
                  'Amount: ₹${vendorPayment['amount'].toStringAsFixed(2)}',
                ),
                trailing: ElevatedButton(
                  onPressed: () => _markAsPaid(doc.id),
                  child: const Text('Mark as Paid'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAsPaid(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'vendorPayment.status': 'completed',
        'vendorPayment.paidDate': FieldValue.serverTimestamp(),
        'vendorPayment.transactionId':
            'MANUAL-${DateTime.now().millisecondsSinceEpoch}',
      });
    } catch (e) {
      print('Error marking payment as paid: $e');
    }
  }
}
