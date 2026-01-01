
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pdf_forge/core/models/editable_image.dart';
import 'dart:developer' as developer;

class SessionService {
  static const String _sessionKey = 'active_session';

  Future<void> saveSession(List<EditableImage> images) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> imageJsonList = images
          .map((image) => jsonEncode(image.toJson()))
          .toList();
      await prefs.setStringList(_sessionKey, imageJsonList);
    } catch (e, s) {
      developer.log('Error saving session', name: 'com.pdf_forge.session', error: e, stackTrace: s);
    }
  }

  Future<List<EditableImage>> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? imageJsonList = prefs.getStringList(_sessionKey);

      if (imageJsonList == null || imageJsonList.isEmpty) {
        return [];
      }

      final List<EditableImage> images = imageJsonList
          .map((jsonString) => EditableImage.fromJson(jsonDecode(jsonString)))
          .toList();
      
      return images;
    } catch (e, s) {
      developer.log('Error loading session', name: 'com.pdf_forge.session', error: e, stackTrace: s);
      return [];
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (e, s) {
      developer.log('Error clearing session', name: 'com.pdf_forge.session', error: e, stackTrace: s);
    }
  }
}
