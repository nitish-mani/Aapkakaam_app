import 'package:flutter/material.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String paymentId;
  final String orderId;
  final dynamic amount;

  const PaymentSuccessPage({
    super.key,
    required this.paymentId,
    required this.orderId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],

      appBar: AppBar(
        title: const Text(
          'Payment Successful',
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
                    // =====================================================
                    // SUCCESS ICON
                    // =====================================================
                    Container(
                      width: 80,
                      height: 80,

                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 64,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =====================================================
                    // TITLE
                    // =====================================================
                    Text(
                      'Payment Successful!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Your payment has been processed successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // =====================================================
                    // PAYMENT DETAILS
                    // =====================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[50],

                        borderRadius: BorderRadius.circular(16),

                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                        ),
                      ),

                      child: Column(
                        children: [
                          _buildDetailRow(
                            label: 'Payment ID',
                            value: paymentId,
                            isDark: isDark,
                          ),

                          const Divider(height: 24),

                          _buildDetailRow(
                            label: 'Order ID',
                            value: orderId,
                            isDark: isDark,
                          ),

                          const Divider(height: 24),

                          _buildDetailRow(
                            label: 'Amount',
                            value: '₹$amount',
                            isDark: isDark,
                            valueColor: Colors.green,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =====================================================
                    // SUCCESS MESSAGE
                    // =====================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                        ),
                      ),

                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 20,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  'Your balance has been updated successfully.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDark
                                            ? Colors.white70
                                            : Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Colors.green,
                                size: 20,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  'You can now use your credits for bookings.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDark
                                            ? Colors.white70
                                            : Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // =====================================================
                    // CONTINUE BUTTON
                    // =====================================================
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

                          elevation: 2,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        child: const Text(
                          'Continue to Dashboard',
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

  Widget _buildDetailRow({
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isDark ? Colors.white : Colors.grey[900]),
            ),
          ),
        ),
      ],
    );
  }
}
