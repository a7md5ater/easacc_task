import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'webview_state.dart';

class WebViewCubit extends Cubit<WebViewState> {
  WebViewCubit() : super(WebViewInitial());

  void loadUrl(String url) {
    if (url.isEmpty) {
      emit(WebViewError('URL is empty', url: ''));
      return;
    }

    emit(WebViewLoading(url: url));
  }

  void updateProgress(double progress) {
    final currentState = state;
    if (currentState is WebViewLoading) {
      if (progress >= 1.0) {
        emit(WebViewLoaded(url: currentState.url));
      } else {
        emit(WebViewLoading(url: currentState.url, progress: progress));
      }
    }
  }

  void reload() {
    final currentState = state;
    if (currentState is WebViewLoaded || currentState is WebViewError) {
      emit(WebViewLoading(url: currentState.url));
    }
  }

  void setError(String message) {
    final currentState = state;
    final url = currentState.url.isNotEmpty ? currentState.url : '';
    emit(WebViewError(message, url: url));
  }
}

