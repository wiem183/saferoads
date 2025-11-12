import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement.dart';

class StorageService {
  static late final SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String getString(String key) => _prefs.getString(key) ?? '';
  static Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  static Future<void> saveAnnouncements(List<Announcement> list) async {
    final json =
        list.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList('announcements', json);
  }

  static List<Announcement> loadAnnouncements() {
    final json = _prefs.getStringList('announcements') ?? [];
    return json.map((s) => Announcement.fromJson(jsonDecode(s))).toList();
  }
}