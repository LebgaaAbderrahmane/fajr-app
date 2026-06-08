import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FajrApp());
}

class FajrApp extends StatelessWidget {
  const FajrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fajr Alarm',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const HomeScreen(),
    );
  }
}
