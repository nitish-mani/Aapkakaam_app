import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class CarouselPage extends StatelessWidget {
  const CarouselPage({super.key, required this.imageData});
  final List<Map<String, String>> imageData;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            animateToClosest: true,
          ),
          items:
              imageData.map((item) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        item['image']!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            item['title']!,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ],
    );
  }
}
