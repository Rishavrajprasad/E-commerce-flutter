import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../client/pages/auth/login.dart';
import 'screens/admin_statistics_screen.dart';
import 'screens/admin_vendors_screen.dart';
import 'screens/admin_customers_screen.dart';
import 'screens/admin_orders_screen.dart';

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
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              FirebaseAuth.instance.signOut().then((_) {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const Login()));
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Colors.white],
          ),
        ),
        child: const DashboardHomeScreen(),
      ),
    );
  }
}

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(24.0),
      crossAxisCount: 2,
      crossAxisSpacing: 24.0,
      mainAxisSpacing: 24.0,
      children: [
        _buildNavigationCard(
          context,
          'Statistics',
          Icons.analytics,
          const Color(0xFF303F9F),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminStatisticsScreen()),
          ),
          'View sales and revenue analytics',
        ),
        _buildNavigationCard(
          context,
          'Vendors',
          Icons.store,
          const Color(0xFF2E7D32),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminVendorsScreen()),
          ),
          'Manage vendor accounts',
        ),
        _buildNavigationCard(
          context,
          'Customers',
          Icons.people,
          const Color(0xFFFF6B6B),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCustomersScreen()),
          ),
          'Manage customer accounts',
        ),
        _buildNavigationCard(
          context,
          'Orders',
          Icons.shopping_cart,
          const Color(0xFF4ECDC4),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
          ),
          'Manage orders',
        ),
      ],
    );
  }

  Widget _buildNavigationCard(
    BuildContext context,
    String title,
    IconData icon,
    Color cardColor,
    VoidCallback onTap,
    String description,
  ) {
    return Card(
      elevation: 4,
      shadowColor: cardColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor,
                cardColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 36.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 12.0),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
