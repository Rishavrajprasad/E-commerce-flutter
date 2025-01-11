import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<String?> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Check users collection
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      return userDoc.data()?['role'] as String?;
    }

    // Check vendors collection
    final vendorDoc = await FirebaseFirestore.instance
        .collection('vendors')
        .doc(user.uid)
        .get();

    if (vendorDoc.exists) {
      return vendorDoc.data()?['role'] as String?;
    }

    return null;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  static Future<bool> checkIfUserExists(String email) async {
    try {
      final result =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }
}
