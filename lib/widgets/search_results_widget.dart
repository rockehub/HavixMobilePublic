import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/api/commerce_api.dart';
import '../core/config/app_config.dart';
import '../core/models/commerce_models.dart';
import '../core/models/storefront_models.dart';

class SearchResultsWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;
  final String? searchQuery;

  const SearchResultsWidget({super.key, required this.config, required this.storefront, this.searchQuery});

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  final _api = CommerceApi();
  final _controller = TextEditingController();
  List<ProductSummary> _products = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.searchQuery ?? '';
    if (_controller.text.isNotEmpty) _search();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      _products = await _api.getProducts(search: _controller.text);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Buscar produtos...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _search),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const CircularProgressIndicator()
          else if (_products.isEmpty && _controller.text.isNotEmpty)
            const Text('Nenhum produto encontrado.')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.7,
              ),
              itemCount: _products.length,
              itemBuilder: (context, i) {
                final p = _products[i];
                return GestureDetector(
                  onTap: () => context.push('/product/${p.slug}'),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: p.imageUrl != null
                              ? CachedNetworkImage(imageUrl: AppConfig.resolveMediaUrl(p.imageUrl!), fit: BoxFit.cover, width: double.infinity)
                              : Container(color: Colors.grey[200]),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              Text(fmt.format(p.price), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
