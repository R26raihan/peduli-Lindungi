import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheProvider extends ChangeNotifier {
  Map<String, dynamic>? cachedData;

  Future<void> loadCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedString = prefs.getString('cachedTweets');
    if (cachedString != null) {
      cachedData = json.decode(cachedString);
    }
    notifyListeners();
  }

  Future<void> saveCache(String key, Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
    cachedData = data;
    notifyListeners();
  }

  Map<String, dynamic>? getCache(String key) {
    return cachedData;
  }
}
