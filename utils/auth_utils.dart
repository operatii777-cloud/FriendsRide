import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart'; // REMOVED: Unnecessary import

class AuthUtils {
  // Metodă statică pentru a afișa dialogul de resetare a parolei
  static void showPasswordResetDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final formKey = GlobalKey<FormState>(); // FIX: Renamed _formKey to formKey

    showDialog(
      context: context,
      builder: (dialogContext) { // Folosim `dialogContext` pentru contextul dialogului
        return AlertDialog(
          title: const Text('Resetare Parolă'),
          content: Form(
            key: formKey, // FIX: Used formKey
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Introduceți adresa de email asociată contului dumneavoastră pentru a primi un link de resetare a parolei.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Introduceți o adresă de email validă.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) { // FIX: Used formKey
                  formKey.currentState?.save(); // Salvăm câmpurile formularului // FIX: Used formKey
                  String email = emailController.text.trim();
                  
                  // Afișăm un indicator de încărcare în dialog
                  Navigator.of(dialogContext).pop(); // Închidem dialogul de input
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Se trimite emailul de resetare...'),
                      duration: Duration(seconds: 2), // Scurt, pentru a fi urmat de mesajul de succes/eroare
                    ),
                  );

                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    if (context.mounted) { // Verificăm context.mounted înainte de a folosi contextul principal
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Un email de resetare a parolei a fost trimis la $email. Verificați-vă inbox-ul (inclusiv folderul Spam)!'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 8),
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    String message = 'A apărut o eroare la trimiterea email-ului de resetare.';
                    if (e.code == 'user-not-found') {
                      message = 'Nu există niciun cont cu această adresă de email.';
                    } else if (e.message != null) {
                      message = e.message!;
                    }
                    if (context.mounted) { // Verificăm context.mounted
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error sending password reset email from dialog: $e');
                    if (context.mounted) { // Verificăm context.mounted
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('A apărut o eroare neașteptată.'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Resetează Parola'),
            ),
          ],
        );
      },
    );
  }
}
