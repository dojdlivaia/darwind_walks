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
    required this.updatedAt,
  });

  final DateTime date;
  final int totalSteps;
  final Map<String, int> stepsByRoute;
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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            dayKey INTEGER PRIMARY KEY,
            date TEXT NOT NULL,
            totalSteps INTEGER NOT NULL,
            stepsByRouteJson TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      },
    );

    return DailyStepsRepository(db);
  }

  static int _dayKeyFromDate(DateTime d) =>
      d.year * 10000 + d.month * 100 + d.day;

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

  Future<void> addSteps({
    required DateTime date,
    required int stepsDelta,
    required String routeId,
  }) async {
    if (stepsDelta <= 0) return;

    await _db.transaction((txn) async {
      final local = DateTime(date.year, date.month, date.day);
      final dayKey = _dayKeyFromDate(local);

      final rows = await txn.query(
        _table,
        where: 'dayKey = ?',
        whereArgs: [dayKey],
        limit: 1,
      );

      final now = DateTime.now();

      late Map<String, dynamic> row;
      if (rows.isEmpty) {
        // создаём новую строку прямо через txn, не трогаем _db
        row = <String, dynamic>{
          'dayKey': dayKey,
          'date': local.toIso8601String(),
          'totalSteps': 0,
          'stepsByRouteJson': jsonEncode(<String, int>{}),
          'updatedAt': now.toIso8601String(),
        };
        await txn.insert(_table, row);
      } else {
        row = rows.first;
      }

      final currentTotal = (row['totalSteps'] as int?) ?? 0;
      final map = (jsonDecode(row['stepsByRouteJson'] as String)
              as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt()));

      final currentRouteSteps = map[routeId] ?? 0;
      map[routeId] = currentRouteSteps + stepsDelta;

      final updated = <String, dynamic>{
        'totalSteps': currentTotal + stepsDelta,
        'stepsByRouteJson': jsonEncode(map),
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

  DailyStepsStat _mapRow(Map<String, dynamic> row) {
    final date = DateTime.parse(row['date'] as String);
    final updatedAt = DateTime.parse(row['updatedAt'] as String);
    final map = (jsonDecode(row['stepsByRouteJson'] as String)
            as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toInt()));

    return DailyStepsStat(
      date: date,
      totalSteps: row['totalSteps'] as int,
      stepsByRoute: map,
      updatedAt: updatedAt,
    );
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