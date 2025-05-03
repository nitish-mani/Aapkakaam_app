import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Page'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Coming Soon...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // const SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () {
            //     // Add your payment logic here
            //   },
            //   child: const Text('Proceed to Payment'),
            // ),
          ],
        ),
      ),
    );
  }
}
