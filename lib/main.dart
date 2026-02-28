import 'package:flutter/material.dart';

void main() {
  runApp(const FriendsRideApp());
}

class FriendsRideApp extends StatelessWidget {
  const FriendsRideApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FriendsRide App',
      home: Scaffold(
        appBar: AppBar(title: const Text('FriendsRide App')),
        body: const Center(child: Text('Bine ai venit la FriendsRide!')),
      ),
    );
  }
}
