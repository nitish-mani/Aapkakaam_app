// this file is made responsive for all devices.

import 'package:app_aapkakaam/widgets/booking_date_selection.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Sorted alphabetically for better UX
  static const List<String> _professions = [
    "AC Mechanic",
    "Aata Chakki",
    "Auto",
    "Bhoonsa Pual Seller",
    "Bike Repair",
    "Bus",
    "Carpenter",
    "Car Repair",
    "Chaat",
    "Cook",
    "DJ",
    "Dhankutti",
    "Dulha Rath",
    "E-Riksha",
    "Electrician",
    "Four Wheeler",
    "Fridge Mechanic",
    "Fruit Seller",
    "Generator",
    "Home Tutor",
    "Kirtan Mandli",
    "Labour",
    "Laptop Repair",
    "Latrine Tank Cleaner",
    "Lights",
    "Marble Fitter",
    "Marriage Hall",
    "Mason",
    "Menhandi Maker",
    "Milk Man",
    "Mini Truck",
    "Painter",
    "Paan Wala",
    "Parlour",
    "Plumber",
    "Pual Cutter",
    "Pundit Ji",
    "RO",
    "Shuttering",
    "Tent House",
    "Tiles Fitter",
    "Waiter",
    "Washer Man",
  ];

  String _query = '';
  late List<String> _filteredItems;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _filteredItems = _professions;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _query = query;
      _filteredItems =
          _professions
              .where((item) => item.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    // ignore: deprecated_member_use
    final textScale = mediaQuery.textScaleFactor;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width * 0.04,
          vertical: mediaQuery.size.height * 0.02,
        ),
        child: Column(
          children: [
            // Search Bar
            _buildSearchField(mediaQuery, textScale),
            SizedBox(height: mediaQuery.size.height * 0.02),
            // Results List
            Expanded(child: _buildResultsList(mediaQuery, isPortrait)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(MediaQueryData mediaQuery, double textScale) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search service...',
        hintStyle: TextStyle(
          fontSize: mediaQuery.size.width * 0.04 * textScale,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width * 0.04,
          vertical: mediaQuery.size.height * 0.02,
        ),
        prefixIcon: Icon(Icons.search, size: mediaQuery.size.width * 0.06),
      ),
      style: TextStyle(fontSize: mediaQuery.size.width * 0.045 * textScale),
    );
  }

  Widget _buildResultsList(MediaQueryData mediaQuery, bool isPortrait) {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Text(
          'No results found',
          style: TextStyle(
            fontSize: mediaQuery.size.width * 0.05,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: mediaQuery.size.height * 0.01),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildListItem(context, _filteredItems[index], mediaQuery);
      },
    );
  }

  Widget _buildListItem(
    BuildContext context,
    String profession,
    MediaQueryData mediaQuery,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: mediaQuery.size.width * 0.01,
        vertical: mediaQuery.size.height * 0.005,
      ),
      elevation: 1,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width * 0.04,
          vertical: mediaQuery.size.height * 0.01,
        ),
        title: Text(
          profession,
          style: TextStyle(
            fontSize: mediaQuery.size.width * 0.045,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: mediaQuery.size.width * 0.05,
        ),
        onTap: () => _navigateToBooking(context, profession),
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
}
