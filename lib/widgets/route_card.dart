import 'package:flutter/material.dart';

class RouteCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;
  final Color? color;
  final bool isActive;
  final bool isCompleted;  // 🆕 новый параметр
  final int? progressPercent; // 🆕 процент прохождения (опционально)

  const RouteCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
    this.color,
    this.isActive = false,
    this.isCompleted = false,      // 🆕
    this.progressPercent,          // 🆕
  });

  String _getButtonText() {
    if (isCompleted) return 'Пройден ✓';
    if (isActive) return 'Продолжить →';
    return 'Начать';
  }

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
              child: Opacity(
                opacity: isCompleted ? 0.7 : 1.0,
                child: Image.asset(
                  imagePath,
                  width: imageWidth,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // 🆕 Бейдж "Пройден"
            if (isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'ПРОЙДЕН',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // 🆕 Бейдж "В процессе"
            if (isActive && !isCompleted && progressPercent != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${progressPercent}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Прогресс-бар (если активный)
            if (isActive && !isCompleted && progressPercent != null)
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: LinearProgressIndicator(
                  value: (progressPercent ?? 0) / 100,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  borderRadius: BorderRadius.circular(4),
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
                    onPressed: isCompleted ? null : onTap, // пройденные маршруты неактивны
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted ? Colors.grey : Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(_getButtonText()),
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