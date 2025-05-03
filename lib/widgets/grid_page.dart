import 'package:flutter/material.dart';

class GridPage extends StatelessWidget {
  GridPage({super.key});

  final SliverGridDelegate gridDelegate =
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 2.0,
      );

  @override
  Widget build(BuildContext context) {
    return GridView(
      gridDelegate: gridDelegate,
      children: [
        Container(color: Colors.amber, child: Center(child: Text('Item 1'))),
        Container(color: Colors.blue, child: Center(child: Text('Item 2'))),
        Container(color: Colors.amber, child: Center(child: Text('Item 3'))),
        Container(color: Colors.blue, child: Center(child: Text('Item 4'))),
        Container(color: Colors.amber, child: Center(child: Text('Item 5'))),
        Container(color: Colors.blue, child: Center(child: Text('Item 6'))),
        Container(color: Colors.amber, child: Center(child: Text('Item 5'))),
        Container(color: Colors.blue, child: Center(child: Text('Item 6'))),
      ],
    );
  }
}
