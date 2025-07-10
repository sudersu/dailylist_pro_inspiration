import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/app_settings.dart';

class StorageService {
  static const String _tasksKey = 'tasks';
  static const String _settingsKey = 'settings';

  // Get SharedPreferences instance
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Save tasks to local storage
  static Future<void> saveTasks(List<Task> tasks) async {
    try {
      final prefs = await _prefs;
      final String tasksJson = jsonEncode(
        tasks.map((task) => task.toJson()).toList(),
      );
      await prefs.setString(_tasksKey, tasksJson);
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  // Load tasks from local storage
  static Future<List<Task>> loadTasks() async {
    try {
      final prefs = await _prefs;
      final String? tasksJson = prefs.getString(_tasksKey);
      
      if (tasksJson == null) {
        return [];
      }

      final List<dynamic> tasksList = jsonDecode(tasksJson);
      return tasksList
          .map((taskMap) => Task.fromJson(taskMap as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading tasks: $e');
      return [];
    }
  }

  // Save app settings to local storage
  static Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await _prefs;
      final String settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  // Load app settings from local storage
  static Future<AppSettings> loadSettings() async {
    try {
      final prefs = await _prefs;
      final String? settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson == null) {
        return AppSettings.defaultSettings;
      }

      final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
      return AppSettings.fromJson(settingsMap);
    } catch (e) {
      print('Error loading settings: $e');
      return AppSettings.defaultSettings;
    }
  }

  // Clear all data (useful for testing or reset)
  static Future<void> clearAll() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_tasksKey);
      await prefs.remove(_settingsKey);
    } catch (e) {
      print('Error clearing storage: $e');
    }
  }

  // Check if tasks exist in storage
  static Future<bool> hasData() async {
    try {
      final prefs = await _prefs;
      return prefs.containsKey(_tasksKey);
    } catch (e) {
      print('Error checking storage: $e');
      return false;
    }
  }
}