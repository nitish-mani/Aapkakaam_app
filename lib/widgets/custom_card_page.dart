// This file is responsive and optimized with Emoji Support

import 'dart:convert';
import 'package:app_aapkakaam/widgets/address_page.dart';
import 'package:app_aapkakaam/widgets/booking_date_selection.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomCardPage extends StatefulWidget {
  const CustomCardPage({
    super.key,
    this.cardColor = Colors.amber,
    this.cardFirstChildColor = Colors.pink,
    this.cardSecondChildColor = Colors.black,
    this.isDarkTheme = false,
    required this.imageData,
  });

  final List<dynamic> imageData;
  final Color cardColor;
  final Color cardFirstChildColor;
  final Color cardSecondChildColor;
  final bool isDarkTheme;

  @override
  State<CustomCardPage> createState() => _CustomCardPageState();
}

class _CustomCardPageState extends State<CustomCardPage> {
  bool? _hasAddress;

  @override
  void initState() {
    super.initState();
    _checkAddressStatus();
  }

  Future<void> _checkAddressStatus() async {
    final hasAddress = await _userHasAddress();
    if (mounted) {
      setState(() => _hasAddress = hasAddress);
    }
  }

  Future<bool> _userHasAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      final vendorData = prefs.getString('vendor');

      bool hasAddressInData(String? data) {
        if (data == null) return false;
        final decoded = jsonDecode(data);
        return decoded['address'] != null && decoded['address'].isNotEmpty;
      }

      return hasAddressInData(userData) || hasAddressInData(vendorData);
    } catch (e) {
      debugPrint('Error checking address status: $e');
      return false;
    }
  }

  void _showAddAddressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text(
              '📍 Address Required',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('Please add your address to continue booking.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (context) => const AddAddressDialog(),
                  );
                  if (result == true) {
                    Navigator.of(context).pop();
                    _checkAddressStatus();
                  }
                },
                child: const Text(
                  'Add Address',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _handleServiceTap(BuildContext context, String profession) async {
    final hasAddress = _hasAddress ?? await _userHasAddress();

    if (hasAddress) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingDateSelection(profession: profession),
        ),
      );
    } else {
      _showAddAddressDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final useGridView = screenWidth >= 500;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              widget.isDarkTheme
                  ? [
                    widget.cardColor.withOpacity(0.3),
                    widget.cardColor.withOpacity(0.1),
                  ]
                  : [
                    widget.cardColor.withOpacity(0.2),
                    widget.cardColor.withOpacity(0.05),
                  ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child:
          useGridView
              ? _buildGridLayout(screenWidth)
              : _buildColumnLayout(screenWidth),
    );
  }

  Widget _buildGridLayout(double screenWidth) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _responsiveValue(screenWidth, 160.w, 180.w, 200.w),
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 0.9,
      ),
      itemCount: widget.imageData.length,
      itemBuilder: (context, index) {
        final item = widget.imageData[index];
        final color =
            index % 2 == 0
                ? widget.cardFirstChildColor
                : widget.cardSecondChildColor;
        return _buildServiceCard(
          context,
          item['image'] ?? '📌', // Fallback emoji
          item['title'] ?? 'Service',
          item['hindi'] ?? '',
          color,
          screenWidth,
        );
      },
    );
  }

  Widget _buildColumnLayout(double screenWidth) {
    List<Widget> rows = [];
    for (int i = 0; i < widget.imageData.length; i += 2) {
      final first = widget.imageData[i];
      final second =
          (i + 1 < widget.imageData.length) ? widget.imageData[i + 1] : null;
      final isReverse = (i ~/ 2) % 2 == 1;

      rows.add(
        Row(
          children: [
            Expanded(
              child: _buildServiceCard(
                context,
                first['image'] ?? '📌',
                first['title'] ?? 'Service',
                first['hindi'] ?? '',
                isReverse
                    ? widget.cardSecondChildColor
                    : widget.cardFirstChildColor,
                screenWidth,
              ),
            ),
            if (second != null)
              Expanded(
                child: _buildServiceCard(
                  context,
                  second['image'] ?? '📌',
                  second['title'] ?? 'Service',
                  second['hindi'] ?? '',
                  isReverse
                      ? widget.cardFirstChildColor
                      : widget.cardSecondChildColor,
                  screenWidth,
                ),
              ),
          ],
        ),
      );

      rows.add(SizedBox(height: 8.h));
    }

    return Column(children: rows);
  }

  double _responsiveValue(
    double screenWidth,
    double small,
    double medium,
    double large,
  ) {
    if (screenWidth >= 900) return large;
    if (screenWidth >= 600) return medium;
    return small;
  }

  Widget _buildServiceCard(
    BuildContext context,
    String emoji,
    String title,
    String hindiTitle,
    Color color,
    double screenWidth,
  ) {
    final fontSize = _responsiveValue(screenWidth, 12.sp, 14.sp, 16.sp);
    final padding = _responsiveValue(screenWidth, 8.w, 10.w, 12.w);

    // Get gradient colors based on emoji
    List<Color> gradientColors = _getEmojiGradient(emoji);

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: InkWell(
        onTap: () => _handleServiceTap(context, title),
        borderRadius: BorderRadius.circular(14.r),
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            gradient: LinearGradient(
              colors:
                  widget.isDarkTheme
                      ? [color.withOpacity(0.3), color.withOpacity(0.1)]
                      : gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8.r,
                offset: Offset(0, 3.h),
              ),
            ],
            border: Border.all(
              color:
                  widget.isDarkTheme
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji Container
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        widget.isDarkTheme
                            ? [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ]
                            : gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: _responsiveValue(
                      screenWidth,
                      28.sp,
                      32.sp,
                      36.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              // English Title
              Text(
                title,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkTheme ? Colors.white : Colors.black87,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              // Hindi Title
              if (hindiTitle.isNotEmpty)
                Text(
                  hindiTitle,
                  style: TextStyle(
                    fontSize: fontSize * 0.8,
                    fontWeight: FontWeight.w400,
                    color:
                        widget.isDarkTheme
                            ? Colors.grey[400]
                            : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Emoji Gradient Helper
  // ============================================================
  List<Color> _getEmojiGradient(String emoji) {
    final emojiColors = {
      '👷': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🧱': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '⚡': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '🔧': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🎨': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      '🪚': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🔲': [const Color(0xFF95A5A6), const Color(0xFF7F8C8D)],
      '💎': [const Color(0xFF1ABC9C), const Color(0xFF16A085)],
      '🏛️': [const Color(0xFFF39C12), const Color(0xFFE67E22)],
      '❄️': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🧊': [const Color(0xFF1ABC9C), const Color(0xFF16A085)],
      '🏍️': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🚗': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '💻': [const Color(0xFF2C3E50), const Color(0xFF34495E)],
      '🚕': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '📚': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      '🥛': [const Color(0xFFECF0F1), const Color(0xFFBDC3C7)],
      '👕': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '💄': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🌸': [const Color(0xFFFF6B81), const Color(0xFFFF4757)],
      '🕉️': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🍳': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '💡': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '⛺': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🎵': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      '⚙️': [const Color(0xFF95A5A6), const Color(0xFF7F8C8D)],
      '🎧': [const Color(0xFF2C3E50), const Color(0xFF34495E)],
      '🍽️': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '💧': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🍛': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🐴': [const Color(0xFF8B4513), const Color(0xFFA0522D)],
      '🌿': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🍎': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '💒': [const Color(0xFFFF6B81), const Color(0xFFFF4757)],
      '🚘': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🚌': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '🛺': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🛵': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🚚': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🌾': [const Color(0xFFF39C12), const Color(0xFFE67E22)],
      '🔄': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🧹': [const Color(0xFF95A5A6), const Color(0xFF7F8C8D)],
      '✂️': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
    };

    return emojiColors[emoji] ??
        [const Color(0xFF6A11CB), const Color(0xFF8E2DE2)];
  }
}
