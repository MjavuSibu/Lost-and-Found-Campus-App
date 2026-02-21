import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';

class ItemDetailScreen extends StatelessWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Detail')),
      body: Center(
        child: Text('Item Detail Screen', style: AppTextStyles.h1),
      ),
    );
  }
}