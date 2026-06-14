// lib/data/repositories/route_state_repository.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../models/route_progress.dart';
import '../daily_steps_repository.dart';

class RouteStateRepository {
  static RouteStateRepository? _instance;
  static Database? _db;
  
  // ✅ Конструктор для обратной совместимости
  RouteStateRepository() {
    debugPrint('⚠️ RouteStateRepository() constructor called - use getInstance() instead');
  }
  
  // ✅ Метод close для обратной совместимости
  Future<void> close() async {
    debugPrint('⚠️ RouteStateRepository.close() called but DB is not closed (singleton)');
  }
  
  static Future<RouteStateRepository> getInstance() async {
    if (_instance == null) {
      _instance = RouteStateRepository._internal();
      await _instance!._init();
    }
    return _instance!;
  }
  
  RouteStateRepository._internal();
  
  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'darwin_routes.db');
    
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  Database get db {
    if (_db == null) {
      throw Exception('Database not initialized. Call getInstance() first.');
    }
    return _db!;
  }

  static const String _activeTable = 'active_route';
  static const String _completedTable = 'completed_routes';
  
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_activeTable (
        id INTEGER PRIMARY KEY CHECK (id = 0),
        routeId TEXT NOT NULL,
        startedAt TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE $_completedTable (
        routeId TEXT PRIMARY KEY,
        completedAt TEXT NOT NULL,
        totalSteps INTEGER NOT NULL
      )
    ''');
  }
  
  Future<ActiveRoute?> getActiveRoute() async {
    final rows = await db.query(_activeTable, where: 'id = 0');
    if (rows.isEmpty) return null;
    return ActiveRoute.fromMap(rows.first);
  }
  
  Future<void> setActiveRoute(String routeId) async {
    await db.delete(_activeTable, where: 'id = 0');
    await db.insert(_activeTable, {
      'id': 0,
      'routeId': routeId,
      'startedAt': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> clearActiveRoute() async {
    await db.delete(_activeTable, where: 'id = 0');
  }
  
  Future<Set<String>> getCompletedRouteIds() async {
    final rows = await db.query(_completedTable);
    return rows.map((row) => row['routeId'] as String).toSet();
  }
  
  Future<bool> isRouteCompleted(String routeId) async {
    final rows = await db.query(
      _completedTable,
      where: 'routeId = ?',
      whereArgs: [routeId],
    );
    return rows.isNotEmpty;
  }
  
  Future<void> markRouteCompleted(String routeId) async {
    final stepsRepo = await DailyStepsRepository.getInstance();
    final totalSteps = await stepsRepo.getTotalStepsForRoute(routeId);
    
    await db.insert(
      _completedTable,
      {
        'routeId': routeId,
        'completedAt': DateTime.now().toIso8601String(),
        'totalSteps': totalSteps,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    final active = await getActiveRoute();
    if (active?.routeId == routeId) {
      await clearActiveRoute();
    }
  }
}