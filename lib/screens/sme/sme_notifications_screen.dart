import 'package:flutter/material.dart';

class SMENotificationsScreen extends StatelessWidget {
  const SMENotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Order & Delivery Updates')),
    );
  }
}
