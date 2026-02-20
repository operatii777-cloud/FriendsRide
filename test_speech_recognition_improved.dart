import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Test îmbunătățit pentru speech recognition și TTS
class SpeechRecognitionTestImproved extends StatefulWidget {
  const SpeechRecognitionTestImproved({super.key});

  @override
  State<SpeechRecognitionTestImproved> createState() => _SpeechRecognitionTestImprovedState();
}

class _SpeechRecognitionTestImprovedState extends State<SpeechRecognitionTestImproved> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  String _lastWords = '';
  String _status = 'Gata să testez';
  final List<String> _debugLogs = [];
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
  }
  
  void _addDebugLog(String message) {
    setState(() {
      _debugLogs.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_debugLogs.length > 20) {
        _debugLogs.removeAt(0);
      }
    });
    debugPrint('🎤 [TEST] $message');
  }
  
  Future<void> _initSpeech() async {
    try {
      _addDebugLog('Initializing speech recognition...');
      
      final available = await _speechToText.initialize(
        onError: (error) {
          _addDebugLog('❌ ERROR: ${error.errorMsg} - Permanent: ${error.permanent}');
          setState(() => _status = 'Eroare: ${error.errorMsg}');
        },
        onStatus: (status) {
          _addDebugLog('📊 STATUS: $status');
          setState(() => _status = 'Status: $status');
        },
      );
      
      if (available) {
        _addDebugLog('✅ Speech recognition disponibil');
        setState(() => _status = 'Speech recognition disponibil');
      } else {
        _addDebugLog('❌ Speech recognition indisponibil');
        setState(() => _status = 'Speech recognition indisponibil');
      }
    } catch (e) {
      _addDebugLog('❌ Init failed: $e');
      setState(() => _status = 'Eroare inițializare: $e');
    }
  }
  
  Future<void> _startListening() async {
    try {
      setState(() => _isListening = true);
      _addDebugLog('🎤 Starting speech recognition...');
      
      await _speechToText.listen(
        onResult: (result) {
          _addDebugLog('🎯 RESULT: "${result.recognizedWords}" (Final: ${result.finalResult})');
          setState(() => _lastWords = result.recognizedWords);
        },
        listenFor: const Duration(seconds: 15), // *** ÎMBUNĂTĂȚIT: Durată mai lungă ***
        pauseFor: const Duration(seconds: 5),   // *** ÎMBUNĂTĂȚIT: Pauză mai lungă ***
        localeId: 'ro_RO',                      // *** ÎMBUNĂTĂȚIT: Forțez locale română ***
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.confirmation,
        ),
      );
      
      _addDebugLog('✅ Listen started successfully');
    } catch (e) {
      _addDebugLog('❌ Listen failed: $e');
      setState(() => _status = 'Eroare ascultare: $e');
    }
  }
  
  Future<void> _stopListening() async {
    try {
      _addDebugLog('⏹️ Stopping speech recognition...');
      await _speechToText.stop();
      setState(() => _isListening = false);
      _addDebugLog('✅ Speech recognition stopped');
    } catch (e) {
      _addDebugLog('❌ Stop failed: $e');
    }
  }
  
  Future<void> _speak(String text) async {
    try {
      _addDebugLog('🔊 Speaking: "$text"');
      await _flutterTts.speak(text);
      setState(() => _status = 'Vorbesc: $text');
    } catch (e) {
      _addDebugLog('❌ Speak failed: $e');
      setState(() => _status = 'Eroare vorbire: $e');
    }
  }
  
  void _clearLogs() {
    setState(() => _debugLogs.clear());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Test Speech Recognition Îmbunătățit'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Curăță log-urile',
          ),
        ],
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
                  child: const Text('🎤 Ascultă (15s)'),
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
              onPressed: () => _speak('Test speech recognition îmbunătățit. Unde doriți să mergeți?'),
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
            
            // Debug Logs
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📋 Debug Logs:',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_debugLogs.length}/20',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _debugLogs.length,
                      itemBuilder: (context, index) {
                        final log = _debugLogs[_debugLogs.length - 1 - index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
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
                    '📋 Instrucțiuni de testare îmbunătățite:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Apasă "🎤 Ascultă (15s)" pentru a începe'),
                  Text('2. Spune o destinație clară (ex: "Vreau să merg la centru")'),
                  Text('3. Așteaptă până se oprește automat sau apasă "⏹️ Oprește"'),
                  Text('4. Verifică rezultatul și debug logs-urile'),
                  Text('5. Testează TTS cu butonul "🔊 Test TTS"'),
                  Text('6. Folosește butonul 🗑️ pentru a curăța log-urile'),
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
    home: SpeechRecognitionTestImproved(),
    debugShowCheckedModeBanner: false,
  ));
}
