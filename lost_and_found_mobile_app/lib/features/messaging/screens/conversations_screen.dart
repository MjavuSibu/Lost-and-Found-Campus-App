import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Center(
        child: Text('Messages Screen', style: AppTextStyles.h1),
      ),
    );
  }
}