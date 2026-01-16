import 'package:flutter/material.dart';
import 'presentation_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSVP Reader'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Read my...',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: 250,
              height: 80,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PresentationPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 24),
                ),
                child: const Text('Clipboard'),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 250,
              height: 80,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 24),
                ),
                child: const Text('PDF (WIP)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
