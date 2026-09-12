import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool isEnabled = false; // Only true if user is visually impaired
  String _currentLanguage = 'en-US'; // US or UK English generally have much higher quality TTS models

  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    if (_isInitialized) return;
    
    await _flutterTts.setLanguage(_currentLanguage);
    
    // Adjust rate and pitch for a more natural, human-like cadence
    await _flutterTts.setSpeechRate(0.45); 
    await _flutterTts.setPitch(1.1);

    // Try to find a high-quality "network" voice (which sounds much more human than offline robotic ones)
    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        List<Map<String, String>> availableVoices = [];
        for (var voice in voices) {
          availableVoices.add(Map<String, String>.from(voice));
        }
        
        // Look for a network/premium voice in the current language
        Map<String, String>? bestVoice;
        final langPrefix = _currentLanguage.split('-').first.toLowerCase();
        for (var voice in availableVoices) {
          final loc = voice["locale"]?.toLowerCase() ?? "";
          if (loc.startsWith(langPrefix)) {
            String name = voice["name"]?.toLowerCase() ?? "";
            if (name.contains("network") || name.contains("sfg") || name.contains("premium")) {
              bestVoice = voice;
              break;
            }
            bestVoice ??= voice;
          }
        }
        
        if (bestVoice != null) {
          await _flutterTts.setVoice({"name": bestVoice["name"]!, "locale": bestVoice["locale"]!});
        }
      }
    } catch (e) {
      // Fallback to default if voice fetching fails
    }
    
    await _flutterTts.setVolume(1.0);
    _isInitialized = true;
  }

  Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    await init();
    final isAvailable = await _flutterTts.isLanguageAvailable(langCode) as bool? ?? false;
    if (isAvailable) {
      await _flutterTts.setLanguage(langCode);
      try {
        final voices = await _flutterTts.getVoices;
        if (voices != null) {
          final prefix = langCode.split('-').first.toLowerCase();
          for (var voice in voices) {
            final vMap = Map<String, String>.from(voice);
            final loc = vMap["locale"]?.toLowerCase() ?? "";
            if (loc.startsWith(prefix)) {
              await _flutterTts.setVoice({"name": vMap["name"]!, "locale": vMap["locale"]!});
              break;
            }
          }
        }
      } catch (_) {}
    } else {
      await _flutterTts.setLanguage('en-US');
    }
  }

  Future<void> speak(String text, {bool force = false}) async {
    if (!isEnabled && !force) return;
    await init();
    
    final isAvailable = await _flutterTts.isLanguageAvailable(_currentLanguage) as bool? ?? false;
    if (!isAvailable && !_currentLanguage.startsWith('en')) {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.speak("Note: Selected language voice is not available. $text");
      await _flutterTts.setLanguage(_currentLanguage); // restore setting
    } else {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
