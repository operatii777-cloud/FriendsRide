import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/models/gift_ride_model.dart';
import 'package:friendsride_app/services/gift_ride_service.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Ecran pentru trimiterea și gestionarea curselor cadou
class GiftRideScreen extends StatefulWidget {
  const GiftRideScreen({super.key});

  @override
  State<GiftRideScreen> createState() => _GiftRideScreenState();
}

class _GiftRideScreenState extends State<GiftRideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GiftRideService _service = GiftRideService();
  List<GiftRide> _sentGifts = [];
  bool _isLoadingList = true;

  // Form fields
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  double _selectedAmount = 50.0;
  bool _isSending = false;

  static const List<double> _amounts = [20, 30, 50, 75, 100, 150];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSentGifts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSentGifts() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoadingList = false);
      return;
    }
    final gifts = await _service.getUserSentGifts(userId);
    if (mounted) {
      setState(() {
        _sentGifts = gifts;
        _isLoadingList = false;
      });
    }
  }

  Future<void> _sendGift() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final gift = await _service.sendGiftRide(
      recipientName: _nameController.text.trim(),
      recipientEmail: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      recipientPhone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      amount: _selectedAmount,
      message: _messageController.text.trim().isNotEmpty
          ? _messageController.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _isSending = false);

      if (gift != null) {
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _messageController.clear();
        _loadSentGifts();
        _tabController.animateTo(1);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cadoul a fost trimis! Cod: ${gift.code}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eroare la trimiterea cadoului. Încearcă din nou.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cursă Cadou'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.card_giftcard), text: 'Trimite cadou'),
            Tab(icon: Icon(Icons.list_alt), text: 'Cadourile mele'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendForm(),
          _buildSentList(),
        ],
      ),
    );
  }

  Widget _buildSendForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildRecipientCard(),
            const SizedBox(height: 16),
            _buildAmountCard(),
            const SizedBox(height: 16),
            _buildMessageCard(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendGift,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Se trimite...' : 'Trimite cadoul'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: AppTextStyles.buttonLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.card_giftcard, size: 48, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            'Trimite o cursă cadou',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Surprinde pe cineva cu o cursă gratuită!',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destinatar', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Numele destinatarului *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Câmp obligatoriu' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email destinatar',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if ((v == null || v.trim().isEmpty) &&
                    _phoneController.text.trim().isEmpty) {
                  return 'Completați email sau telefon';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon destinatar',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valoare cadou', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _amounts.map((amount) {
                final isSelected = _selectedAmount == amount;
                return ChoiceChip(
                  label: Text('${amount.toInt()} RON'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedAmount = amount),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Valoare selectată: ${_selectedAmount.toInt()} RON',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mesaj personal (opțional)', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Scrie un mesaj pentru destinatar...',
                prefixIcon: Icon(Icons.message_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentList() {
    if (_isLoadingList) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sentGifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.card_giftcard_outlined,
                size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text('Nu ai trimis niciun cadou încă',
                style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Text(
              'Surprinde pe cineva cu o cursă cadou!',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSentGifts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sentGifts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildGiftCard(_sentGifts[index]),
      ),
    );
  }

  Widget _buildGiftCard(GiftRide gift) {
    final statusColor = _statusColor(gift.status);
    final statusLabel = _statusLabel(gift.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.card_giftcard, color: AppColors.primary),
        ),
        title: Text(
          'Pentru: ${gift.recipientName}',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valoare: ${gift.amount.toInt()} RON',
                style: AppTextStyles.bodySmall),
            Text('Cod: ${gift.code}',
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
                color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Color _statusColor(GiftRideStatus status) {
    switch (status) {
      case GiftRideStatus.pending:
        return AppColors.warning;
      case GiftRideStatus.claimed:
        return AppColors.success;
      case GiftRideStatus.expired:
        return AppColors.textDisabled;
      case GiftRideStatus.cancelled:
        return AppColors.error;
    }
  }

  String _statusLabel(GiftRideStatus status) {
    switch (status) {
      case GiftRideStatus.pending:
        return 'În așteptare';
      case GiftRideStatus.claimed:
        return 'Revendicat';
      case GiftRideStatus.expired:
        return 'Expirat';
      case GiftRideStatus.cancelled:
        return 'Anulat';
    }
  }
}
