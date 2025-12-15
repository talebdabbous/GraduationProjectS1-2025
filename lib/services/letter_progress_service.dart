import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../letter_writing/letter_writing_screen.dart';

/// Service to manage letter writing progress
/// Stores completion status for each letter form (isolated, beginning, middle, end)
class LetterProgressService {
  static const String _keyPrefix = 'letter_progress_';

  /// Mark a letter form as completed
  static Future<void> markFormCompleted(String letter, LetterForm form) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$letter';
    
    // Load existing progress
    final progressJson = prefs.getString(key);
    Map<String, dynamic> progress = {};
    
    if (progressJson != null) {
      progress = json.decode(progressJson) as Map<String, dynamic>;
    }
    
    // Mark this form as completed
    progress[form.name] = true;
    
    // Save back
    await prefs.setString(key, json.encode(progress));
  }

  /// Check if a specific letter form is completed
  static Future<bool> isFormCompleted(String letter, LetterForm form) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$letter';
    
    final progressJson = prefs.getString(key);
    if (progressJson == null) return false;
    
    final progress = json.decode(progressJson) as Map<String, dynamic>;
    return progress[form.name] == true;
  }

  /// Get progress for a specific letter
  /// Returns a map of form -> isCompleted
  static Future<Map<LetterForm, bool>> getLetterProgress(String letter) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$letter';
    
    final progressJson = prefs.getString(key);
    if (progressJson == null) {
      return {
        LetterForm.isolated: false,
        LetterForm.beginning: false,
        LetterForm.middle: false,
        LetterForm.end: false,
      };
    }
    
    final progress = json.decode(progressJson) as Map<String, dynamic>;
    return {
      LetterForm.isolated: progress['isolated'] == true,
      LetterForm.beginning: progress['beginning'] == true,
      LetterForm.middle: progress['middle'] == true,
      LetterForm.end: progress['end'] == true,
    };
  }

  /// Calculate completion percentage for a letter
  /// Takes into account which forms are applicable (some letters don't have middle form)
  /// Returns a value between 0.0 and 100.0
  static Future<double> getCompletionPercentage(String letter, bool hasMiddle) async {
    final progress = await getLetterProgress(letter);
    
    // Count total applicable forms (always: isolated, beginning, end. Middle is conditional)
    final totalForms = hasMiddle ? 4 : 3;
    
    // Count completed forms
    int completedCount = 0;
    if (progress[LetterForm.isolated] == true) completedCount++;
    if (progress[LetterForm.beginning] == true) completedCount++;
    if (progress[LetterForm.end] == true) completedCount++;
    if (hasMiddle && progress[LetterForm.middle] == true) completedCount++;
    
    if (totalForms == 0) return 0.0;
    return (completedCount / totalForms) * 100.0;
  }

  /// Get all letter progress as a map
  static Future<Map<String, Map<LetterForm, bool>>> getAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    
    final result = <String, Map<LetterForm, bool>>{};
    
    for (final key in keys) {
      final letter = key.replaceFirst(_keyPrefix, '');
      result[letter] = await getLetterProgress(letter);
    }
    
    return result;
  }

  /// Clear all progress (for testing/reset)
  static Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

