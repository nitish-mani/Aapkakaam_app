// this file is made responsive for all devices with modern UI/UX.

import 'package:app_aapkakaam/widgets/booking_date_selection.dart';
import 'package:flutter/material.dart';
import 'package:app_aapkakaam/data/notifiers.dart';

// Import the serviceData from BodyPage
import 'package:app_aapkakaam/widgets/body_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  late List<ServiceItem> _filteredItems;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<ServiceItem> _allServices = [];

  // Theme Colors
  static const Color _primaryBlue = Color(0xFF4F46E5);
  static const Color _primaryPurple = Color(0xFF7C3AED);
  static const Color _accentOrange = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _loadAllServices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadAllServices() {
    // Extract all services from serviceData with their categories
    _allServices = [];
    for (var category in serviceData) {
      for (var service in category.services) {
        _allServices.add(service);
      }
    }
    _filteredItems = List.from(_allServices);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _filteredItems = List.from(_allServices);
      } else {
        _filteredItems =
            _allServices.where((service) {
              final searchable =
                  [
                    service.title.toLowerCase(),
                    service.hindi,
                    service.jobType.toLowerCase(),
                    service.description.toLowerCase(),
                    service.descriptionHindi,
                  ].join(' ').toLowerCase();
              return searchable.contains(query);
            }).toList();
      }
    });
  }

  // Get display name based on language
  String _getDisplayName(ServiceItem service) {
    return isHindiNotifier.value ? service.hindi : service.title;
  }

  // Get display description based on language
  String _getDisplayDescription(ServiceItem service) {
    return isHindiNotifier.value
        ? service.descriptionHindi
        : service.description;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isHindi = isHindiNotifier.value;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ValueListenableBuilder<bool>(
        valueListenable: isHindiNotifier,
        builder: (context, isHindi, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: isDarkThemeNotifier,
            builder: (context, isDarkTheme, _) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: mediaQuery.size.width * 0.04,
                  vertical: mediaQuery.size.height * 0.02,
                ),
                child: Column(
                  children: [
                    // Search Bar
                    _buildModernSearchField(mediaQuery, isDarkTheme, isHindi),
                    SizedBox(height: mediaQuery.size.height * 0.02),
                    // Results Summary
                    if (_query.isNotEmpty)
                      _buildResultsSummary(mediaQuery, isDarkTheme, isHindi),
                    // Results List
                    Expanded(
                      child: _buildModernResultsList(
                        mediaQuery,
                        isDarkTheme,
                        isHindi,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildModernSearchField(
    MediaQueryData mediaQuery,
    bool isDarkTheme,
    bool isHindi,
  ) {
    final isSmallScreen = mediaQuery.size.width < 400;

    return Container(
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDarkTheme
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.2 : 0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            child: Icon(Icons.search_rounded, color: _primaryBlue, size: 24),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(
                fontSize: mediaQuery.size.width * 0.045,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: isHindi ? 'सेवा खोजें...' : 'Search service...',
                hintStyle: TextStyle(
                  fontSize: mediaQuery.size.width * 0.04,
                  color: isDarkTheme ? Colors.white54 : Colors.grey[500],
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: mediaQuery.size.width * 0.02,
                  vertical: mediaQuery.size.height * 0.02,
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: isDarkTheme ? Colors.white54 : Colors.grey[500],
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                  _filteredItems = List.from(_allServices);
                });
              },
            ),
          Container(
            margin: EdgeInsets.all(6),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryBlue, _primaryPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_allServices.length}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSummary(
    MediaQueryData mediaQuery,
    bool isDarkTheme,
    bool isHindi,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: _primaryBlue, size: 18),
          SizedBox(width: 8),
          Text(
            isHindi
                ? '${_filteredItems.length} ${_filteredItems.length == 1 ? 'सेवा मिली' : 'सेवाएँ मिलीं'}'
                : '${_filteredItems.length} ${_filteredItems.length == 1 ? 'service' : 'services'} found',
            style: TextStyle(
              color: isDarkTheme ? Colors.white : const Color(0xFF172033),
              fontWeight: FontWeight.w600,
              fontSize: mediaQuery.size.width * 0.035,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernResultsList(
    MediaQueryData mediaQuery,
    bool isDarkTheme,
    bool isHindi,
  ) {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (isDarkTheme ? Colors.white : Colors.black).withOpacity(
                  0.05,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: isDarkTheme ? Colors.white30 : Colors.grey[400],
              ),
            ),
            SizedBox(height: 16),
            Text(
              isHindi ? 'कोई सेवा नहीं मिली' : 'No services found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: mediaQuery.size.width * 0.05,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              isHindi
                  ? 'दूसरा नाम लिखकर खोजें या अंग्रेज़ी में खोजें।'
                  : 'Try another name or search in Hindi.',
              style: TextStyle(
                fontSize: mediaQuery.size.width * 0.035,
                color: isDarkTheme ? Colors.white54 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Build the list manually - SIMPLEST APPROACH
    List<Widget> widgets = [];

    // Add all services
    for (int i = 0; i < _filteredItems.length; i++) {
      widgets.add(
        _buildModernListItem(
          context,
          _filteredItems[i],
          mediaQuery,
          isDarkTheme,
          isHindi,
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.only(top: mediaQuery.size.height * 0.01),
      children: widgets,
    );
  }

  Widget _buildModernListItem(
    BuildContext context,
    ServiceItem service,
    MediaQueryData mediaQuery,
    bool isDarkTheme,
    bool isHindi,
  ) {
    final colors = _getEmojiColors(service.emoji);
    final displayName = _getDisplayName(service);
    final displayDesc = _getDisplayDescription(service);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: mediaQuery.size.width * 0.01,
        vertical: mediaQuery.size.height * 0.005,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _navigateToBooking(context, service.title),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Emoji Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors[0].withOpacity(0.15),
                      colors[1].withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors[0].withOpacity(0.15)),
                ),
                child: Center(
                  child: Text(service.emoji, style: TextStyle(fontSize: 24)),
                ),
              ),
              SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: mediaQuery.size.width * 0.045,
                        fontWeight: FontWeight.w700,
                        color:
                            isDarkTheme
                                ? Colors.white
                                : const Color(0xFF172033),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      displayDesc.length > 60
                          ? '${displayDesc.substring(0, 60)}...'
                          : displayDesc,
                      style: TextStyle(
                        fontSize: mediaQuery.size.width * 0.03,
                        color: isDarkTheme ? Colors.white54 : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Job Type Tag
                    Container(
                      margin: EdgeInsets.only(top: 6),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service.jobType,
                        style: TextStyle(
                          fontSize: mediaQuery.size.width * 0.025,
                          color: _primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: _primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToBooking(BuildContext context, String profession) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDateSelection(profession: profession),
      ),
    );
  }

  // ============================================================
  // Emoji Colors (copied from BodyPage)
  // ============================================================

  List<Color> _getEmojiColors(String emoji) {
    final map = {
      '👷': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🧱': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '⚡': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '🔧': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🎨': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      '🪚': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🔲': [const Color(0xFF95A5A6), const Color(0xFF7F8C8D)],
      '💎': [const Color(0xFF1ABC9C), const Color(0xFF16A085)],
      '🏛️': [const Color(0xFFF39C12), const Color(0xFFE67E22)],
      '🔥': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '⚙️': [const Color(0xFF95A5A6), const Color(0xFF7F8C8D)],
      '🪟': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🎭': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      '❄️': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🧊': [const Color(0xFF1ABC9C), const Color(0xFF16A085)],
      '🏍️': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🚗': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '💻': [const Color(0xFF2C3E50), const Color(0xFF34495E)],
      '📹': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🔋': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '📡': [const Color(0xFFF39C12), const Color(0xFFE67E22)],
      '🚕': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '📚': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      '🥛': [const Color(0xFFECF0F1), const Color(0xFFBDC3C7)],
      '👕': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🌱': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🛡️': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🧹': [const Color(0xFF95A5A6), const Color(0xFF7F8C8D)],
      '👶': [const Color(0xFFFF6B81), const Color(0xFFFF4757)],
      '👴': [const Color(0xFF8B4513), const Color(0xFFA0522D)],
      '💄': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🌸': [const Color(0xFFFF6B81), const Color(0xFFFF4757)],
      '🕉️': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🍳': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '💡': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '⛺': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🎵': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      '🎧': [const Color(0xFF2C3E50), const Color(0xFF34495E)],
      '🍽️': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '💧': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🍛': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🐴': [const Color(0xFF8B4513), const Color(0xFFA0522D)],
      '🌿': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🍎': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '💒': [const Color(0xFFFF6B81), const Color(0xFFFF4757)],
      '📸': [const Color(0xFF2C3E50), const Color(0xFF34495E)],
      '🎥': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '💋': [const Color(0xFFFF6B81), const Color(0xFFFF4757)],
      '🎺': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '🎆': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🍲': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '🚘': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🚌': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      '🛺': [const Color(0xFFFF6B35), const Color(0xFFF7931E)],
      '🛵': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🚚': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🌾': [const Color(0xFFF39C12), const Color(0xFFE67E22)],
      '🔄': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '✂️': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
      '🐜': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '🧽': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🪣': [const Color(0xFF95A5A6), const Color(0xFF7F8C8D)],
      '🛁': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      '🧺': [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      '📺': [const Color(0xFF2C3E50), const Color(0xFF34495E)],
      '💃': [const Color(0xFFFF6B81), const Color(0xFFFF4757)],
      '🗣️': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
    };
    return map[emoji] ?? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)];
  }
}
