import 'package:flutter/material.dart';

class SHGMessagesScreen extends StatelessWidget {
  const SHGMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: const Center(child: Text('Chat with Buyers & Suppliers')),
    );
  }
}
