import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';

class PostItemScreen extends StatelessWidget {
  final String initialType;
  const PostItemScreen({super.key, required this.initialType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Item')),
      body: Center(
        child: Text('Post Item Screen', style: AppTextStyles.h1),
      ),
    );
  }
}