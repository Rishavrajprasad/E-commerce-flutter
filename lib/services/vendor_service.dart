import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String vendorId = FirebaseAuth.instance.currentUser!.uid;

  // Get vendor's services
  Stream<QuerySnapshot> getServices() {
    return _firestore
        .collection('vendors')
        .doc(vendorId)
        .collection('services')
        .snapshots();
  }

  // Get vendor's payments
  Stream<QuerySnapshot> getPayments() {
    return _firestore
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('orderDate', descending: true)
        .snapshots();
  }

  // Get vendor profile (modified to match your structure)
  Stream<DocumentSnapshot> getVendorProfile() {
    return _firestore.collection('vendors').doc(vendorId).snapshots();
  }

  // Update vendor profile (modified to match your structure)
  Future<void> updateVendorProfile(Map<String, dynamic> profileData) {
    return _firestore.collection('vendors').doc(vendorId).update(profileData);
  }

  // Add new service
  Future<void> addService(Map<String, dynamic> serviceData) {
    return _firestore
        .collection('vendors')
        .doc(vendorId)
        .collection('services')
        .add(serviceData);
  }

  Future<void> deleteService(String serviceId) async {
    await FirebaseFirestore.instance
        .collection('vendors')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('services')
        .doc(serviceId)
        .delete();
  }

  String get currentVendorId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }
}
