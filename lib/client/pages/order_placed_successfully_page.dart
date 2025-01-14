import 'package:flutter/material.dart';

import 'orders_page.dart';

class OrderPlacedSuccessfullyPage extends StatelessWidget {
  final String orderId;

  const OrderPlacedSuccessfullyPage({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Order Success Image
              Image.asset(
                'assets/images/order_success.png', // Make sure to add this image
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 32),

              // Success Title
              const Text(
                'Order Placed Successfully',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Email confirmation text
              const Text(
                'You will receive an email confirmation',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9DA3B4),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // See Order Details Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdersPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'See Order details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
