import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../core/models/storefront_models.dart';

class ProductReviewsWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const ProductReviewsWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final reviews = (config['reviews'] as List<dynamic>? ?? []);
    final average = (config['averageRating'] as num?)?.toDouble() ?? 0.0;
    final count = config['reviewCount'] as int? ?? 0;
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Avaliações', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(average.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingBarIndicator(rating: average, itemSize: 20, itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber)),
                  Text('$count avaliações', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          ...reviews.map((r) {
            final review = r as Map<String, dynamic>;
            final date = review['createdAt'] != null ? DateTime.tryParse(review['createdAt'] as String) : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(review['authorName'] as String? ?? 'Anônimo', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (date != null) Text(dateFmt.format(date), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RatingBarIndicator(rating: (review['rating'] as num?)?.toDouble() ?? 0, itemSize: 16, itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber)),
                  const SizedBox(height: 4),
                  Text(review['comment'] as String? ?? ''),
                  const Divider(),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
