import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../voice/passenger/passenger_voice_controller_adapter.dart';
import '../l10n/app_localizations.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  // ✅ NOU: Variabilele redundante eliminate - sistemul vocal este mereu activ
  // bool _isVoiceEnabled = true; // ❌ ELIMINAT
  // bool _isAutoListenEnabled = false; // ❌ ELIMINAT
  double _speechRate = 0.8;
  double _volume = 0.9;
  double _pitch = 1.0;
  String _selectedLanguage = 'ro-RO';
  // bool _isWakeWordEnabled = false; // ❌ ELIMINAT
  // bool _isContinuousListening = false; // ❌ ELIMINAT
  // String _wakeWord = 'Hey FriendsRide'; // ❌ ELIMINAT
  bool _isPrivacyMode = false;
  bool _isAnalyticsEnabled = true;
  bool _isCloudSync = false;

  @override
  void initState() {
    super.initState();
    _loadVoiceSettings();
  }

  Future<void> _loadVoiceSettings() async {
    // Load saved settings from SharedPreferences or other storage
    // For now, using default values
  }

  Future<void> _saveVoiceSettings(BuildContext context) async {
    // Save settings to storage
    // Update voice orchestrator with new settings
    // final voiceController = context.read<PassengerVoiceController>();
    // Metoda updateSettings nu este implementată încă
    // await voiceController.voice.updateSettings(
    //   speechRate: _speechRate,
    //   volume: _volume,
    //   language: _selectedLanguage,
    //   pitch: _pitch,
    // );
    
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.voiceSettingsSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('🎤 ${l10n.voiceSettings}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () => _showAdvancedHelp(),
            tooltip: l10n.advancedHelp,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVoiceStatusCard(),
            SizedBox(height: 24),
            _buildGeneralSettings(),
            SizedBox(height: 24),
            _buildVoicePreferences(),
            SizedBox(height: 24),
            _buildAdvancedVoiceFeatures(),
            SizedBox(height: 24),
            _buildAdvancedSettings(),
            SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceStatusCard() {
    return Consumer<PassengerVoiceControllerAdapter>(
      builder: (context, voiceController, child) {
        final l10n = AppLocalizations.of(context)!;
        final isInitialized = voiceController.isInitialized;
        
        return Card(
          elevation: 4,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isInitialized 
                  ? [Colors.green.shade100, Colors.green.shade50]
                  : [Colors.red.shade100, Colors.red.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isInitialized ? Icons.check_circle : Icons.error,
                      color: isInitialized ? Colors.green : Colors.red,
                      size: 40,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isInitialized ? l10n.voiceSystemActive : l10n.voiceSystemNotActive,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isInitialized ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            isInitialized 
                              ? l10n.canUseVoiceCommands
                              : l10n.checkMicrophonePermissions,
                            style: TextStyle(
                              color: isInitialized ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isInitialized)
                      ElevatedButton(
                        onPressed: () => _initializeVoiceSystem(voiceController),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.activate),
                      ),
                  ],
                ),
                
                if (isInitialized) ...[
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 16),
                  
                  // Voice Features Status
                  Row(
                    children: [
                      _buildFeatureStatus(
                        l10n.basicMode,
                        true, // Always enabled since detectarea "salut" is removed
                        Icons.hearing,
                      ),
                      SizedBox(width: 16),
                      _buildFeatureStatus(
                        l10n.continuous,
                        voiceController.isContinuousListening,
                        Icons.mic,
                      ),
                      SizedBox(width: 16),
                      _buildFeatureStatus(
                        l10n.privacy,
                        _isPrivacyMode,
                        Icons.security,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureStatus(String label, bool isEnabled, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? Colors.green.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isEnabled ? Colors.green : Colors.grey,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isEnabled ? Colors.green.shade700 : Colors.grey.shade600,
              ),
            ),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  isEnabled ? l10n.on : l10n.off,
                  style: TextStyle(
                    fontSize: 10,
                    color: isEnabled ? Colors.green.shade600 : Colors.grey.shade500,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.generalSettings,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                
                // ✅ NOU: Opțiunile redundante eliminate - sistemul vocal este mereu activ
                // SwitchListTile(...) // ❌ ELIMINAT - Activează controlul vocal
                // SwitchListTile(...) // ❌ ELIMINAT - Ascultare automată
                // SwitchListTile(...) // ❌ ELIMINAT - Cuvânt de activare

                SwitchListTile(
                  title: Text(l10n.continuousListening),
                  subtitle: Text(l10n.continuousListeningSubtitle),
                  value: context.watch<PassengerVoiceControllerAdapter>().isContinuousListening,
                  onChanged: (value) {
                    context.read<PassengerVoiceControllerAdapter>().toggleContinuousListening();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoicePreferences() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.voicePreferences,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                
                Text(l10n.speechRate),
                Slider(
                  value: _speechRate,
                  min: 0.5,
                  max: 1.5,
                  divisions: 10,
                  label: _speechRate.toStringAsFixed(1),
                  onChanged: (value) {
                    _safeSetState(() {
                      _speechRate = value;
                    });
                  },
                ),
                Text(
                  l10n.percentOfNormalSpeed((_speechRate * 100).round()),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                
                SizedBox(height: 20),
                
                Text(l10n.volume),
                Slider(
                  value: _volume,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: _volume.toStringAsFixed(1),
                  onChanged: (value) {
                    _safeSetState(() {
                      _volume = value;
                    });
                  },
                ),
                Text(
                  l10n.percentOfMaxVolume((_volume * 100).round()),
                  style: TextStyle(color: Colors.grey[600]),
                ),

                SizedBox(height: 20),
                
                Text(l10n.pitch),
                Slider(
                  value: _pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: _pitch.toStringAsFixed(1),
                  onChanged: (value) {
                    _safeSetState(() {
                      _pitch = value;
                    });
                  },
                ),
                Text(
                  _pitch < 1.0 ? l10n.lowerPitch : _pitch > 1.0 ? l10n.higherPitch : l10n.normalPitch,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                
                SizedBox(height: 20),
                
                Text(l10n.language),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    DropdownMenuItem(value: 'ro-RO', child: Text(l10n.romanian)),
                    DropdownMenuItem(value: 'en-US', child: Text(l10n.english)),
                    DropdownMenuItem(value: 'de-DE', child: Text(l10n.german)),
                    DropdownMenuItem(value: 'fr-FR', child: Text(l10n.french)),
                    DropdownMenuItem(value: 'es-ES', child: Text(l10n.spanish)),
                    DropdownMenuItem(value: 'it-IT', child: Text(l10n.italian)),
                  ],
                  onChanged: (value) {
                    _safeSetState(() {
                      _selectedLanguage = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedVoiceFeatures() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.advancedVoiceFeatures,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                
                SizedBox(height: 20),
                
                // Voice Commands Training
                ListTile(
                  leading: Icon(Icons.school, color: Colors.blue),
                  title: Text(l10n.voiceCommandTraining),
                  subtitle: Text(l10n.voiceCommandTrainingSubtitle),
                  onTap: () => _startVoiceTraining(),
                ),
                
                // Voice Profile
                ListTile(
                  leading: Icon(Icons.person, color: Colors.green),
                  title: Text(l10n.customVoiceProfile),
                  subtitle: Text(l10n.customVoiceProfileSubtitle),
                  onTap: () => _createVoiceProfile(),
                ),
                
                // Multi-language Support
                ListTile(
                  leading: Icon(Icons.language, color: Colors.orange),
                  title: Text(l10n.multiLanguageSupport),
                  subtitle: Text(l10n.multiLanguageSupportSubtitle),
                  onTap: () => _showMultiLanguageSettings(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAdvancedSettings() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.advancedSettings,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                
                ListTile(
                  leading: Icon(Icons.mic),
                  title: Text(l10n.testMicrophone),
                  subtitle: Text(l10n.testMicrophoneSubtitle),
                  onTap: () => _testMicrophone(context),
                ),
                
                ListTile(
                  leading: Icon(Icons.volume_up),
                  title: Text(l10n.testSound),
                  subtitle: Text(l10n.testSoundSubtitle),
                  onTap: () => _testSound(context),
                ),

                ListTile(
                  leading: Icon(Icons.hearing),
                  title: Text(l10n.testRecognition),
                  subtitle: Text(l10n.testRecognitionSubtitle),
                  onTap: () => _testSpeechRecognition(context),
                ),
                
                ListTile(
                  leading: Icon(Icons.help),
                  title: Text(l10n.voiceCommandsHelp),
                  subtitle: Text(l10n.voiceCommandsHelpSubtitle),
                  onTap: () => _showVoiceCommandsHelp(),
                ),
                
                ListTile(
                  leading: Icon(Icons.security),
                  title: Text(l10n.privacySettings),
                  subtitle: Text(l10n.privacySettingsSubtitle),
                  onTap: () => _showPrivacySettings(),
                ),

                ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text(l10n.analyticsAndImprovements),
                  subtitle: Text(l10n.analyticsAndImprovementsSubtitle),
                  onTap: () => _showAnalyticsSettings(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _saveVoiceSettings(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.saveSettings,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Future<void> _initializeVoiceSystem(PassengerVoiceControllerAdapter voiceController) async {
    try {
      await voiceController.initializeVoiceSystem();
      if (!mounted) return;
      
      // Considerăm că inițializarea a avut succes dacă nu a apărut o eroare
      _safeSetState(() {});
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.voiceSystemActivatedSuccessfully)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorActivatingVoiceSystem(e.toString()))),
        );
      }
    }
  }

  Future<void> _testMicrophone(BuildContext context) async {
    if (!mounted) return;
    
    final l10n = AppLocalizations.of(context)!;
    final voiceController = context.read<PassengerVoiceControllerAdapter>();
    if (!voiceController.isInitialized) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.activateVoiceSystemFirst)),
        );
      }
      return;
    }
    
    try {
      await voiceController.voice.speak("Testez microfonul. Spuneți ceva...");
      
      if (!mounted) return;
      
      final result = await voiceController.voice.listen(timeoutSeconds: 5);
      
      if (!mounted) return;
      
      if (result != null) {
        await voiceController.voice.speak("Am auzit: $result. Microfonul funcționează corect!");
      } else {
        await voiceController.voice.speak("Nu am auzit nimic. Verificați microfonul.");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorTestingMicrophone(e.toString()))),
        );
      }
    }
  }

  Future<void> _testSound(BuildContext context) async {
    if (!mounted) return;
    
    final l10n = AppLocalizations.of(context)!;
    final voiceController = context.read<PassengerVoiceControllerAdapter>();
    if (!voiceController.isInitialized) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.activateVoiceSystemFirst)),
        );
      }
      return;
    }
    
    try {
      await voiceController.voice.speak("Testez sunetul. Dacă auziți această frază, sunetul funcționează corect!");
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorTestingSound(e.toString()))),
        );
      }
    }
  }

  Future<void> _testSpeechRecognition(BuildContext context) async {
    if (!mounted) return;
    
    final l10n = AppLocalizations.of(context)!;
    final voiceController = context.read<PassengerVoiceControllerAdapter>();
    if (!voiceController.isInitialized) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.activateVoiceSystemFirst)),
        );
      }
      return;
    }
    
    try {
      await voiceController.voice.speak("Testez recunoașterea vocală. Spuneți o comandă simplă...");
      
      if (!mounted) return;
      
      final result = await voiceController.voice.listen(timeoutSeconds: 10);
      
      if (!mounted) return;
      
      if (result != null) {
        await voiceController.voice.speak("Recunoașterea funcționează! Ați spus: $result");
      } else {
        await voiceController.voice.speak("Nu am putut recunoaște comanda. Verificați setările.");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorTestingRecognition(e.toString()))),
        );
      }
    }
  }

          // void _customizeWakeWord() { // ❌ ELIMINAT - Detectarea "salut" nu este implementată
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('🎤 Personalizare Cuvânt Activare'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text('Introduceți cuvântul de activare dorit:'),
  //           SizedBox(height: 16),
  //           TextField(
  //             decoration: InputDecoration(
  //               hintText: 'Ex: Hey FriendsRide',
  //               border: OutlineInputBorder(),
  //             ),
  //            onChanged: (value) {
  //              _safeSetState(() {
  //                _wakeWord = value;
  //              });
  //            },
  //         ),
  //         SizedBox(height: 16),
  //         Text(
  //           'Sfaturi pentru un cuvânt eficient:',
  //           style: TextStyle(fontWeight: FontWeight.bold),
  //         ),
  //         SizedBox(height: 8),
  //         Text('• 2-4 cuvinte'),
  //         Text('• Ușor de pronunțat'),
  //         Text('• Distinct de conversația normală'),
  //       ],
  //     ),
  //     actions: [
  //       TextButton(
  //         onPressed: () => Navigator.pop(context),
  //         child: Text('Anulează'),
  //       ),
  //            ElevatedButton(
  //        onPressed: () {
  //          Navigator.pop(context);
  //          _safeSetState(() {});
  //        },
  //        child: Text('Salvează'),
  //      ),
  //     ],
  //   ),
  // }

  void _startVoiceTraining() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎓 ${l10n.voiceCommandTrainingTitle}'),
        content: Text(l10n.voiceCommandTrainingContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.later),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                _showVoiceTrainingSteps();
              }
            },
            child: Text(l10n.startTraining),
          ),
        ],
      ),
    );
  }

  void _showVoiceTrainingSteps() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎓 ${l10n.trainingStepsTitle}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.repeatCommand1),
            Text(l10n.repeatCommand2),
            Text(l10n.repeatCommand3),
            Text(l10n.repeatCommand4),
            SizedBox(height: 16),
            Text(
              l10n.trainingWillTakeApprox,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _createVoiceProfile() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('👤 ${l10n.customVoiceProfileTitle}'),
        content: Text(l10n.customVoiceProfileContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.later),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                // Start voice profile creation
              }
            },
            child: Text(l10n.createProfile),
          ),
        ],
      ),
    );
  }

  void _showMultiLanguageSettings() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🌍 ${l10n.multiLanguageSettingsTitle}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.primaryLanguage),
            SizedBox(height: 16),
            Text(l10n.secondaryLanguages),
            CheckboxListTile(
              title: Text(l10n.english),
              value: true,
              onChanged: (value) {
                if (mounted) {
                  // Handle language change
                }
              },
            ),
            CheckboxListTile(
              title: Text(l10n.german),
              value: false,
              onChanged: (value) {
                if (mounted) {
                  // Handle language change
                }
              },
            ),
            CheckboxListTile(
              title: Text(l10n.french),
              value: false,
              onChanged: (value) {
                if (mounted) {
                  // Handle language change
                }
              },
            ),
            SizedBox(height: 16),
            Text(
              l10n.switchBetweenLanguages,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showVoiceCommandsHelp() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎤 ${l10n.availableVoiceCommandsTitle}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.basicCommands, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(l10n.wantRideToDestination),
              Text(l10n.economyRideToDestination),
              Text(l10n.urgentRideToDestination),
              Text(l10n.premiumRideToDestination),
              SizedBox(height: 16),
              Text(l10n.commandsDuringRide, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(l10n.sendMessageToDriver),
              Text(l10n.whereIsDriver),
              Text(l10n.cancelRide),
              Text(l10n.wantToPayCash),
              SizedBox(height: 16),
              Text(l10n.controlCommands, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(l10n.heyFriendsRide),
              Text(l10n.helpCommand),
              Text(l10n.cancelCommand),
              Text(l10n.stopCommand),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔒 ${l10n.privacySettingsTitle}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.privacySettingsLabel, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.saveVoiceHistory),
              subtitle: Text(l10n.saveVoiceHistorySubtitle),
              value: _isPrivacyMode,
              onChanged: (value) {
                _safeSetState(() {
                  _isPrivacyMode = value;
                });
              },
            ),
            SwitchListTile(
              title: Text(l10n.anonymousAnalysis),
              subtitle: Text(l10n.anonymousAnalysisSubtitle),
              value: _isAnalyticsEnabled,
              onChanged: (value) {
                _safeSetState(() {
                  _isAnalyticsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: Text(l10n.cloudSync),
              subtitle: Text(l10n.cloudSyncSubtitle),
              value: _isCloudSync,
              onChanged: (value) {
                _safeSetState(() {
                  _isCloudSync = value;
                });
              },
            ),
            SizedBox(height: 16),
            Text(
              l10n.voiceDataProcessedLocally,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsSettings() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📊 ${l10n.analyticsSettingsTitle}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.analyticsSettingsLabel, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.improveRecognition),
              subtitle: Text(l10n.improveRecognitionSubtitle),
              value: _isAnalyticsEnabled,
              onChanged: (value) {
                _safeSetState(() {
                  _isAnalyticsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: Text(l10n.usageStatistics),
              subtitle: Text(l10n.usageStatisticsSubtitle),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text(l10n.errorReporting),
              subtitle: Text(l10n.errorReportingSubtitle),
              value: true,
              onChanged: (value) {},
            ),
            SizedBox(height: 16),
            Text(
              l10n.allDataAnonymized,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }



  void _showAdvancedHelp() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔧 ${l10n.advancedHelpTitle}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.advancedFeaturesAvailable, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text(l10n.automaticVoiceActivation),
              Text(l10n.customActivationWord),
              Text(l10n.realtimeDetection),
              SizedBox(height: 8),
              Text('🔄 ${l10n.continuousListening}'),
              Text(l10n.continuousListeningForCommands),
              Text(l10n.realtimeProcessing),
              Text(l10n.smartBatterySaving),
              SizedBox(height: 8),
              Text('🌍 ${l10n.multiLanguageSupport}'),
              Text(l10n.supportFor6Languages),
              Text(l10n.voiceSwitchBetweenLanguages),
              Text(l10n.localAccentAdaptation),
              SizedBox(height: 8),
              Text('🔒 ${l10n.privacySecurity}'),
              Text(l10n.localProcessing),
              Text(l10n.endToEndEncryption),
              Text(l10n.fullDataControl),
              SizedBox(height: 16),
              Text(
                l10n.contactSupportForTechnical,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
