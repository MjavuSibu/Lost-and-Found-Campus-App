import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';

class ChatScreen extends StatelessWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Center(
        child: Text('Chat Screen', style: AppTextStyles.h1),
      ),
    );
  }
}