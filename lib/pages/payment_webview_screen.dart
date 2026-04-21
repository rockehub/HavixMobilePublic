import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  String get _resolvedUrl {
    if (!kDebugMode) return widget.url;
    return widget.url
        .replaceAll('localhost', '10.0.2.2')
        .replaceAll('127.0.0.1', '10.0.2.2');
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (request) {
          final url = request.url;
          if (url.contains('/success')) {
            _onSuccess();
            return NavigationDecision.prevent;
          }
          if (url.contains('/failed') || url.contains('/expired')) {
            _onFailed(url.contains('/expired'));
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(_resolvedUrl));
  }

  void _onSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Pagamento confirmado! Pedido em processamento.'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 3),
    ));
    context.go('/orders');
  }

  void _onFailed(bool expired) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(expired ? 'Sessão expirada' : 'Pagamento não realizado'),
        content: Text(expired
            ? 'O tempo para pagamento expirou. Tente finalizar o pedido novamente.'
            : 'O pagamento não foi concluído. Deseja tentar novamente ou voltar ao carrinho?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/cart');
            },
            child: const Text('Voltar ao carrinho'),
          ),
          if (!expired)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _controller.loadRequest(Uri.parse(_resolvedUrl));
              },
              child: const Text('Tentar novamente'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Fechar pagamento',
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Sair do pagamento?'),
                content: const Text('Seu pedido foi criado. Você pode finalizar o pagamento depois em Meus pedidos.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continuar pagando'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/orders');
                    },
                    child: const Text('Sair'),
                  ),
                ],
              ),
            );
          },
        ),
        title: const Text('Pagamento'),
        centerTitle: true,
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
