// lib/screens/ready_routes_screen.dart

import 'package:flutter/material.dart';

import 'jurassic_screen.dart';
import 'whale_screen.dart';
import 'cenozoic_screen.dart';
import '../widgets/route_card.dart';
import '../widgets/bottom_bar.dart';

class ReadyRoutesScreen extends StatefulWidget {
  const ReadyRoutesScreen({super.key});

  @override
  State<ReadyRoutesScreen> createState() => _ReadyRoutesScreenState();
}

class _ReadyRoutesScreenState extends State<ReadyRoutesScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  final List<Map<String, dynamic>> routes = [
    {
      'title': 'Юрский период',
      'subtitle': 'Погружаемся в мир динозавров',
      'image': 'assets/images/routes/jurassic.png',
      'bgColor': const Color(0xFF344651),
    },
    {
      'title': 'Назад в океан',
      'subtitle': 'Как оленёнок стал китом',
      'image': 'assets/images/routes/whale.png',
      'bgColor': const Color.fromARGB(255, 235, 183, 25),
    },
    {
      'title': 'От раптора до колибри',
      'subtitle': 'Динозавры сред нас',
      'image': 'assets/images/routes/Ichthyornis.png',
      'bgColor': const Color.fromARGB(255, 124, 207, 208),
    },
    {
      'title': 'Мир млекопитающих',
      'subtitle': 'Исследуем разнообразие зверей',
      'image': 'assets/images/routes/mammals.png',
      'bgColor': const Color(0xFF5A4E7C),
    },
    {
      'title': 'Кембрийский взрыв',
      'subtitle': 'Всплеск жизни в океанах',
      'image': 'assets/images/routes/cambrian.png',
      'bgColor': const Color(0xFF6C4C4C),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.65);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToRoute(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const JurassicScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WhaleScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CenozoicScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Этот маршрут пока в разработке!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.black87, fontFamily: 'Roboto'),
                  children: [
                    TextSpan(
                      text: '\nвыбери свой \n',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.5,
                        height: 0.8,
                      ),
                    ),
                    TextSpan(
                      text: 'МАРШРУТ',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        height: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Блок с карточками фиксированной высоты
            SizedBox(
              height: 420 + 80,
              child: PageView.builder(
                controller: _pageController,
                itemCount: routes.length,
                onPageChanged: (index) {
                  setState(() => _currentPageIndex = index);
                },
                itemBuilder: (context, index) {
                  final route = routes[index];
                  final isActive = index == _currentPageIndex;

                  return Padding(
                    padding: const EdgeInsets.only(top: 35),
                    child: RouteCard(
                      title: route['title'] as String,
                      subtitle: route['subtitle'] as String,
                      imagePath: route['image'] as String,
                      color: route['bgColor'] as Color,
                      isActive: isActive,
                      onTap: () => _navigateToRoute(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DarwinBottomBar(currentIndex: 0),
    );
  }
}
