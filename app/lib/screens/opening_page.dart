import 'package:flutter/material.dart';

import 'home_page.dart';

class OpeningPage extends StatelessWidget {
  const OpeningPage({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.brush_rounded, size: 96, color: cs.primary),
                      const SizedBox(height: 16),
                      Text('InkStudio',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Draw anything. Offline.', textAlign: TextAlign.center),
                      const SizedBox(height: 48),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage())),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Text('Get Started', style: TextStyle(fontSize: 18))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

