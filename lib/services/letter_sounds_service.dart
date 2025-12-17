import 'dart:convert';
import 'package:http/http.dart' as http;

class LetterSoundsService {
  static const String baseUrl = 'http://10.0.2.2:4000/api';

  /// Fetch all letter sounds from the backend
  static Future<List<LetterSound>> fetchLetterSounds() async {
    final url = Uri.parse('$baseUrl/letter-sounds');
    print('📡 GET Request URL: $url');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    print('📥 Response Status: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode != 200) {
      try {
        final body = json.decode(response.body);
        final message = body['message'] ?? 'Failed to load letter sounds';
        throw Exception(message);
      } catch (e) {
        throw Exception('Failed to load letter sounds: ${response.statusCode}');
      }
    }

    try {
      final body = json.decode(response.body);
      print('📥 Parsed Body: $body');
      print('📥 Body type: ${body.runtimeType}');
      
      // Handle different response structures
      List<dynamic> data = [];
      
      if (body is Map<String, dynamic>) {
        // Check if 'data' field exists
        if (body.containsKey('data')) {
          final dataValue = body['data'];
          print('📥 Data value type: ${dataValue.runtimeType}');
          
          if (dataValue is List) {
            data = dataValue;
          } else if (dataValue is Map) {
            // If data is a Map, convert values to list
            print('⚠️ Data is Map, converting to list');
            data = dataValue.values.toList();
          } else {
            print('⚠️ Unexpected data type: ${dataValue.runtimeType}');
            throw Exception('Data field is not a list or map');
          }
        } else {
          // If no 'data' field, check if body itself is a list
          print('⚠️ No data field found, checking if body is list');
          throw Exception('No data field in response');
        }
      } else if (body is List) {
        data = body;
      } else {
        print('⚠️ Unexpected response structure: ${body.runtimeType}');
        throw Exception('Unexpected response structure from backend');
      }
      
      print('📥 Data list length: ${data.length}');
      print('📥 Data list type: ${data.runtimeType}');
      
      if (data.isEmpty) {
        print('⚠️ Empty data list received');
        return [];
      }
      
      final letters = <LetterSound>[];
      final errors = <String>[];
      
      for (int i = 0; i < data.length; i++) {
        try {
          final item = data[i];
          print('📥 Parsing letter at index $i');
          print('📥 Item type: ${item.runtimeType}');
          print('📥 Item content: $item');
          
          Map<String, dynamic> itemMap;
          
          if (item is Map<String, dynamic>) {
            itemMap = item;
          } else if (item is Map) {
            // Convert Map<dynamic, dynamic> to Map<String, dynamic>
            itemMap = Map<String, dynamic>.from(item);
            print('📥 Converted Map to Map<String, dynamic>');
          } else {
            final error = 'Item at index $i is not a Map: ${item.runtimeType}';
            print('❌ $error');
            errors.add(error);
            continue;
          }
          
          print('📥 Item keys: ${itemMap.keys.toList()}');
          print('📥 Calling LetterSound.fromJson...');
          
          final letter = LetterSound.fromJson(itemMap);
          
          if (letter.letter.isEmpty) {
            final error = 'Letter at index $i has empty letter field';
            print('⚠️ $error');
            errors.add(error);
            continue;
          }
          
          letters.add(letter);
          print('✅ Successfully parsed letter at index $i: "${letter.letter}"');
          
        } catch (e, stackTrace) {
          final error = 'Error parsing letter at index $i: $e';
          print('❌ $error');
          print('❌ Stack trace: $stackTrace');
          errors.add(error);
        }
      }
      
      // Print all errors if any
      if (errors.isNotEmpty) {
        print('❌ Parsing errors summary:');
        for (var error in errors) {
          print('   - $error');
        }
      }
      
      print('✅ Successfully parsed ${letters.length} letters out of ${data.length} items');
      
      // Debug: Print all parsed letters
      if (letters.isNotEmpty) {
        print('📋 Parsed letters:');
        for (var letter in letters) {
          print('  - Letter: "${letter.letter}", Order: ${letter.order}, Difficulty: ${letter.difficulty}, Level: ${letter.difficultyLevel}');
        }
      } else {
        print('⚠️ No letters were successfully parsed!');
        print('⚠️ This means all items failed to parse. Check the logs above for parsing errors.');
        if (data.isNotEmpty) {
          print('⚠️ First item structure: ${data[0]}');
        }
      }
      
      // If no letters were parsed but we have data, throw an error
      if (letters.isEmpty && data.isNotEmpty) {
        throw Exception('Failed to parse any letters from ${data.length} items. Check backend data structure.');
      }
      
      return letters;
    } catch (e, stackTrace) {
      print('❌ Error parsing response: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }
}

class LetterSound {
  final String letter;
  final int order;
  final String difficulty; // "easy" | "medium" | "hard"
  final int difficultyLevel; // 1 | 2 | 3
  final LetterSounds sounds;

  LetterSound({
    required this.letter,
    required this.order,
    required this.difficulty,
    required this.difficultyLevel,
    required this.sounds,
  });

  factory LetterSound.fromJson(Map<String, dynamic> json) {
    print('📥 LetterSound.fromJson: json keys: ${json.keys.toList()}');
    print('📥 LetterSound.fromJson: letter=${json['letter']}, order=${json['order']}, order type: ${json['order']?.runtimeType}');
    
    // Get letter - try multiple field names
    String letter = '';
    if (json['letter'] != null) {
      letter = json['letter'].toString().trim();
    } else if (json['char'] != null) {
      letter = json['char'].toString().trim();
    } else if (json['character'] != null) {
      letter = json['character'].toString().trim();
    }
    
    if (letter.isEmpty) {
      print('⚠️ Letter is empty! Available fields: ${json.keys.toList()}');
      print('⚠️ Full JSON object: $json');
      // Try to find any field that might contain the letter
      for (var key in json.keys) {
        final value = json[key];
        if (value is String && value.length == 1 && RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
          print('⚠️ Found potential letter in field "$key": "$value"');
          letter = value;
          break;
        }
      }
    }
    
    // Safe conversion for order
    int order = 0;
    if (json['order'] != null) {
      if (json['order'] is int) {
        order = json['order'] as int;
      } else if (json['order'] is String) {
        order = int.tryParse(json['order'] as String) ?? 0;
      } else if (json['order'] is num) {
        order = (json['order'] as num).toInt();
      }
    }
    
    // Safe conversion for difficultyLevel
    int difficultyLevel = 1;
    final difficultyLevelValue = json['difficultyLevel'] ?? json['difficulty_level'];
    if (difficultyLevelValue != null) {
      if (difficultyLevelValue is int) {
        difficultyLevel = difficultyLevelValue;
      } else if (difficultyLevelValue is String) {
        difficultyLevel = int.tryParse(difficultyLevelValue) ?? 1;
      } else if (difficultyLevelValue is num) {
        difficultyLevel = difficultyLevelValue.toInt();
      }
    }
    
    // Handle sounds - can be List or Map
    final soundsValue = json['sounds'];
    LetterSounds sounds;
    
    if (soundsValue is List) {
      // Convert List to Map format
      print('📥 Sounds is List, converting to Map format');
      sounds = LetterSounds.fromJsonList(soundsValue);
    } else if (soundsValue is Map) {
      // Already in Map format
      sounds = LetterSounds.fromJson(Map<String, dynamic>.from(soundsValue));
    } else {
      // Empty sounds
      sounds = LetterSounds.fromJson({});
    }
    
    final result = LetterSound(
      letter: letter,
      order: order,
      difficulty: json['difficulty']?.toString() ?? 'easy',
      difficultyLevel: difficultyLevel,
      sounds: sounds,
    );
    
    print('✅ Parsed LetterSound: letter="${result.letter}", order=${result.order}');
    return result;
  }
}

class LetterSounds {
  final String? fatha; // Arabic form with fatha
  final String? kasra; // Arabic form with kasra
  final String? damma; // Arabic form with damma
  final String? sukun; // Arabic form with sukun
  final String? fathaTransliteration; // e.g., "ba"
  final String? kasraTransliteration;
  final String? dammaTransliteration;
  final String? sukunTransliteration;
  final String? fathaAudioUrl;
  final String? kasraAudioUrl;
  final String? dammaAudioUrl;
  final String? sukunAudioUrl;

  LetterSounds({
    this.fatha,
    this.kasra,
    this.damma,
    this.sukun,
    this.fathaTransliteration,
    this.kasraTransliteration,
    this.dammaTransliteration,
    this.sukunTransliteration,
    this.fathaAudioUrl,
    this.kasraAudioUrl,
    this.dammaAudioUrl,
    this.sukunAudioUrl,
  });

  factory LetterSounds.fromJson(Map<String, dynamic> json) {
    return LetterSounds(
      fatha: json['fatha']?.toString(),
      kasra: json['kasra']?.toString(),
      damma: json['damma']?.toString(),
      sukun: json['sukun']?.toString(),
      fathaTransliteration: json['fathaTransliteration']?.toString() ?? 
                           json['fatha_transliteration']?.toString(),
      kasraTransliteration: json['kasraTransliteration']?.toString() ?? 
                           json['kasra_transliteration']?.toString(),
      dammaTransliteration: json['dammaTransliteration']?.toString() ?? 
                           json['damma_transliteration']?.toString(),
      sukunTransliteration: json['sukunTransliteration']?.toString() ?? 
                           json['sukun_transliteration']?.toString(),
      fathaAudioUrl: json['fathaAudioUrl']?.toString() ?? 
                     json['fatha_audio_url']?.toString() ??
                     json['fathaAudio']?.toString() ??
                     json['fatha_audio']?.toString(),
      kasraAudioUrl: json['kasraAudioUrl']?.toString() ?? 
                     json['kasra_audio_url']?.toString() ??
                     json['kasraAudio']?.toString() ??
                     json['kasra_audio']?.toString(),
      dammaAudioUrl: json['dammaAudioUrl']?.toString() ?? 
                     json['damma_audio_url']?.toString() ??
                     json['dammaAudio']?.toString() ??
                     json['damma_audio']?.toString(),
      sukunAudioUrl: json['sukunAudioUrl']?.toString() ?? 
                     json['sukun_audio_url']?.toString() ??
                     json['sukunAudio']?.toString() ??
                     json['sukun_audio']?.toString(),
    );
  }

  /// Parse from List format (backend returns sounds as array)
  factory LetterSounds.fromJsonList(List<dynamic> soundsList) {
    String? fatha, kasra, damma, sukun;
    String? fathaTrans, kasraTrans, dammaTrans, sukunTrans;
    String? fathaAudio, kasraAudio, dammaAudio, sukunAudio;
    
    for (var soundItem in soundsList) {
      if (soundItem is! Map) continue;
      
      final soundMap = Map<String, dynamic>.from(soundItem);
      final type = soundMap['type']?.toString().toLowerCase();
      final arabic = soundMap['arabic']?.toString();
      final latin = soundMap['latin']?.toString();
      final audioUrl = soundMap['audioUrl']?.toString() ?? 
                      soundMap['audio_url']?.toString() ??
                      soundMap['audio']?.toString();
      
      switch (type) {
        case 'fatha':
          fatha = arabic;
          fathaTrans = latin;
          fathaAudio = audioUrl;
          break;
        case 'kasra':
          kasra = arabic;
          kasraTrans = latin;
          kasraAudio = audioUrl;
          break;
        case 'damma':
          damma = arabic;
          dammaTrans = latin;
          dammaAudio = audioUrl;
          break;
        case 'sukun':
          sukun = arabic;
          sukunTrans = latin;
          sukunAudio = audioUrl;
          break;
      }
    }
    
    return LetterSounds(
      fatha: fatha,
      kasra: kasra,
      damma: damma,
      sukun: sukun,
      fathaTransliteration: fathaTrans,
      kasraTransliteration: kasraTrans,
      dammaTransliteration: dammaTrans,
      sukunTransliteration: sukunTrans,
      fathaAudioUrl: fathaAudio,
      kasraAudioUrl: kasraAudio,
      dammaAudioUrl: dammaAudio,
      sukunAudioUrl: sukunAudio,
    );
  }

  /// Get Arabic form for a specific sound type
  String? getArabicForm(String soundType) {
    switch (soundType) {
      case 'fatha':
        return fatha;
      case 'kasra':
        return kasra;
      case 'damma':
        return damma;
      case 'sukun':
        return sukun;
      default:
        return null;
    }
  }

  /// Get transliteration for a specific sound type
  String? getTransliteration(String soundType) {
    switch (soundType) {
      case 'fatha':
        return fathaTransliteration;
      case 'kasra':
        return kasraTransliteration;
      case 'damma':
        return dammaTransliteration;
      case 'sukun':
        return sukunTransliteration;
      default:
        return null;
    }
  }

  /// Get audio URL for a specific sound type
  String? getAudioUrl(String soundType) {
    switch (soundType) {
      case 'fatha':
        return fathaAudioUrl;
      case 'kasra':
        return kasraAudioUrl;
      case 'damma':
        return dammaAudioUrl;
      case 'sukun':
        return sukunAudioUrl;
      default:
        return null;
    }
  }
}

