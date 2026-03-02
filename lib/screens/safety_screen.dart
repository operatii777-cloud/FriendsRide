import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';

import '../helpers/safety_preferences.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  List<TrustedContact> _contacts = const [];
  bool _isLoadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoadingContacts = true;
    });
    final contacts = await SafetyPreferences.loadTrustedContacts();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _isLoadingContacts = false;
    });
  }

  Future<void> _addContact() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10nDialog = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10nDialog.addTrustedContact),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10nDialog.name,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: l10nDialog.phoneNumber,
                  hintText: l10nDialog.phoneNumberExample,
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10nDialog.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    phoneController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: Text(l10nDialog.save),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final contact = TrustedContact(
        name: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
      );
      await SafetyPreferences.addTrustedContact(contact);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.contactSaved(contact.name)),
        ),
      );
      await _loadContacts();
    }
  }

  Future<void> _removeContact(TrustedContact contact) async {
    final l10n = AppLocalizations.of(context)!;
    await SafetyPreferences.removeTrustedContact(contact);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.contactRemoved(contact.name)),
      ),
    );
    await _loadContacts();
  }

  Future<void> _sendTestMessage(TrustedContact contact) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri(
      scheme: 'sms',
      path: contact.phoneNumber,
      queryParameters: <String, String>{
        'body': l10n.testMessageBody,
      },
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.couldNotOpenMessages),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.safetyCenter),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.addContact),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildSafetyFeatureCard(
            context,
            icon: Icons.emergency_outlined,
            title: l10n.emergencyAssistanceButton,
            description: l10n.emergencyAssistanceButtonDesc,
            color: Colors.red.shade400,
          ),
          _buildSafetyFeatureCard(
            context,
            icon: Icons.share_location_outlined,
            title: l10n.tripSharing,
            description: l10n.tripSharingDesc,
            color: Colors.blue.shade400,
          ),
          _buildSafetyFeatureCard(
            context,
            icon: Icons.verified_user_outlined,
            title: l10n.verifiedDrivers,
            description: l10n.verifiedDriversDesc,
            color: Colors.green.shade400,
          ),
          _buildSafetyFeatureCard(
            context,
            icon: Icons.report_problem_outlined,
            title: l10n.reportIncidentTitle,
            description: l10n.reportIncidentDesc,
            color: Colors.orange.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.trustedContacts,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_isLoadingContacts)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ))
          else if (_contacts.isEmpty)
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nu ați adăugat încă persoane de încredere.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adăugați rapid familia sau prietenii care vor primi notificări atunci când partajați o cursă.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              elevation: 1,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _contacts.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade300),
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(contact.name),
                    subtitle: Text(contact.phoneNumber),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: l10n.sendTestMessage,
                          icon: const Icon(Icons.sms_outlined),
                          onPressed: () => _sendTestMessage(contact),
                        ),
                        IconButton(
                          tooltip: l10n.delete,
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeContact(contact),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSafetyFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
