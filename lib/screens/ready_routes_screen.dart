// lib/screens/ready_routes_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import 'jurassic_screen.dart';
import 'whale_screen.dart';
import 'cenozoic_screen.dart';
import '../widgets/route_card.dart';
import '../widgets/bottom_bar.dart';
import '../data/repositories/route_state_repository.dart';
import '../data/daily_steps_repository.dart';
import '../models/route_progress.dart';
import '../models/jurassic.dart';
import '../models/whale.dart';
import '../models/cenozoic.dart';
import '../services/current_route_manager.dart';

class ReadyRoutesScreen extends StatefulWidget {
  const ReadyRoutesScreen({super.key});

  @override
  State<ReadyRoutesScreen> createState() => _ReadyRoutesScreenState();
}

class _ReadyRoutesScreenState extends State<ReadyRoutesScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  
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
    },
    {
      'id': 'whale',
      'title': 'Назад в океан',
      'subtitle': 'Как оленёнок стал китом',
      'image': 'assets/images/routes/whale.png',
      'bgColor': const Color.fromARGB(255, 235, 183, 25),
    },
    {
      'id': 'cenozoic',
      'title': 'От раптора до колибри',
      'subtitle': 'Динозавры среди нас',
      'image': 'assets/images/routes/Ichthyornis.png',
      'bgColor': const Color.fromARGB(255, 124, 207, 208),
    },
    {
      'id': 'mammals',
      'title': 'Мир млекопитающих',
      'subtitle': 'Исследуем разнообразие зверей',
      'image': 'assets/images/routes/mammals.png',
      'bgColor': const Color(0xFF5A4E7C),
    },
    {
      'id': 'cambrian',
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
    _loadRouteStates();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<int> _getTotalStepsFromJson(String routeId) async {
    try {
      switch (routeId) {
        case 'jurassic':
          final jsonString = await rootBundle.loadString('assets/data/jurassic.json');
          final jsonMap = json.decode(jsonString);
          final data = JurassicData.fromJson(jsonMap);
          return data.totalSteps;
        case 'whale':
          final jsonString = await rootBundle.loadString('assets/data/whale.json');
          final jsonMap = json.decode(jsonString);
          final data = WhaleData.fromJson(jsonMap);
          return data.totalSteps;
        case 'cenozoic':
          final jsonString = await rootBundle.loadString('assets/data/cenozoic.json');
          final jsonMap = json.decode(jsonString);
          final data = CenozoicData.fromJson(jsonMap);
          return data.totalSteps;
        default:
          return 0;
      }
    } catch (e) {
      debugPrint('Error loading total steps for $routeId: $e');
      return 0;
    }
  }

  Future<void> _loadRouteStates() async {
    setState(() => _isLoading = true);
    
    try {
      _routeRepo = await RouteStateRepository.getInstance();
      
      final completed = await _routeRepo!.getCompletedRouteIds();
      final active = await _routeRepo!.getActiveRoute();
      
      final stepsRepo = await DailyStepsRepository.getInstance();
      Map<String, int> progress = {};
      
      for (final route in routes) {
        final routeId = route['id'] as String;
        final totalSteps = await stepsRepo.getTotalStepsForRoute(routeId);
        final maxSteps = await _getTotalStepsFromJson(routeId);
        
        if (maxSteps > 0) {
          int percent = ((totalSteps / maxSteps) * 100).ceil();
          if (totalSteps > 0 && percent == 0) percent = 1;
          percent = percent.clamp(0, 100);
          progress[routeId] = percent;
        } else {
          progress[routeId] = 0;
        }
      }
      
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
    
    if (isCompleted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Этот маршрут уже пройден! 🎉'), backgroundColor: Colors.green),
        );
      }
      return;
    }
    
    if (isActive) {
      _openRouteScreen(index);
      return;
    }
    
    if (_activeRoute != null) {
      final shouldSwitch = await _showSwitchRouteDialog();
      if (shouldSwitch != true) return;
      await _routeRepo?.clearActiveRoute();
      CurrentRouteManager.instance.stopRoute();
    }
    
    await _routeRepo?.setActiveRoute(routeId);
    CurrentRouteManager.instance.startRoute(routeId);
    await _loadRouteStates();
    _openRouteScreen(index);
  }
  
  Future<bool?> _showSwitchRouteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Сменить маршрут?'),
        content: const Text('Вы уже проходите другой маршрут. Прогресс по нему сохранится.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сменить')),
        ],
      ),
    );
  }

  void _openRouteScreen(int index) {
    Widget screen;
    switch (index) {
      case 0: screen = const JurassicScreen(); break;
      case 1: screen = const WhaleScreen(); break;
      case 2: screen = const CenozoicScreen(); break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Этот маршрут пока в разработке!')),
        );
        return;
    }
    
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen)).then((_) {
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
            SizedBox(
              height: 420 + 80,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: routes.length,
                      onPageChanged: (index) => setState(() => _currentPageIndex = index),
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        final routeId = route['id'] as String;
                        final isActive = index == _currentPageIndex;
                        final isRouteSelected = _activeRoute?.routeId == routeId;
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
                            progressPercent: isRouteSelected ? progressPercent : null,
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