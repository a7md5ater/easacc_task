import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/settings/cubit/settings_cubit.dart';
import '../../features/webview/cubit/webview_cubit.dart';

extension CubitExtensions on BuildContext {
  AuthCubit get authCubit => read<AuthCubit>();
  SettingsCubit get settingsCubit => read<SettingsCubit>();
  WebViewCubit get webViewCubit => read<WebViewCubit>();
}

