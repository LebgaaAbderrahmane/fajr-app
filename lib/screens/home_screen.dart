import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fajr Alarm"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Today's Fajr Time",
              style: TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 20),

            const Text(
              "05:12 AM", // placeholder for now
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                // future alarm logic
              },
              child: const Text("Set Alarm"),
            ),
          ],
        ),
      ),
    );
  }
}