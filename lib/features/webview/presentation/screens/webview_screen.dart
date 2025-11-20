import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../cubit/webview_cubit.dart';

class WebViewScreen extends StatefulWidget {
  final String? initialUrl;

  const WebViewScreen({
    super.key,
    this.initialUrl,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _webViewController;
  bool _isWebViewInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            context.read<WebViewCubit>().loadUrl(url);
          },
          onProgress: (int progress) {
            context.read<WebViewCubit>().updateProgress(progress / 100.0);
          },
          onPageFinished: (String url) {
            context.read<WebViewCubit>().updateProgress(1.0);
          },
          onWebResourceError: (WebResourceError error) {
            context.read<WebViewCubit>().setError(
                  'Failed to load page: ${error.description}',
                );
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.initialUrl ?? '';

    if (url.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('WebView'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('No URL configured. Please set a URL in Settings.'),
            ],
          ),
        ),
      );
    }

    if (!_isWebViewInitialized) {
      _webViewController.loadRequest(Uri.parse(url));
      context.read<WebViewCubit>().loadUrl(url);
      _isWebViewInitialized = true;
    }

    return BlocBuilder<WebViewCubit, WebViewState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              state.url.isNotEmpty ? Uri.parse(state.url).host : 'WebView',
              overflow: TextOverflow.ellipsis,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (state is WebViewLoaded || state is WebViewError)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<WebViewCubit>().reload();
                    _webViewController.reload();
                  },
                  tooltip: 'Reload',
                ),
            ],
          ),
          body: Stack(
            children: [
              WebViewWidget(controller: _webViewController),
              if (state is WebViewLoading && state.progress < 1.0)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: state.progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              if (state is WebViewError)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<WebViewCubit>().reload();
                          _webViewController.reload();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

