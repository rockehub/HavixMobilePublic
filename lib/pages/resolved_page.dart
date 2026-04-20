import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/storefront_models.dart';
import '../core/store/storefront_store.dart';
import '../widgets/widget_resolver.dart';

class ResolvedPage extends StatelessWidget {
  final StorefrontPage page;
  const ResolvedPage({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final storefront = context.watch<StorefrontStore>().resolveData;
    if (storefront == null) return const SizedBox.shrink();
    final areas = page.layout?.areas ?? [];

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate(
            areas.map((area) => _buildArea(context, area, storefront)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildArea(BuildContext context, StorefrontArea area, StorefrontResolveResponse storefront) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Flat mode: area has widgets directly
    final flatWidgets = area.rows.isEmpty ? <StorefrontWidget>[] : <StorefrontWidget>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: area.rows.map((row) => _buildRow(context, row, storefront, isMobile)).toList(),
    );
  }

  Widget _buildRow(BuildContext context, StorefrontRow row, StorefrontResolveResponse storefront, bool isMobile) {
    if (isMobile || row.columns.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: row.columns
            .expand((col) => col.widgets)
            .map((w) => resolveWidget(w, storefront: storefront))
            .toList(),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: row.columns.map((col) {
          return Expanded(
            flex: col.span,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: col.widgets.map((w) => resolveWidget(w, storefront: storefront)).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PageLoader extends StatefulWidget {
  final String pageType;
  final String? slug;
  final Future<StorefrontPage> Function() loader;

  const PageLoader({super.key, required this.pageType, this.slug, required this.loader});

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
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Erro ao carregar página'),
                TextButton(
                  onPressed: () => setState(() => _future = widget.loader()),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }
        return ResolvedPage(page: snapshot.data!);
      },
    );
  }
}
