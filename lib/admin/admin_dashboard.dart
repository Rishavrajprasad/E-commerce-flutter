import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../client/pages/auth/login.dart';
import 'screens/admin_statistics_screen.dart';
import 'screens/admin_vendors_screen.dart';
import 'screens/admin_customers_screen.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/admin_vendor_payments_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            fontSize: 22,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const Login()));
            },
          ),
        ],
      ),
      body: const DashboardHomeScreen(),
    );
  }
}

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = screenSize.width * 0.04;
    final verticalPadding = screenSize.height * 0.02;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 1.2,
              ),
              delegate: SliverChildListDelegate([
                _buildNavigationCard(
                  context: context,
                  title: 'Statistics',
                  icon: Icons.analytics,
                  cardColor: const Color(0xFF1976D2),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminStatisticsScreen()),
                  ),
                  description: 'View sales and revenue analytics',
                ),
                _buildNavigationCard(
                  context: context,
                  title: 'Vendors',
                  icon: Icons.store,
                  cardColor: const Color(0xFF2E7D32),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminVendorsScreen()),
                  ),
                  description: 'Manage vendor accounts',
                ),
                _buildNavigationCard(
                  context: context,
                  title: 'Customers',
                  icon: Icons.people,
                  cardColor: const Color(0xFFFF6B6B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminCustomersScreen()),
                  ),
                  description: 'Manage customer accounts',
                ),
                _buildNavigationCard(
                  context: context,
                  title: 'Orders',
                  icon: Icons.shopping_cart,
                  cardColor: const Color(0xFF4ECDC4),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminOrdersScreen()),
                  ),
                  description: 'Manage orders',
                ),
                _buildNavigationCard(
                  context: context,
                  title: 'Vendor Payments',
                  icon: Icons.payments,
                  cardColor: const Color(0xFF9C27B0),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminVendorPaymentsScreen()),
                  ),
                  description: 'Manage vendor payments',
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color cardColor,
    required VoidCallback onTap,
    required String description,
  }) {
    return Card(
      elevation: 2,
      shadowColor: cardColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 12.0),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
