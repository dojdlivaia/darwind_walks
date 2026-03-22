import 'package:flutter/material.dart';

class RouteCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;
  final Color? color;
  final bool isActive;

  const RouteCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.55;
    final double cardHeight = 300.0;
    final double imageWidth = isActive ? cardWidth * 1.05 : cardWidth * 0.95;

    return Card(
      color: color ?? Colors.blueGrey[100],
      clipBehavior: Clip.none,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Изображение
            Positioned(
              top: isActive ? -0.12 * cardHeight : 0,
              left: isActive ? -0.05 * cardWidth : (cardWidth - imageWidth) / 2,
              child: Image.asset(
                imagePath,
                width: imageWidth,
                fit: BoxFit.cover,
              ),
            ),
            // Контент карточки
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("Начать"),
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
