import 'package:flutter/material.dart';

class SMEMessagesScreen extends StatelessWidget {
  const SMEMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: const Center(child: Text('Chat with Farmers')),
    );
  }
}
