import 'package:flutter/material.dart';
import 'package:app_aapkakaam/data/notifiers.dart';

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

  // Language helper
  String _t(String en, String hi) => isHindiNotifier.value ? hi : en;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHindi = isHindiNotifier.value;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B1020) : const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(
          _t('Payment Successful', 'भुगतान सफल'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : surface,
        foregroundColor: isDark ? Colors.white : onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                shadowColor: primaryColor.withOpacity(0.1),
                color: isDark ? const Color(0xFF1A1A2E) : surface,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // =====================================================
                      // SUCCESS ICON
                      // =====================================================
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // =====================================================
                      // TITLE
                      // =====================================================
                      Text(
                        _t('Payment Successful!', 'भुगतान सफल हुआ! 🎉'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        _t(
                          'Your payment has been processed successfully.',
                          'आपका भुगतान सफलतापूर्वक संसाधित हो गया है।',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // =====================================================
                      // PAYMENT DETAILS
                      // =====================================================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isDark
                                    ? [
                                      const Color(0xFF252540),
                                      const Color(0xFF1A1A2E),
                                    ]
                                    : [Colors.grey[50]!, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : const Color(0xFFE8ECF3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              label: _t('Payment ID', 'भुगतान आईडी'),
                              value: paymentId,
                              isDark: isDark,
                              icon: Icons.payment_outlined,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              label: _t('Order ID', 'ऑर्डर आईडी'),
                              value: orderId,
                              isDark: isDark,
                              icon: Icons.receipt_outlined,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              label: _t('Amount', 'राशि'),
                              value: '₹$amount',
                              isDark: isDark,
                              valueColor: Colors.green,
                              icon: Icons.currency_rupee_rounded,
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
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withOpacity(0.08),
                              Colors.green.withOpacity(0.03),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildMessageRow(
                              icon: Icons.check_circle_outline,
                              text: _t(
                                'Your balance has been updated successfully.',
                                'आपका बैलेंस सफलतापूर्वक अपडेट हो गया है।',
                              ),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildMessageRow(
                              icon: Icons.account_balance_wallet_outlined,
                              text: _t(
                                'You can now use your credits for bookings.',
                                'आप अब अपने क्रेडिट का उपयोग बुकिंग के लिए कर सकते हैं।',
                              ),
                              isDark: isDark,
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
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadowColor: primaryColor.withOpacity(0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.dashboard_rounded, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _t('Continue to Dashboard', 'डैशबोर्ड पर जाएं'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (valueColor ?? (isDark ? Colors.white : Colors.grey[900]))
                ?.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: valueColor ?? (isDark ? Colors.white : Colors.grey[600]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
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
              fontWeight: FontWeight.w700,
              color: valueColor ?? (isDark ? Colors.white : Colors.grey[900]),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageRow({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey[700],
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
