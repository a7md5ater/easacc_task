import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../core/services/auth_service.dart';
import '../core/services/storage_service.dart';

import '../features/auth/cubit/auth_cubit.dart';
import '../features/settings/cubit/settings_cubit.dart';
import '../features/webview/cubit/webview_cubit.dart';

final di = GetIt.instance;

Future<void> setupGetIt() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  di.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Services
  di.registerLazySingleton<StorageService>(
    () => StorageService(sharedPreferences: di()),
  );
  di.registerLazySingleton<AuthService>(() => AuthService());

  // Connectivity
  di.registerLazySingleton<Connectivity>(() => Connectivity());
  di.registerLazySingleton<NetworkInfo>(() => NetworkInfo());

  // Cubits
  // Auth cubit
  di.registerLazySingleton<AuthCubit>(
    () => AuthCubit(authService: di(), storageService: di()),
  );

  // Settings and WebView cubits
  di.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      storageService: di(),
      connectivity: di(),
      networkInfo: di(),
    ),
  );
  di.registerFactory<WebViewCubit>(() => WebViewCubit());
}
