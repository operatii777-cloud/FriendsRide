import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:friendsride_app/screens/auth_screen.dart';
import 'package:friendsride_app/screens/change_password_screen.dart';
import 'package:friendsride_app/services/account_service.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siguranță și Securitate'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          // ── Password ────────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: const Text('Schimbă parola'),
            subtitle: const Text('Modifică parola contului tău'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ChangePasswordScreen()),
              );
            },
          ),

          const Divider(),

          // ── Session management ───────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Sesiuni',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: const Text('Deconectare de pe toate dispozitivele'),
            subtitle: const Text('Ieșire din cont pe toate dispozitivele conectate'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _confirmLogoutAllDevices(context),
          ),

          const Divider(),

          // ── Danger zone ──────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Zonă periculoasă',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text(
              'Ștergere cont',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Șterge permanent contul și toate datele asociate'),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red),
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  // ── Logout all devices ─────────────────────────────────────────────────────

  void _confirmLogoutAllDevices(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deconectare de pe toate dispozitivele'),
        content: const Text(
          'Vei fi deconectat de pe toate dispozitivele, inclusiv cel curent. '
          'Va trebui să te autentifici din nou.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(dialogContext).pop();

              try {
                await AccountService().logoutAllDevices();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (ctx) => const AuthScreen()),
                  (route) => false,
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Eroare: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Deconectează'),
          ),
        ],
      ),
    );
  }

  // ── Delete account ─────────────────────────────────────────────────────────

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Only offer password re-auth for email/password providers
    final user = FirebaseAuth.instance.currentUser;
    final isEmailUser = user?.providerData
            .any((p) => p.providerId == EmailAuthProvider.PROVIDER_ID) ??
        false;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ștergere cont permanent'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Atenție! Această acțiune este ireversibilă.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vor fi șterse definitiv:\n'
                '• Profilul tău\n'
                '• Istoricul curselor\n'
                '• Toate datele asociate contului',
              ),
              if (isEmailUser) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Parola contului',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Introduceți parola pentru confirmare.'
                      : null,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(dialogContext).pop();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final result = await AccountService()
                  .deleteAccount(passwordController.text);

              navigator.pop(); // close loading indicator
              if (!navigator.mounted) return;

              if (result['success'] == true) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(result['message'] as String),
                    backgroundColor: Colors.green,
                  ),
                );
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (ctx) => const AuthScreen()),
                  (route) => false,
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(result['message'] as String),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Ștergere cont',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
