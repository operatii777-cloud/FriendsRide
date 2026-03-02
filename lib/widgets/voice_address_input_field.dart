import 'dart:async';
import 'package:flutter/material.dart';
import 'package:friendsride_app/widgets/voice_input_button.dart';
import 'package:friendsride_app/services/address_validation_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// 🏠 VoiceAddressInputField - Câmp de input pentru adrese cu microfon și validare în timp real
/// 
/// Caracteristici:
/// - 🎤 Buton de microfon integrat pentru input vocal
/// - ✅ Validare în timp real a adreselor
/// - 📍 Extragerea automată a coordonatelor
/// - 🔍 Sugestii de adrese cu autocompletare
/// - 🎯 Feedback vizual pentru starea validării
/// - 🗺️ Integrare cu butonul de hartă existent
class VoiceAddressInputField extends StatefulWidget {
  /// Controller-ul pentru text
  final TextEditingController controller;
  
  /// Focus node-ul pentru câmp
  final FocusNode? focusNode;
  
  /// Eticheta câmpului
  final String labelText;
  
  /// Iconița prefix
  final IconData? prefixIcon;
  
  /// Dacă este câmpul de pickup (start)
  final bool isStart;
  
  /// Callback pentru când adresa este validată cu succes
  final Function(String address, Point coordinates)? onAddressValidated;
  
  /// Callback pentru când adresa este invalidă
  final Function(String error)? onAddressInvalid;
  
  /// Callback pentru când se apasă butonul de hartă
  final VoidCallback? onMapButtonPressed;
  
  /// Dacă să afișeze sugestiile de adrese
  final bool showSuggestions;
  
  /// Dacă să afișeze feedback-ul vizual pentru validare
  final bool showValidationFeedback;
  
  /// Timeout-ul pentru validare (în secunde)
  final int validationTimeoutSeconds;

  const VoiceAddressInputField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.labelText,
    this.prefixIcon,
    this.isStart = false,
    this.onAddressValidated,
    this.onAddressInvalid,
    this.onMapButtonPressed,
    this.showSuggestions = true,
    this.showValidationFeedback = true,
    this.validationTimeoutSeconds = 8,
  });

  @override
  State<VoiceAddressInputField> createState() => _VoiceAddressInputFieldState();
}

class _VoiceAddressInputFieldState extends State<VoiceAddressInputField> {
  late final AddressValidationService _validationService;
  late final FocusNode _internalFocusNode;
  
  AddressValidationState _validationState = AddressValidationState.idle;
  String? _validationMessage;
  List<AddressSuggestion> _suggestions = [];

  bool _showSuggestions = false;
  
  // Timer pentru debouncing
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _validationService = AddressValidationService();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    
    // Listener pentru schimbările în text
    widget.controller.addListener(_onTextChanged);
    
    // Listener pentru focus
    _internalFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  /// 🔄 Gestionează schimbările în text
  void _onTextChanged() {
    final text = widget.controller.text.trim();
    
    // Resetăm starea dacă textul e gol
    if (text.isEmpty) {
      _resetValidationState();
      return;
    }
    
    // Debouncing pentru validare
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _validateAddress(text);
    });
  }

  /// 🔍 Gestionează schimbările de focus
  void _onFocusChanged() {
    if (_internalFocusNode.hasFocus && widget.controller.text.trim().isNotEmpty) {
      _showSuggestions = true;
      setState(() {});
    } else {
      _showSuggestions = false;
      setState(() {});
    }
  }

  /// ✅ Validează adresa introdusă
  Future<void> _validateAddress(String address) async {
    if (address.length < 3) return;
    
    setState(() {
      _validationState = AddressValidationState.validating;
      _validationMessage = 'Validând adresa...';
    });

    try {
      final result = await _validationService.validateAddress(
        address: address,
        timeoutSeconds: widget.validationTimeoutSeconds,
      );

      if (mounted) {
        setState(() {
          _validationState = result.state;
          _validationMessage = result.message;
          _suggestions = result.suggestions;
        });

        // Gestionează rezultatul
        if (result.isValid && result.coordinates != null) {
          // Adresa validă cu coordonate
          widget.onAddressValidated?.call(result.address!, result.coordinates!);
          
          // Afișează feedback pozitiv
          if (widget.showValidationFeedback) {
            _showSuccessSnackBar('✅ Adresa validată: ${result.address}');
          }
        } else if (result.state == AddressValidationState.needsClarification) {
          // Adresa necesită clarificare - afișează sugestiile
          setState(() {
            _showSuggestions = true;
          });
        } else {
          // Adresa invalidă
          widget.onAddressInvalid?.call(result.message);
          
          if (widget.showValidationFeedback) {
            _showErrorSnackBar('❌ ${result.message}');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationState = AddressValidationState.error;
          _validationMessage = 'Eroare la validare: $e';
        });
        
        widget.onAddressInvalid?.call('Eroare la validare: $e');
      }
    }
  }

  /// 🎤 Gestionează rezultatul input-ului vocal
  void _onVoiceInputResult(String result) {
    // Setează textul în controller
    widget.controller.text = result;
    
    // Validează imediat adresa
    _validateAddress(result);
    
    // Focus pe câmp pentru editare
    _internalFocusNode.requestFocus();
  }

  /// ❌ Gestionează erorile input-ului vocal
  void _onVoiceInputError(String error) {
    if (widget.showValidationFeedback) {
      _showErrorSnackBar('🎤 Eroare la recunoașterea vocală: $error');
    }
  }

  /// 🔄 Resetează starea validării
  void _resetValidationState() {
    setState(() {
      _validationState = AddressValidationState.idle;
      _validationMessage = null;
      _suggestions.clear();
      _showSuggestions = false;
    });
  }

  /// 🎯 Selectează o sugestie de adresă
  void _selectSuggestion(AddressSuggestion suggestion) {
    widget.controller.text = suggestion.description;
    _internalFocusNode.unfocus();
    
    setState(() {
      _showSuggestions = false;
    });
    
    // Validează adresa selectată
    _validateAddress(suggestion.description);
  }

  /// ✅ Afișează un mesaj de succes
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ❌ Afișează un mesaj de eroare
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 🎨 Obține culoarea pentru starea validării
  Color _getValidationColor() {
    switch (_validationState) {
      case AddressValidationState.valid:
        return Colors.green;
      case AddressValidationState.invalid:
      case AddressValidationState.error:
        return Colors.red;
      case AddressValidationState.validating:
        return Colors.orange;
      case AddressValidationState.needsClarification:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// 🎨 Obține iconița pentru starea validării
  IconData _getValidationIcon() {
    switch (_validationState) {
      case AddressValidationState.valid:
        return Icons.check_circle;
      case AddressValidationState.invalid:
      case AddressValidationState.error:
        return Icons.error;
      case AddressValidationState.validating:
        return Icons.hourglass_empty;
      case AddressValidationState.needsClarification:
        return Icons.help;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rând superior: etichetă + butoane voce & hartă
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.labelText,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VoiceInputButton(
                  onSpeechResult: _onVoiceInputResult,
                  onSpeechError: _onVoiceInputError,
                  size: 32,
                  timeoutSeconds: widget.validationTimeoutSeconds,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.map_outlined, color: Colors.grey),
                  tooltip: 'Alege de pe hartă',
                  onPressed: widget.onMapButtonPressed,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Câmpul principal de input cu border permanent
        TextFormField(
          controller: widget.controller,
          focusNode: _internalFocusNode,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _getValidationColor(),
                width: _validationState != AddressValidationState.idle ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _getValidationColor(),
                width: _validationState != AddressValidationState.idle ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _getValidationColor(),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
        
        // Mesajul de validare
        if (widget.showValidationFeedback && _validationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Row(
              children: [
                Icon(
                  _getValidationIcon(),
                  color: _getValidationColor(),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _validationMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getValidationColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Sugestiile de adrese
        if (widget.showSuggestions && _showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.place_outlined, size: 20),
                  title: Text(
                    suggestion.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: suggestion.type != null
                      ? Text(
                          suggestion.type!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        )
                      : null,
                  onTap: () => _selectSuggestion(suggestion),
                  dense: true,
                );
              },
            ),
          ),
      ],
    );
  }
}
