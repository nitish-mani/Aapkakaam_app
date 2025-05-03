import 'package:app_aapkakaam/data/constants.dart';
import 'package:flutter/material.dart';

class ScrollableCardPage extends StatelessWidget {
  const ScrollableCardPage({
    super.key,
    this.cardColor = Colors.amber,
    this.cardFirstChildColor = Colors.pink,
    this.cardSecondChildColor = Colors.black,
    this.imageWidth = 150,
    this.imageHeight = 150,
    this.isBorder = false,
  });

  final Color cardColor;
  final Color cardFirstChildColor;
  final Color cardSecondChildColor;
  final double imageWidth;
  final double imageHeight;
  final bool isBorder;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                // border: Border.all(color: Colors.white70),
                color: cardFirstChildColor,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.asset(
                      'assets/images/labour.jpg',
                      width: 150.0,
                      height: 150.0,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Text(
                    'Labour',
                    style: TextStyle(
                      // color: Colors.black,
                      fontSize: KTextStyle.titleTealText.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.0),
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: isBorder ? Border.all(color: Colors.black) : null,
                color: cardSecondChildColor,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.asset(
                      'assets/images/mason.jpg',
                      width: 150.0,
                      height: 150.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Text(
                    'Mason',
                    style: TextStyle(
                      fontSize: KTextStyle.titleTealText.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 10.0),
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                // border: Border.all(color: Colors.white70),
                color: cardFirstChildColor,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.asset(
                      'assets/images/electrician.jpg',
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Text(
                    'Electrician',
                    style: TextStyle(
                      fontSize: KTextStyle.titleTealText.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.0),
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: isBorder ? Border.all(color: Colors.black) : null,
                color: cardSecondChildColor,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.asset(
                      'assets/images/plumber.jpg',
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Text(
                    'Plumber',
                    style: TextStyle(
                      fontSize: KTextStyle.titleTealText.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
