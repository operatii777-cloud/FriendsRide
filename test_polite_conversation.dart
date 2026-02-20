// Test pentru conversațiile de curtoazie din AIVocabulary
import 'package:flutter/material.dart';
import 'lib/voice/ai/ai_methods.dart';

void main() {
  runApp(const PoliteConversationTestApp());
}

class PoliteConversationTestApp extends StatelessWidget {
  const PoliteConversationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Conversații de Curtoazie',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PoliteConversationTestScreen(),
    );
  }
}

class PoliteConversationTestScreen extends StatefulWidget {
  const PoliteConversationTestScreen({super.key});

  @override
  State<PoliteConversationTestScreen> createState() => _PoliteConversationTestScreenState();
}

class _PoliteConversationTestScreenState extends State<PoliteConversationTestScreen> {
  final TextEditingController _commandController = TextEditingController();
  Map<String, dynamic>? _lastResult;

  // Exemple predefinite de conversații de curtoazie
  final List<String> _testCommands = [
    // Salutări
    'Bună ziua',
    'Bună dimineața',
    'Salut',
    'Hello',
    
    // Mulțumiri
    'Vă mulțumesc',
    'Mulțumesc frumos',
    'Mersi',
    'Thank you',
    
    // Întrebări de curtoazie
    'Unde doriți să mergeți?',
    'Care este destinația dumneavoastră?',
    'Unde vă duc?',
    
    // Oferiri de serviciu
    'Dacă doriți pot să caut alt tip de autoturism',
    'Pot să vă ofer o altă opțiune',
    'Pot să vă ajut cu altceva?',
    'Mai aveți nevoie de ceva?',
    
    // Confirmări
    'Perfect',
    'Foarte bine',
    'Excelent',
    'În regulă',
    
    // Scuze
    'Îmi pare rău',
    'Scuzați-mă',
    'Ne cerem scuze',
    
    // Rămas bun
    'La revedere',
    'Drum bun',
    'Călătorie plăcută',
    'Să aveți o zi frumoasă',
  ];

  void _testCommand(String command) {
    if (command.trim().isEmpty) return;
    
                final result = AIMethods.processVoiceCommand(command);
    setState(() {
      _lastResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤝 Test Conversații de Curtoazie'),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Secțiunea de input manual
            _buildManualInputSection(),
            const SizedBox(height: 24),
            
            // Comenzile predefinite
            _buildPredefinedCommandsSection(),
            const SizedBox(height: 24),
            
            // Rezultatele testului
            if (_lastResult != null) _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInputSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✍️ Test Manual',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commandController,
              decoration: const InputDecoration(
                labelText: 'Introdu o comandă de curtoazie',
                hintText: 'Ex: Bună ziua, mulțumesc, la revedere...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat_bubble_outline),
              ),
              onSubmitted: _testCommand,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _testCommand(_commandController.text),
              icon: const Icon(Icons.send),
              label: const Text('Testează Comanda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredefinedCommandsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Comenzi Predefinite',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Apasă pe o comandă pentru a o testa:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
                          children: _testCommands.map((command) {
              return _buildCommandChip(command);
            }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandChip(String command) {
    return InkWell(
      onTap: () => _testCommand(command),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
        ),
        child: Text(
          command,
          style: const TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Rezultatele Analizei NLU',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 16),
            
            // Intenția recunoscută
            _buildResultRow(
              '🎯 Intenție', 
              _lastResult!['intent'] ?? 'N/A',
              _getIntentColor(_lastResult!['intent']),
            ),
            const SizedBox(height: 8),
            
            // Încrederea
            _buildResultRow(
              '📈 Încredere', 
              '${((_lastResult!['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%',
              _getConfidenceColor(_lastResult!['confidence']),
            ),
            const SizedBox(height: 8),
            
            // Entitățile extrase
            _buildEntitiesSection(),
            const SizedBox(height: 12),
            
            // Răspunsul AI
            _buildResponseSection(),
            const SizedBox(height: 12),
            
            // Sugestiile
            _buildSuggestionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntitiesSection() {
    final entities = _lastResult!['entities'] as Map<String, String>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏷️ Entități Extrase:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        if (entities.isEmpty)
          const Text('Nicio entitate identificată')
        else
          ...entities.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text('• ${entry.key}: ${entry.value}'),
            );
          }),
      ],
    );
  }

  Widget _buildResponseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🤖 Răspuns AI:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Text(
            _lastResult!['response'] ?? 'Fără răspuns',
            style: const TextStyle(
              color: Colors.blue,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsSection() {
    final suggestions = _lastResult!['suggestions'] as List<String>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 Sugestii:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        if (suggestions.isEmpty)
          const Text('Nicio sugestie disponibilă')
        else
          ...suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text('• $suggestion'),
            );
          }),
      ],
    );
  }

  Color _getIntentColor(String? intent) {
    switch (intent) {
      case 'POLITE_CONVERSATION':
        return Colors.green;
      case 'BOOK_RIDE':
        return Colors.blue;
      case 'UNKNOWN_INTENT':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _getConfidenceColor(double? confidence) {
    if (confidence == null) return Colors.grey;
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }
}
