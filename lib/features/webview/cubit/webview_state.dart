part of 'webview_cubit.dart';

abstract class WebViewState extends Equatable {
  final String url;

  const WebViewState({required this.url});

  @override
  List<Object?> get props => [url];
}

class WebViewInitial extends WebViewState {
  const WebViewInitial() : super(url: '');
}

class WebViewLoading extends WebViewState {
  final double progress;

  const WebViewLoading({required super.url, this.progress = 0.0});

  @override
  List<Object?> get props => [url, progress];
}

class WebViewLoaded extends WebViewState {
  const WebViewLoaded({required super.url});
}

class WebViewError extends WebViewState {
  final String message;

  const WebViewError(this.message, {required super.url});

  @override
  List<Object?> get props => [url, message];
}

