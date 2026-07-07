import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/ad_config_service.dart';

/// Loads remote HTML/JS ad banner via WebView without rebuilding the APK.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  WebViewController? _controller;
  AdConfig? _config;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    final config = await AdConfigService.loadBannerConfig();
    if (!mounted || config == null) return;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (_) {
            if (mounted) setState(() => _visible = false);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _visible = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(config.bannerUrl));

    if (!mounted) return;
    setState(() {
      _config = config;
      _controller = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _config == null || !_visible) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: _config!.height,
      width: double.infinity,
      child: WebViewWidget(controller: _controller!),
    );
  }
}
