// lib/data/daily_steps_repository.dart

import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DailyStepsStat {
  DailyStepsStat({
    required this.date,
    required this.totalSteps,
    required this.stepsByRoute,
    required this.hourlySteps,
    required this.updatedAt,
  });

  final DateTime date;
  final int totalSteps;
  final Map<String, int> stepsByRoute;
  final Map<int, int> hourlySteps;
  final DateTime updatedAt;
}

class DailyStepsRepository {
  DailyStepsRepository(this._db);

  final Database _db;

  static const _table = 'daily_steps';

  static Future<DailyStepsRepository> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'darwin_steps.db');

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion == 1) {
          await db.execute('ALTER TABLE $_table ADD COLUMN hourlyStepsJson TEXT');
          await db.execute('''
            UPDATE $_table 
            SET hourlyStepsJson = '{"0":0,"1":0,"2":0,"3":0,"4":0,"5":0,"6":0,"7":0,"8":0,"9":0,"10":0,"11":0,"12":0,"13":0,"14":0,"15":0,"16":0,"17":0,"18":0,"19":0,"20":0,"21":0,"22":0,"23":0}'
            WHERE hourlyStepsJson IS NULL
          ''');
        }
      },
    );

    return DailyStepsRepository(db);
  }

  static Future<void> _createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_table (
        dayKey INTEGER PRIMARY KEY,
        date TEXT NOT NULL,
        totalSteps INTEGER NOT NULL,
        stepsByRouteJson TEXT NOT NULL,
        hourlyStepsJson TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  static int _dayKeyFromDate(DateTime d) =>
      d.year * 10000 + d.month * 100 + d.day;

  static Map<int, int> _createEmptyHourlyMap() {
    return {for (var i = 0; i < 24; i++) i: 0};
  }

  // ✅ Вспомогательный метод: Map<int, int> → Map<String, int> для JSON
  static Map<String, int> _encodeHourlyMap(Map<int, int> map) {
    return map.map((k, v) => MapEntry(k.toString(), v));
  }

  // ✅ Вспомогательный метод: Map<String, dynamic> → Map<int, int> из JSON
  static Map<int, int> _decodeHourlyMap(String? jsonStr) {
    if (jsonStr == null) return _createEmptyHourlyMap();
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
    } catch (_) {
      return _createEmptyHourlyMap();
    }
  }

  Future<Map<String, dynamic>?> _getRawForDate(DateTime date) async {
    final local = DateTime(date.year, date.month, date.day);
    final dayKey = _dayKeyFromDate(local);

    final rows = await _db.query(
      _table,
      where: 'dayKey = ?',
      whereArgs: [dayKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  DailyStepsStat _mapRow(Map<String, dynamic> row) {
    final date = DateTime.parse(row['date'] as String);
    final updatedAt = DateTime.parse(row['updatedAt'] as String);
    
    final routeMap = (jsonDecode(row['stepsByRouteJson'] as String)
            as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toInt()));

    final hourlySteps = _decodeHourlyMap(row['hourlyStepsJson'] as String?);

    return DailyStepsStat(
      date: date,
      totalSteps: row['totalSteps'] as int,
      stepsByRoute: routeMap,
      hourlySteps: hourlySteps,
      updatedAt: updatedAt,
    );
  }

  Future<void> addSteps({
    required DateTime date,
    required int stepsDelta,
    required String routeId,
  }) async {
    if (stepsDelta <= 0) return;

    await _db.transaction((txn) async {
      final local = DateTime(date.year, date.month, date.day);
      final dayKey = _dayKeyFromDate(local);
      final hour = date.hour;

      final rows = await txn.query(
        _table,
        where: 'dayKey = ?',
        whereArgs: [dayKey],
        limit: 1,
      );

      final now = DateTime.now();

      late Map<String, dynamic> row;
      if (rows.isEmpty) {
        row = <String, dynamic>{
          'dayKey': dayKey,
          'date': local.toIso8601String(),
          'totalSteps': 0,
          'stepsByRouteJson': jsonEncode(<String, int>{}),
          'hourlyStepsJson': jsonEncode(_encodeHourlyMap(_createEmptyHourlyMap())),
          'updatedAt': now.toIso8601String(),
        };
        await txn.insert(_table, row);
      } else {
        row = rows.first;
      }

      final currentTotal = (row['totalSteps'] as int?) ?? 0;
      
      final routeMap = (jsonDecode(row['stepsByRouteJson'] as String)
              as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt()));

      // ✅ Декодируем почасовые данные
      final hourlyMap = _decodeHourlyMap(row['hourlyStepsJson'] as String?);
      
      // Обновляем нужный час
      hourlyMap[hour] = (hourlyMap[hour] ?? 0) + stepsDelta;

      final currentRouteSteps = routeMap[routeId] ?? 0;
      routeMap[routeId] = currentRouteSteps + stepsDelta;

      final updated = <String, dynamic>{
        'totalSteps': currentTotal + stepsDelta,
        'stepsByRouteJson': jsonEncode(routeMap),
        // ✅ Кодируем Map<int, int> → Map<String, int> перед сохранением
        'hourlyStepsJson': jsonEncode(_encodeHourlyMap(hourlyMap)),
        'updatedAt': now.toIso8601String(),
      };

      await txn.update(
        _table,
        updated,
        where: 'dayKey = ?',
        whereArgs: [dayKey],
      );
    });
  }

  Future<DailyStepsStat?> getForDate(DateTime date) async {
    final row = await _getRawForDate(date);
    if (row == null) return null;
    return _mapRow(row);
  }

  Future<List<DailyStepsStat>> getRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final f = DateTime(from.year, from.month, from.day);
    final t = DateTime(to.year, to.month, to.day);
    final fromKey = _dayKeyFromDate(f);
    final toKey = _dayKeyFromDate(t);

    final rows = await _db.query(
      _table,
      where: 'dayKey BETWEEN ? AND ?',
      whereArgs: [fromKey, toKey],
      orderBy: 'dayKey ASC',
    );

    return rows.map(_mapRow).toList();
  }

  Future<void> clearAll() async {
    await _db.delete(_table);
  }

  Future<void> close() async {
    await _db.close();
  }
}