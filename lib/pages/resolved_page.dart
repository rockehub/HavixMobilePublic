import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/storefront_models.dart';
import '../core/store/storefront_store.dart';
import '../widgets/widget_resolver.dart';

class ResolvedPage extends StatelessWidget {
  final StorefrontPage page;
  final String? slug;
  const ResolvedPage({super.key, required this.page, this.slug});

  @override
  Widget build(BuildContext context) {
    final storefront = context.watch<StorefrontStore>().resolveData;
    if (storefront == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final template = storefront.layoutTemplate;
    final pageAreas = page.layout?.areas ?? [];

    // Merge template areas + page areas, sorted by position (same as web)
    final mergedAreas = <StorefrontArea>[
      ...?template?.areas,
      ...pageAreas,
    ]..sort((a, b) => a.position.compareTo(b.position));

    final allWidgets = mergedAreas.expand((a) => a.allWidgets).toList();

    if (kDebugMode) {
      debugPrint('[ResolvedPage] page=${page.pageType} '
          'areas=${mergedAreas.length} totalWidgets=${allWidgets.length}');
      for (final a in mergedAreas) {
        debugPrint('  area=${a.name} pos=${a.position} widgets=${a.allWidgets.length}');
      }
    }

    if (allWidgets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Página sem conteúdo configurado',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                resolveWidget(allWidgets[index], storefront: storefront, slug: slug),
            childCount: allWidgets.length,
          ),
        ),
      ],
    );
  }
}

class PageLoader extends StatefulWidget {
  final String pageType;
  final String? slug;
  final Future<StorefrontPage> Function() loader;

  const PageLoader(
      {super.key, required this.pageType, this.slug, required this.loader});

  @override
  State<PageLoader> createState() => _PageLoaderState();
}

class _PageLoaderState extends State<PageLoader> {
  late Future<StorefrontPage> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StorefrontPage>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint(
              '[PageLoader] error loading ${widget.pageType}: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Erro ao carregar página',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _future = widget.loader()),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ResolvedPage(page: snapshot.data!, slug: widget.slug);
      },
    );
  }
}
