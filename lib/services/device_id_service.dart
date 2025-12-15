import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const String _deviceIdKey = 'device_id';
  static const Uuid _uuid = Uuid();

  /// Get or create a persistent device ID
  /// Returns the existing device ID if it exists, otherwise generates a new UUID v4
  /// and saves it for future use
  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if device ID already exists
    final existingDeviceId = prefs.getString(_deviceIdKey);
    if (existingDeviceId != null && existingDeviceId.isNotEmpty) {
      return existingDeviceId;
    }
    
    // Generate new UUID v4
    final newDeviceId = _uuid.v4();
    
    // Save it for future use
    await prefs.setString(_deviceIdKey, newDeviceId);
    
    return newDeviceId;
  }
}

