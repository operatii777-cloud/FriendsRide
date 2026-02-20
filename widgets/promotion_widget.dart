import 'package:flutter/material.dart';
import 'package:friendsride_app/models/promotion_model.dart';
import 'package:friendsride_app/services/promotion_service.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Widget pentru aplicare cod promoțional
class PromotionWidget extends StatefulWidget {
  final Function(Promotion?)? onPromotionApplied;
  final String? category;
  final double rideAmount;

  const PromotionWidget({
    super.key,
    this.onPromotionApplied,
    this.category,
    required this.rideAmount,
  });

  @override
  State<PromotionWidget> createState() => _PromotionWidgetState();
}

class _PromotionWidgetState extends State<PromotionWidget> {
  final PromotionService _promotionService = PromotionService();
  final _codeController = TextEditingController();
  Promotion? _appliedPromotion;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _applyPromotion() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _promotionService.validateAndApplyPromotion(
        code: code,
        rideAmount: widget.rideAmount,
        category: widget.category,
      );

      if (result['success'] == true && mounted) {
        setState(() {
          _appliedPromotion = result['promotion'] as Promotion?;
          _errorMessage = null;
        });
        widget.onPromotionApplied?.call(_appliedPromotion);
        
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.promotionAppliedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = result['message'] as String? ?? 'Eroare la aplicarea codului';
          _appliedPromotion = null;
        });
        widget.onPromotionApplied?.call(null);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Eroare: ${e.toString()}';
          _appliedPromotion = null;
        });
        widget.onPromotionApplied?.call(null);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _removePromotion() {
    setState(() {
      _appliedPromotion = null;
      _codeController.clear();
      _errorMessage = null;
    });
    widget.onPromotionApplied?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.promotionCode,
                  style: AppTextStyles.headingMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_appliedPromotion == null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        hintText: l10n.enterPromotionCode,
                        border: const OutlineInputBorder(),
                        errorText: _errorMessage,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _applyPromotion,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.apply),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _appliedPromotion!.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_appliedPromotion!.description.isNotEmpty)
                            Text(
                              _appliedPromotion!.description,
                              style: AppTextStyles.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _removePromotion,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

