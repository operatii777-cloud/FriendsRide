import 'package:flutter/material.dart';

class JoinTeamScreen extends StatelessWidget {
  const JoinTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alătură-te Echipei FriendsRide'),
      ),
      // CORECȚIE: Am eliminat 'const'-ul de aici pentru a permite apelarea funcțiilor
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Condiții de Colaborare pentru Șoferi Parteneri',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bun venit în procesul de a deveni șofer partener FriendsRide! Pentru a asigura o experiență sigură și de calitate pentru toți utilizatorii, avem următoarele cerințe și condiții:',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Cerințe pentru Șoferi:'),
            _buildRequirementItem('Vârsta minimă de 21 de ani.'),
            _buildRequirementItem('Permis de conducere categoria B valabil, cu o vechime de cel puțin 2 ani.'),
            _buildRequirementItem('Cazier judiciar curat.'),
            _buildRequirementItem('Atestat de transport persoane în regim de închiriere valabil.'),
            _buildRequirementItem('Card de identitate și permis de conducere valabile.'),
            const SizedBox(height: 16),
            _buildSectionTitle('Cerințe pentru Autovehicul:'),
            _buildRequirementItem('Autovehicul înmatriculat în România, cu ITP valabil.'),
            _buildRequirementItem('Normă de poluare minim Euro 5.'),
            _buildRequirementItem('Autovehicul cu 4 uși, în stare tehnică și estetică bună.'),
            _buildRequirementItem('Asigurare RCA valabilă.'),
            _buildRequirementItem('Copie conformă și ecusoane pentru transport alternativ valabile.'),
            const SizedBox(height: 16),
            _buildSectionTitle('Procesul de Înregistrare:'),
            const Text(
              '1. Completați formularul de aplicare direct din aplicație.\n'
              '2. Încărcați documentele solicitate în format digital.\n'
              '3. Așteptați validarea contului de către echipa noastră (poate dura până la 48 de ore).\n'
              '4. Odată ce contul este activat, puteți comuta în "Mod Șofer" și începe să acceptați curse.',
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Vă mulțumim pentru interes și vă urăm bun venit în echipă!',
                 style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Funcție ajutătoare pentru a formata titlurile de secțiune
  static Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  // Funcție ajutătoare pentru a formata item-urile din liste
  static Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
