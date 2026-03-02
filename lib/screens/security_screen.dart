import 'package:flutter/material.dart';
import 'package:friendsride_app/screens/change_password_screen.dart';

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
        ],
      ),
    );
  }
}
