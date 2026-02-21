import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CUT Lost & Found')),
      body: Center(
        child: Text('Home Screen', style: AppTextStyles.h1),
      ),
    );
  }
}