import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/widgets/login_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // Theme Colors
  static const Color _primaryBlue = Color(0xFF4F46E5);
  static const Color _primaryPurple = Color(0xFF7C3AED);
  static const Color _primaryLight = Color(0xFFEEF2FF);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textLight = Color(0xFF6B7280);

  String _t(String english, String hindi) {
    return isHindiNotifier.value ? hindi : english;
  }

  Future<void> _navigateToLogin(BuildContext context, bool isVendorMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isVendor", isVendorMode);
    isVendor.value = isVendorMode;

    if (!mounted) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (_, animation, __) =>
                LoginPage(category: isVendorMode ? 'vendor' : 'user'),
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.height < 720;
    final horizontal = size.width < 420 ? 22.0 : 32.0;

    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        return Scaffold(
          backgroundColor: _primaryLight,
          body: Stack(
            children: [
              // Soft background decoration with theme colors
              Positioned(
                top: -120,
                right: -100,
                child: _blob(280, _primaryBlue.withOpacity(0.08)),
              ),
              Positioned(
                bottom: -150,
                left: -120,
                child: _blob(330, _primaryPurple.withOpacity(0.08)),
              ),
              Positioned(
                top: 100,
                left: -80,
                child: _blob(200, _primaryBlue.withOpacity(0.05)),
              ),
              Positioned(
                bottom: 200,
                right: -60,
                child: _blob(180, _primaryPurple.withOpacity(0.05)),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      14,
                      horizontal,
                      28,
                    ),
                    child: Column(
                      children: [
                        // Top bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [_brandMini(), _languageButton(isHindi)],
                        ),

                        SizedBox(height: isCompact ? 20 : 34),

                        // Hero illustration with theme border
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            14,
                            isCompact ? 8 : 14,
                            14,
                            14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryBlue.withOpacity(0.10),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                            border: Border.all(
                              color: _primaryBlue.withOpacity(0.10),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: isCompact ? 210 : 285,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Lottie.asset(
                                      'assets/lotties/welcome.json',
                                      fit: BoxFit.contain,
                                    ),
                                    Positioned(
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primaryBlue.withOpacity(
                                                0.25,
                                              ),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            'assets/images/aapkakaam_aa.jpg',
                                            width: isCompact ? 52 : 66,
                                            height: isCompact ? 52 : 66,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isCompact ? 24 : 34),

                        // Heading with theme color
                        Text(
                          _t(
                            'Welcome to Aapkakaam',
                            'आपकाकाम में आपका स्वागत है',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 29,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: _textDark,
                            letterSpacing: -.7,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          _t(
                            'Find trusted local services, right when you need them.',
                            'जब जरूरत हो, भरोसेमंद स्थानीय सेवाएं आसानी से पाएं।',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: _textLight,
                          ),
                        ),

                        SizedBox(height: isCompact ? 26 : 34),

                        // Account choice card with theme border
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: _primaryBlue.withOpacity(0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryBlue.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  10,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _t(
                                      'How do you want to continue?',
                                      'आप कैसे आगे बढ़ना चाहते हैं?',
                                    ),
                                    style: TextStyle(
                                      color: _textDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),

                              _accountButton(
                                icon: Icons.person_rounded,
                                title: _t('Find a Service', 'सेवा खोजें'),
                                subtitle: _t(
                                  'Book a trusted local professional',
                                  'भरोसेमंद स्थानीय कारीगर की सेवा लें',
                                ),
                                onTap: () => _navigateToLogin(context, false),
                                primary: true,
                              ),

                              const SizedBox(height: 8),

                              _accountButton(
                                icon: Icons.handyman_rounded,
                                title: _t(
                                  'Offer Your Service',
                                  'अपनी सेवा दें',
                                ),
                                subtitle: _t(
                                  'Get customers and grow your work',
                                  'ग्राहक पाएं और अपना काम बढ़ाएं',
                                ),
                                onTap: () => _navigateToLogin(context, true),
                                primary: false,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Footer with theme color
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: _primaryBlue,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                _t(
                                  'Simple • Local • Trusted',
                                  'आसान • स्थानीय • भरोसेमंद',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _textLight,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _brandMini() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryBlue, _primaryPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/images/aapkakaam_aa.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Aapkakaam',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
          ),
        ),
      ],
    );
  }

  Widget _languageButton(bool isHindi) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => isHindiNotifier.value = !isHindiNotifier.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _primaryBlue.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, size: 18, color: _primaryBlue),
              const SizedBox(width: 6),
              Text(
                isHindi ? 'हिंदी' : 'English',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool primary,
  }) {
    final background =
        primary
            ? LinearGradient(
              colors: [_primaryBlue, _primaryPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
            : null;

    final foreground = primary ? Colors.white : _textDark;
    final secondary = primary ? Colors.white.withOpacity(.72) : _textLight;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: background,
            borderRadius: BorderRadius.circular(20),
            border:
                primary
                    ? null
                    : Border.all(color: _primaryBlue.withOpacity(0.15)),
            boxShadow:
                primary
                    ? [
                      BoxShadow(
                        color: _primaryBlue.withOpacity(0.30),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      primary ? Colors.white.withOpacity(.16) : _primaryLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: foreground, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: foreground.withOpacity(primary ? .9 : .55),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
