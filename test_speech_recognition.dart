import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Test pentru speech recognition și TTS
class SpeechRecognitionTest extends StatefulWidget {
  const SpeechRecognitionTest({super.key});

  @override
  State<SpeechRecognitionTest> createState() => _SpeechRecognitionTestState();
}

class _SpeechRecognitionTestState extends State<SpeechRecognitionTest> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  String _lastWords = '';
  String _status = 'Gata să testez';
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
  }
  
  Future<void> _initSpeech() async {
    try {
      final available = await _speechToText.initialize(
        onError: (error) {
          debugPrint('🎤 [TEST] Speech Error: ${error.errorMsg}');
          setState(() => _status = 'Eroare: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('🎤 [TEST] Speech Status: $status');
          setState(() => _status = 'Status: $status');
        },
      );
      
      if (available) {
        setState(() => _status = 'Speech recognition disponibil');
      } else {
        setState(() => _status = 'Speech recognition indisponibil');
      }
    } catch (e) {
      debugPrint('🎤 [TEST] Init failed: $e');
      setState(() => _status = 'Eroare inițializare: $e');
    }
  }
  
  Future<void> _startListening() async {
    try {
      setState(() => _isListening = true);
      
      await _speechToText.listen(
        onResult: (result) {
          debugPrint('🎤 [TEST] Result: ${result.recognizedWords}');
          setState(() => _lastWords = result.recognizedWords);
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(milliseconds: 500),
        localeId: 'ro-RO',
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.confirmation,
        ),
      );
    } catch (e) {
      debugPrint('🎤 [TEST] Listen failed: $e');
      setState(() => _status = 'Eroare ascultare: $e');
    }
  }
  
  Future<void> _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } catch (e) {
      debugPrint('🎤 [TEST] Stop failed: $e');
    }
  }
  
  Future<void> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
      setState(() => _status = 'Vorbesc: $text');
    } catch (e) {
      debugPrint('🎤 [TEST] Speak failed: $e');
      setState(() => _status = 'Eroare vorbire: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Test Speech Recognition'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Butoane de control
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isListening ? null : _startListening,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('🎤 Ascultă'),
                ),
                
                ElevatedButton(
                  onPressed: _isListening ? _stopListening : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('⏹️ Oprește'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Test TTS
            ElevatedButton(
              onPressed: () => _speak('Test speech recognition. Unde doriți să mergeți?'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('🔊 Test TTS'),
            ),
            
            const SizedBox(height: 20),
            
            // Rezultatul
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎯 Rezultatul recunoașterii:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastWords.isEmpty ? 'Încă nu s-a recunoscut nimic...' : _lastWords,
                    style: TextStyle(
                      fontSize: 18,
                      color: _lastWords.isEmpty ? Colors.grey : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Instrucțiuni
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Instrucțiuni de testare:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Apasă "🎤 Ascultă" pentru a începe'),
                  Text('2. Spune o destinație (ex: "Vreau să merg la centru")'),
                  Text('3. Apasă "⏹️ Oprește" când ai terminat'),
                  Text('4. Verifică rezultatul în caseta de jos'),
                  Text('5. Testează TTS cu butonul "🔊 Test TTS"'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }
}

void main() {
  runApp(const MaterialApp(
    home: SpeechRecognitionTest(),
    debugShowCheckedModeBanner: false,
  ));
}
