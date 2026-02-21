import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Text('Notifications Screen', style: AppTextStyles.h1),
      ),
    );
  }
}