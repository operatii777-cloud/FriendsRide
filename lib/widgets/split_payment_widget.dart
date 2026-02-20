import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/models/split_payment_model.dart';
import 'package:friendsride_app/services/split_payment_service.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';
import 'package:share_plus/share_plus.dart';

/// Widget pentru split payment (împărțirea costului între pasageri)
class SplitPaymentWidget extends StatefulWidget {
  final String rideId;
  final double totalAmount;
  final VoidCallback? onSplitCreated;
  final VoidCallback? onSplitCompleted;

  const SplitPaymentWidget({
    super.key,
    required this.rideId,
    required this.totalAmount,
    this.onSplitCreated,
    this.onSplitCompleted,
  });

  @override
  State<SplitPaymentWidget> createState() => _SplitPaymentWidgetState();
}

class _SplitPaymentWidgetState extends State<SplitPaymentWidget> {
  final SplitPaymentService _splitPaymentService = SplitPaymentService();
  SplitPayment? _currentSplitPayment;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSplitPayment();
  }

  Future<void> _loadSplitPayment() async {
    final split = await _splitPaymentService.getSplitPaymentForRide(widget.rideId);
    if (mounted) {
      setState(() {
        _currentSplitPayment = split;
      });
    }
  }

  Future<void> _createSplitPayment() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Dialog pentru numărul de participanți
    final numberOfSplits = await showDialog<int>(
      context: context,
      builder: (context) => _SplitNumberDialog(),
    );

    if (numberOfSplits == null || numberOfSplits < 2) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final split = await _splitPaymentService.createSplitPayment(
        rideId: widget.rideId,
        totalAmount: widget.totalAmount,
        numberOfSplits: numberOfSplits,
      );

      if (split != null && mounted) {
        setState(() {
          _currentSplitPayment = split;
        });
        widget.onSplitCreated?.call();
        
        // Arată link-ul de partajare
        _showShareDialog(split);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorCreatingSplitPayment(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptSplitPayment() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _currentSplitPayment == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _splitPaymentService.acceptSplitPayment(
        _currentSplitPayment!.id,
        userId,
      );

      if (success && mounted) {
        await _loadSplitPayment();
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.accepted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorAcceptingSplitPayment(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markPaymentCompleted() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _currentSplitPayment == null) return;

    // ✅ IMPLEMENTED: Add payment method selection
    final paymentMethodId = await _showPaymentMethodDialog();
    if (paymentMethodId == null && mounted) {
      // User cancelled
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _splitPaymentService.markPaymentCompleted(
        _currentSplitPayment!.id,
        userId,
        paymentMethodId, // Use selected payment method
      );

      if (success && mounted) {
        await _loadSplitPayment();
        if (!mounted) return;
        if (_currentSplitPayment?.status == SplitPaymentStatus.completed) {
          widget.onSplitCompleted?.call();
        }
        final l10n = AppLocalizations.of(context)!;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.paymentCompleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorCompletingPayment(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show payment method selection dialog
  Future<String?> _showPaymentMethodDialog() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Simple payment methods (can be extended to fetch from Firestore)
    final paymentMethods = [
      {'id': 'cash', 'name': l10n.cash, 'icon': Icons.money},
      {'id': 'card_1', 'name': 'Visa •••• 4242', 'icon': Icons.credit_card},
      {'id': 'card_2', 'name': 'Mastercard •••• 5555', 'icon': Icons.credit_card},
    ];
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectPaymentMethod),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: paymentMethods.map((method) {
            return ListTile(
              leading: Icon(method['icon'] as IconData),
              title: Text(method['name'] as String),
              onTap: () => Navigator.pop(context, method['id'] as String),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(SplitPayment split) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.splitPaymentCreated),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shareLinkWithParticipants),
            const SizedBox(height: 12),
            SelectableText(
              split.shareLink ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (split.shareLink != null) {
                SharePlus.instance.share(ShareParams(text: split.shareLink!));
              }
              Navigator.pop(context);
            },
            child: Text(l10n.share),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentSplitPayment == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.splitPayment,
                    style: AppTextStyles.headingMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.splitPaymentDescription,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createSplitPayment,
                icon: const Icon(Icons.share),
                label: Text(l10n.createSplitPayment),
              ),
            ],
          ),
        ),
      );
    }

    final split = _currentSplitPayment!;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final currentParticipant = split.participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => split.participants.first,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.splitPayment,
                  style: AppTextStyles.headingMedium,
                ),
                const Spacer(),
                _buildStatusChip(split.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildPaymentInfo(split),
            const SizedBox(height: 16),
            _buildParticipantsList(split),
            const SizedBox(height: 16),
            if (!currentParticipant.hasAccepted)
              ElevatedButton(
                onPressed: _acceptSplitPayment,
                child: Text(l10n.acceptSplitPayment),
              )
            else if (!currentParticipant.hasPaid)
              ElevatedButton(
                onPressed: _markPaymentCompleted,
                child: Text(l10n.markAsPaid),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(SplitPaymentStatus status) {
    Color color;
    String text;

    switch (status) {
      case SplitPaymentStatus.pending:
        color = Colors.orange;
        text = AppLocalizations.of(context)!.pending;
        break;
      case SplitPaymentStatus.accepted:
        color = Colors.blue;
        text = AppLocalizations.of(context)!.accepted;
        break;
      case SplitPaymentStatus.completed:
        color = Colors.green;
        text = AppLocalizations.of(context)!.completed;
        break;
      case SplitPaymentStatus.rejected:
        color = Colors.red;
        text = AppLocalizations.of(context)!.rejected;
        break;
      case SplitPaymentStatus.cancelled:
        color = Colors.grey;
        text = AppLocalizations.of(context)!.cancelled;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPaymentInfo(SplitPayment split) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoItem(
          l10n.totalAmount,
          '${split.totalAmount.toStringAsFixed(2)} RON',
        ),
        _buildInfoItem(
          l10n.perPerson,
          '${split.amountPerPerson.toStringAsFixed(2)} RON',
        ),
        _buildInfoItem(
          l10n.participants,
          '${split.participants.length}/${split.numberOfSplits}',
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall,
        ),
      ],
    );
  }

  Widget _buildParticipantsList(SplitPayment split) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.participants,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...split.participants.map((participant) => _buildParticipantItem(participant)),
      ],
    );
  }

  Widget _buildParticipantItem(SplitPaymentParticipant participant) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            participant.hasPaid ? Icons.check_circle : participant.hasAccepted ? Icons.pending : Icons.person_outline,
            color: participant.hasPaid ? Colors.green : participant.hasAccepted ? Colors.blue : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              participant.displayName ?? participant.email ?? participant.phoneNumber ?? l10n.participant,
              style: AppTextStyles.bodySmall,
            ),
          ),
          if (participant.hasPaid)
            Text(
              l10n.paid,
              style: AppTextStyles.labelSmall.copyWith(color: Colors.green),
            )
          else if (participant.hasAccepted)
            Text(
              l10n.accepted,
              style: AppTextStyles.labelSmall.copyWith(color: Colors.blue),
            )
          else
            Text(
              l10n.pending,
              style: AppTextStyles.labelSmall.copyWith(color: Colors.orange),
            ),
        ],
      ),
    );
  }
}

class _SplitNumberDialog extends StatefulWidget {
  @override
  State<_SplitNumberDialog> createState() => _SplitNumberDialogState();
}

class _SplitNumberDialogState extends State<_SplitNumberDialog> {
  int _selectedSplits = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.splitWithHowMany),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.selectNumberOfPeople),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _selectedSplits > 2
                    ? () => setState(() => _selectedSplits--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$_selectedSplits',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _selectedSplits < 10
                    ? () => setState(() => _selectedSplits++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedSplits),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

