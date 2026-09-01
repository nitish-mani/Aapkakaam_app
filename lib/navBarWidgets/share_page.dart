import 'dart:convert';

import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  String? _url;
  String? _shareText;
  String? _name;
  bool _isLoading = true;

  final List<Map<String, String>> _shareOptions = const [
    {'label': 'Twitter', 'hindi': 'ट्विटर', 'icon': 'assets/icons/twitter.svg'},
    {
      'label': 'Facebook',
      'hindi': 'फेसबुक',
      'icon': 'assets/icons/facebook.svg',
    },
    {
      'label': 'LinkedIn',
      'hindi': 'लिंक्डइन',
      'icon': 'assets/icons/linkedin.svg',
    },
    {
      'label': 'WhatsApp',
      'hindi': 'व्हाट्सऐप',
      'icon': 'assets/icons/whatsapp.svg',
    },
    {
      'label': 'Telegram',
      'hindi': 'टेलीग्राम',
      'icon': 'assets/icons/telegram.svg',
    },
    {'label': 'SMS', 'hindi': 'एसएमएस', 'icon': 'assets/icons/message.svg'},
  ];

  String _t(String en, String hi) => isHindiNotifier.value ? hi : en;

  @override
  void initState() {
    super.initState();
    _loadShareData();
  }

  Future<void> _loadShareData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoryKey = isVendor.value ? 'vendor' : 'user';
      final raw = prefs.getString(categoryKey);

      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final id = data[categoryKey == 'user' ? 'userId' : 'vendorId'];
        final name = data['name']?.toString();

        if (!mounted) return;

        setState(() {
          _name = name;
          _url = 'https://aapkakaam.com/category/$categoryKey/$id';
          _shareText = 'Shared by ${name ?? ''} via AapKaKaam';
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading share data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _shareContent() async {
    if (_shareText == null || _url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _t(
              'Sharing content is not available yet',
              'शेयर करने की जानकारी अभी उपलब्ध नहीं है',
            ),
          ),
        ),
      );
      return;
    }

    await Share.share('$_shareText\n$_url');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, _, __) {
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkThemeNotifier,
          builder: (context, isDark, __) {
            final bg =
                isDark ? const Color(0xFF08111F) : const Color(0xFFF5F8FD);
            final surface = isDark ? const Color(0xFF101C2D) : Colors.white;
            final text = isDark ? Colors.white : const Color(0xFF142B49);
            final muted =
                isDark ? const Color(0xFF9AA9BC) : const Color(0xFF6A788C);
            final border =
                isDark
                    ? Colors.white.withOpacity(.08)
                    : const Color(0xFFE1E8F2);

            // Use theme colors
            final primaryColor = colorScheme.primary;
            final primaryContainer = colorScheme.primaryContainer;
            final onPrimary = colorScheme.onPrimary;

            return Scaffold(
              backgroundColor: bg,
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hero Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? .18 : .055,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      primaryColor,
                                      primaryColor.withOpacity(0.7),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.share_rounded,
                                  color: onPrimary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _t('Share Profile', 'प्रोफ़ाइल शेयर करें'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: text,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _name == null
                                    ? _t(
                                      'Share your Aapkakaam profile with others',
                                      'अपनी आपकाकाम प्रोफ़ाइल दूसरों के साथ शेयर करें',
                                    )
                                    : _t(
                                      'Share ${_name?.toUpperCase()}’s Aapkakaam profile',
                                      '${_name?.toUpperCase()} की आपकाकाम प्रोफ़ाइल शेयर करें',
                                    ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Share Apps Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? .14 : .035,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? primaryContainer.withOpacity(
                                                0.3,
                                              )
                                              : primaryColor.withOpacity(.10),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.send_rounded,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _t(
                                            'Share with',
                                            'इनके साथ शेयर करें',
                                          ),
                                          style: TextStyle(
                                            color: text,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        Text(
                                          _t('Choose an app', 'कोई ऐप चुनें'),
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Fixed grid height
                              SizedBox(
                                height: 178,
                                child: GridView.builder(
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _shareOptions.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 7,
                                        crossAxisSpacing: 7,
                                        childAspectRatio: 1.25,
                                      ),
                                  itemBuilder: (context, index) {
                                    final option = _shareOptions[index];
                                    final label =
                                        isHindiNotifier.value
                                            ? option['hindi']!
                                            : option['label']!;

                                    return Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(15),
                                      child: InkWell(
                                        onTap: _shareContent,
                                        borderRadius: BorderRadius.circular(15),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isDark
                                                    ? const Color(0xFF0B1626)
                                                    : const Color(0xFFF8FAFD),
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            border: Border.all(color: border),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                padding: const EdgeInsets.all(
                                                  7,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: surface,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: border,
                                                  ),
                                                ),
                                                child: SvgPicture.asset(
                                                  option['icon']!,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                label,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: text,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Main Share Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _shareContent,
                            icon: Icon(
                              Icons.apps_rounded,
                              color: onPrimary,
                              size: 20,
                            ),
                            label: Text(
                              _t(
                                'Share via Other Apps',
                                'अन्य ऐप्स से शेयर करें',
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: onPrimary,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Link Section
                        if (_isLoading)
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: primaryColor,
                            ),
                          )
                        else if (_url != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? primaryContainer.withOpacity(0.3)
                                            : primaryColor.withOpacity(.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.link_rounded,
                                    color: primaryColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _t('Your share link', 'आपका शेयर लिंक'),
                                        style: TextStyle(
                                          color: text,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _url!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 12),

                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
