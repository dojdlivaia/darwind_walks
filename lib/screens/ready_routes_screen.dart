// lib/screens/ready_routes_screen.dart

import 'package:flutter/material.dart';

import 'jurassic_screen.dart';
import 'whale_screen.dart';
import 'cenozoic_screen.dart';
import '../widgets/route_card.dart';
import '../widgets/bottom_bar.dart';
import '../data/repositories/route_state_repository.dart';
import '../data/daily_steps_repository.dart';
import '../models/route_progress.dart';

class ReadyRoutesScreen extends StatefulWidget {
  const ReadyRoutesScreen({super.key});

  @override
  State<ReadyRoutesScreen> createState() => _ReadyRoutesScreenState();
}

class _ReadyRoutesScreenState extends State<ReadyRoutesScreen> {
  late PageController _pageController;
  
  RouteStateRepository? _routeRepo;
  Set<String> _completedRoutes = {};
  ActiveRoute? _activeRoute;
  Map<String, int> _routeProgress = {};
  bool _isLoading = true;

  final List<Map<String, dynamic>> routes = [
    {
      'id': 'jurassic',
      'title': 'Юрский период',
      'subtitle': 'Погружаемся в мир динозавров',
      'image': 'assets/images/routes/jurassic.png',
      'bgColor': const Color(0xFF344651),
      'totalSteps': 18500,
    },
    {
      'id': 'whale',
      'title': 'Назад в океан',
      'subtitle': 'Как оленёнок стал китом',
      'image': 'assets/images/routes/whale.png',
      'bgColor': const Color.fromARGB(255, 235, 183, 25),
      'totalSteps': 15000,
    },
    {
      'id': 'cenozoic',
      'title': 'От раптора до колибри',
      'subtitle': 'Динозавры среди нас',
      'image': 'assets/images/routes/Ichthyornis.png',
      'bgColor': const Color.fromARGB(255, 124, 207, 208),
      'totalSteps': 12000,
    },
    {
      'id': 'mammals',
      'title': 'Мир млекопитающих',
      'subtitle': 'Исследуем разнообразие зверей',
      'image': 'assets/images/routes/mammals.png',
      'bgColor': const Color(0xFF5A4E7C),
      'totalSteps': 20000,
    },
    {
      'id': 'cambrian',
      'title': 'Кембрийский взрыв',
      'subtitle': 'Всплеск жизни в океанах',
      'image': 'assets/images/routes/cambrian.png',
      'bgColor': const Color(0xFF6C4C4C),
      'totalSteps': 10000,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.65);
    _loadRouteStates();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // ✅ Убираем close() - больше не нужен
    // _routeRepo?.close();
    super.dispose();
  }

  Future<void> _loadRouteStates() async {
    setState(() => _isLoading = true);
    
    try {
      // ✅ Используем getInstance() вместо конструктора
      _routeRepo = await RouteStateRepository.getInstance();
      
      final completed = await _routeRepo!.getCompletedRouteIds();
      final active = await _routeRepo!.getActiveRoute();
      
      // ✅ Используем getInstance() вместо init()
      final stepsRepo = await DailyStepsRepository.getInstance();
      Map<String, int> progress = {};
      
      for (final route in routes) {
        final routeId = route['id'] as String;
        final totalSteps = await stepsRepo.getTotalStepsForRoute(routeId);
        final maxSteps = route['totalSteps'] as int;
        
        if (maxSteps > 0) {
          int percent = ((totalSteps / maxSteps) * 100).toInt();
          percent = percent.clamp(0, 100);
          progress[routeId] = percent;
        } else {
          progress[routeId] = 0;
        }
      }
      
      // ✅ Убираем close() - больше не нужно
      // await stepsRepo.close();
      
      if (mounted) {
        setState(() {
          _completedRoutes = completed;
          _activeRoute = active;
          _routeProgress = progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading route states: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToRoute(int index) async {
    final route = routes[index];
    final routeId = route['id'] as String;
    final isCompleted = _completedRoutes.contains(routeId);
    final isActive = _activeRoute?.routeId == routeId;
    
    // Если маршрут уже пройден
    if (isCompleted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Этот маршрут уже пройден! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }
    
    // Если маршрут активен — просто открываем
    if (isActive) {
      _openRouteScreen(index);
      return;
    }
    
    // Если выбран другой активный маршрут
    if (_activeRoute != null) {
      final shouldSwitch = await _showSwitchRouteDialog();
      if (shouldSwitch != true) return;
      
      await _routeRepo?.clearActiveRoute();
    }
    
    // Устанавливаем новый активный маршрут
    await _routeRepo?.setActiveRoute(routeId);
    
    // Обновляем состояние
    await _loadRouteStates();
    
    // Открываем маршрут
    _openRouteScreen(index);
  }
  
  Future<bool?> _showSwitchRouteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Сменить маршрут?'),
        content: Text(
          'Вы уже проходите другой маршрут. '
          'Прогресс по нему сохранится, но активным станет новый маршрут.\n\n'
          'Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('Сменить'),
          ),
        ],
      ),
    );
  }

  void _openRouteScreen(int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = const JurassicScreen();
        break;
      case 1:
        screen = const WhaleScreen();
        break;
      case 2:
        screen = const CenozoicScreen();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Этот маршрут пока в разработке!')),
        );
        return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      // Обновляем состояние после возврата
      _loadRouteStates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: routes.length,
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        final routeId = route['id'] as String;
                        final isActive = _activeRoute?.routeId == routeId;
                        final isCompleted = _completedRoutes.contains(routeId);
                        final progressPercent = _routeProgress[routeId];
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 35),
                          child: RouteCard(
                            title: route['title'] as String,
                            subtitle: route['subtitle'] as String,
                            imagePath: route['image'] as String,
                            color: route['bgColor'] as Color,
                            isActive: isActive,
                            isCompleted: isCompleted,
                            progressPercent: progressPercent,
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