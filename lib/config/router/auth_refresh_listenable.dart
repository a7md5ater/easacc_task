import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/auth/cubit/auth_cubit.dart';

class AuthRefreshListenable extends ChangeNotifier {
  final AuthCubit _authCubit;
  StreamSubscription<AuthState>? _subscription;

  AuthRefreshListenable(this._authCubit) {
    _subscription = _authCubit.stream.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

