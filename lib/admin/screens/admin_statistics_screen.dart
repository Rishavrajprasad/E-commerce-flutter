import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;

  int totalCompletedOrders = 0;
  int pendingOrders = 0;
  int totalVendors = 0;
  double totalRevenue = 0.0;
  Map<String, double> vendorRevenues = {};
  int totalCustomers = 0;
  double growthRate = 0.0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() => isLoading = true);
    try {
      final completedOrders = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .get();

      final pending = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .get();

      final vendors = await _firestore.collection('vendors').get();

      final customers = await _firestore.collection('users').get();

      double totalRev = 0;
      Map<String, double> vendorRev = {};

      // Get all vendors
      final vendorsSnapshot = await _firestore.collection('vendors').get();

      // Iterate through each vendor
      for (var vendor in vendorsSnapshot.docs) {
        double vendorTotal = 0;

        // Get all payments for this vendor
        final paymentsSnapshot = await _firestore
            .collection('vendors')
            .doc(vendor.id)
            .collection('payments')
            .get();

        // Sum up all payment totals for this vendor
        for (var payment in paymentsSnapshot.docs) {
          final orderSummary =
              payment.data()['orderSummary'] as Map<String, dynamic>?;
          final total = orderSummary?['total'] as num? ?? 0;
          vendorTotal += total;
        }

        vendorRev[vendor.id] = vendorTotal;
        totalRev += vendorTotal;
      }

      // Calculate month-over-month growth
      final lastMonthStart = DateTime.now().subtract(const Duration(days: 30));
      final thisMonthOrders = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThan: lastMonthStart)
          .get();

      final prevMonthStart = lastMonthStart.subtract(const Duration(days: 30));
      final lastMonthOrders = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThan: prevMonthStart)
          .where('createdAt', isLessThan: lastMonthStart)
          .get();

      final growth = thisMonthOrders.docs.length - lastMonthOrders.docs.length;
      growthRate = lastMonthOrders.docs.isEmpty
          ? 0
          : (growth / lastMonthOrders.docs.length) * 100;

      setState(() {
        totalCompletedOrders = completedOrders.docs.length;
        pendingOrders = pending.docs.length;
        totalVendors = vendors.docs.length;
        totalRevenue = totalRev;
        vendorRevenues = vendorRev;
        totalCustomers = customers.docs.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchDashboardData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeaderSection(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRevenueOverview(),
                        const SizedBox(height: 20),
                        _buildOrdersSection(),
                        const SizedBox(height: 20),
                        _buildMetricsGrid(),
                        const SizedBox(height: 20),
                        _buildDetailedStats(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Admin',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Revenue',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,##0.00').format(totalRevenue)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRevenueMetric(
                  'Growth Rate', '${growthRate.toStringAsFixed(1)}%'),
              _buildRevenueMetric('Avg. Order',
                  '₹${(totalRevenue / (totalCompletedOrders == 0 ? 1 : totalCompletedOrders)).toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersSection() {
    return Row(
      children: [
        Expanded(
          child: _buildOrderCard(
            'Completed Orders',
            totalCompletedOrders.toString(),
            Icons.check_circle_outline,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildOrderCard(
            'Pending Orders',
            pendingOrders.toString(),
            Icons.pending_outlined,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
            'Total Customers', totalCustomers.toString(), Icons.people_outline),
        _buildMetricCard(
            'Active Vendors', totalVendors.toString(), Icons.store_outlined),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
              'Total Orders', '${totalCompletedOrders + pendingOrders}'),
          _buildDetailRow('Completion Rate',
              '${((totalCompletedOrders / (totalCompletedOrders + pendingOrders)) * 100).toStringAsFixed(1)}%'),
          _buildDetailRow('Average Revenue per Customer',
              '₹${(totalRevenue / (totalCustomers == 0 ? 1 : totalCustomers)).toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
