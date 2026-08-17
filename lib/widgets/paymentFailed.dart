import 'package:flutter/material.dart';

class PaymentFailedPage extends StatelessWidget {
  const PaymentFailedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],

      appBar: AppBar(
        title: const Text(
          'Payment Failed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Card(
              elevation: 4,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),

              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Container(
                      width: 80,
                      height: 80,

                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 64,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Payment Failed',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Your payment could not be completed.',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.06),

                        borderRadius: BorderRadius.circular(14),

                        border: Border.all(color: Colors.red.withOpacity(0.15)),
                      ),

                      child: const Text(
                        'No amount has been added to your balance. Please try again.',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,

                      height: 52,

                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.teal : Colors.blue,

                          foregroundColor: Colors.white,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        child: const Text(
                          'Back to Add Balance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
