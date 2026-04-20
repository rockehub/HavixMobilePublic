import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(height: 60, color: Colors.white),
                const SizedBox(height: 8),
                Container(height: 300, color: Colors.white),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: List.generate(
                      4,
                      (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(width: 100, height: 120, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(height: 14, color: Colors.white),
                                  const SizedBox(height: 8),
                                  Container(height: 14, width: 120, color: Colors.white),
                                  const SizedBox(height: 8),
                                  Container(height: 14, width: 80, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
