import 'package:flutter/material.dart';

class SpacerWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  const SpacerWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: (config['height'] as num?)?.toDouble() ?? 40);
  }
}
