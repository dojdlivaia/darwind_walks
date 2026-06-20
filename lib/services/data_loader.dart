// lib/services/data_loader.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/mammal_node.dart';

class DataLoader {
  static Future<MammalTimelineData> loadMammalsData() async {
    try {
      // Загружаем JSON из assets
      final String jsonString = await rootBundle.loadString(
        'assets/data/mammals_timeline.json',
      );

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return MammalTimelineData.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to load mammals data: $e');
    }
  }
}