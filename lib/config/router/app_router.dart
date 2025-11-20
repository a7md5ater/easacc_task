import 'package:easacc/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/injector.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/settings/cubit/settings_cubit.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/webview/cubit/webview_cubit.dart';
import '../../features/webview/presentation/screens/webview_screen.dart';
import 'auth_refresh_listenable.dart';
import 'routes.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey(
    debugLabel: 'root',
  );

  static GoRouter createRouter() {
    final authCubit = di<AuthCubit>();
    final refreshListenable = AuthRefreshListenable(authCubit);

    return GoRouter(
      initialLocation: Routes.splash,
      debugLogDiagnostics: true,
      navigatorKey: rootNavigatorKey,
      refreshListenable: refreshListenable,
      redirect: (context, state) {
        final authState = authCubit.state;
        final isLoggedIn = authState is AuthAuthenticated;
        final isSplash = state.matchedLocation == Routes.splash;
        final isLogin = state.matchedLocation == Routes.login;

        if (authState is AuthInitial || authState is AuthLoading) {
          return isSplash ? null : Routes.splash;
        }

        if (!isLoggedIn) {
          return isLogin ? null : Routes.login;
        }

        if (isSplash || isLogin) {
          return Routes.settings;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: Routes.splash,
          name: Routes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: Routes.login,
          name: Routes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: Routes.settings,
          name: Routes.settings,
          builder: (context, state) {
            return BlocProvider<SettingsCubit>(
              create: (context) => di<SettingsCubit>(),
              child: const SettingsScreen(),
            );
          },
        ),
        GoRoute(
          path: Routes.webview,
          name: Routes.webview,
          builder: (context, state) {
            final initialUrl = state.extra != null
                ? state.extra as String?
                : null;
            return BlocProvider<WebViewCubit>(
              create: (context) => di<WebViewCubit>(),
              child: WebViewScreen(initialUrl: initialUrl),
            );
          },
        ),
      ],
    );
  }
}
