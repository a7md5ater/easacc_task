import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/router/routes.dart';

class OpenWebViewButton extends StatelessWidget {
  final String? savedUrl;

  const OpenWebViewButton({
    super.key,
    required this.savedUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: savedUrl?.isNotEmpty == true
            ? () {
                context.push(
                  Routes.webview,
                  extra: savedUrl,
                );
              }
            : null,
        icon: const Icon(Icons.open_in_browser),
        label: const Text('Open WebView'),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

