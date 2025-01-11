import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/client/pages/auth/login.dart';
import 'package:saloon_app/client/pages/profile/edit_profile_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../orders_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      // Sign out from Google
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      body: user == null
          ? const Center(child: Text('Please login to view profile'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong!'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};

                return CustomScrollView(
                  slivers: [
                    // Flexible App Bar with Profile Header
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      backgroundColor: const Color(0xFF8B5CF6),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF8B5CF6),
                                const Color(0xFF8B5CF6).withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white24,
                                  child: Icon(Icons.person,
                                      size: 50, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                userData['name'] ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // User Info Card
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildInfoRow(
                                      Icons.email_outlined,
                                      'Email',
                                      userData['email'] ?? user.email ?? '',
                                      theme,
                                    ),
                                    const Divider(height: 24),
                                    _buildInfoRow(
                                      Icons.calendar_today_outlined,
                                      'Member Since',
                                      _formatDate(userData['createdAt']),
                                      theme,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Actions Card
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  _buildOptionTile(
                                    icon: Icons.person_outline,
                                    title: 'Edit Profile',
                                    subtitle:
                                        'Add phone number, address and more',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const EditProfilePage()),
                                    ),
                                    showBorder: true,
                                  ),
                                  _buildOptionTile(
                                    icon: Icons.history,
                                    title: 'Booking History',
                                    subtitle: 'View your past appointments',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const OrdersPage(),
                                        ),
                                      );
                                    },
                                    showBorder: true,
                                  ),
                                  _buildOptionTile(
                                    icon: Icons.logout,
                                    title: 'Sign Out',
                                    subtitle: 'Log out from your account',
                                    onTap: () => _signOut(context),
                                    textColor: Colors.red,
                                    showBorder: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    required bool showBorder,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (textColor ?? const Color(0xFF8B5CF6)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: textColor ?? const Color(0xFF8B5CF6)),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        if (showBorder) Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not available';
    if (date is Timestamp) {
      return date.toDate().toString().split(' ')[0];
    }
    if (date is DateTime) {
      return date.toString().split(' ')[0];
    }
    return 'Not available';
  }
}
