import 'package:flutter/material.dart';

class SHGNotificationsScreen extends StatelessWidget {
  const SHGNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Order Updates & Alerts')),
    );
  }
}
