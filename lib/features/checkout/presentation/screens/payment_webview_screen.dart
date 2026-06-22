import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  final String orderId;

  const PaymentWebViewScreen({
    super.key,
    required this.url,
    required this.orderId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onUrlChange: (change) {
            _checkForRedirect(change.url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _checkForRedirect(String? url) {
    if (url == null) return;
    final lower = url.toLowerCase();

    // eSewa success/cancel
    if (lower.contains('esewa') && lower.contains('success')) {
      _finish(success: true);
      return;
    }
    if (lower.contains('esewa') && lower.contains('cancel')) {
      _finish(success: false);
      return;
    }

    // Khalti
    if (lower.contains('khalti') && lower.contains('success')) {
      _finish(success: true);
      return;
    }
    if (lower.contains('khalti') && lower.contains('cancel')) {
      _finish(success: false);
      return;
    }

    // Generic: check for our app's callback scheme
    if (lower.contains('ecom.aitrc.com.np') ||
        lower.contains('aarambha')) {
      if (lower.contains('success') ||
          lower.contains('complete') ||
          lower.contains('thank')) {
        _finish(success: true);
        return;
      }
      if (lower.contains('cancel') ||
          lower.contains('fail') ||
          lower.contains('error')) {
        _finish(success: false);
        return;
      }
    }
  }

  void _finish({required bool success}) {
    if (!mounted) return;
    Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _finish(success: false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
