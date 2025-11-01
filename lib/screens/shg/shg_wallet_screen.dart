import 'package:flutter/material.dart';

class SHGWalletScreen extends StatelessWidget {
  const SHGWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: const Center(child: Text('Wallet & Transactions')),
    );
  }
}
