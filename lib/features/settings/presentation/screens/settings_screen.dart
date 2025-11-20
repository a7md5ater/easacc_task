import 'package:easacc/config/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/injector.dart';
import '../../../../features/auth/cubit/auth_cubit.dart';
import '../../cubit/settings_cubit.dart';
import '../../../../core/shared_widgets/loading_indicator.dart';
import '../widgets/url_input_section.dart';
import '../widgets/network_devices_section.dart';
import '../widgets/open_webview_button.dart';
import '../widgets/settings_error_view.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _urlFormKey = GlobalKey<FormState>();
  bool _hasTriggeredScanning = false;

  @override
  void initState() {
    super.initState();
    // Check if cubit is already in loaded state and trigger scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<SettingsCubit>();
        final currentState = cubit.state;
        if (currentState is SettingsLoaded && !_hasTriggeredScanning) {
          _hasTriggeredScanning = true;
          cubit.scanAllDevices();
        }
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          actions: [
            BlocListener<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthUnauthenticated) {
                  context.go(Routes.login);
                }
              },
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  di<AuthCubit>().logout();
                },
                tooltip: 'Logout',
              ),
            ),
          ],
        ),
        body: BlocListener<SettingsCubit, SettingsState>(
          listener: (context, state) {
            if (state is SettingsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is SettingsLoaded) {
              if (_urlController.text != state.savedUrl) {
                _urlController.text = state.savedUrl;
              }
              // Trigger scanning when SettingsLoaded is first received
              if (!_hasTriggeredScanning) {
                _hasTriggeredScanning = true;
                // Use a small delay to ensure UI is ready
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    context.read<SettingsCubit>().scanAllDevices();
                  }
                });
              }
            }
          },
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              if (state is SettingsLoading) {
                return const LoadingIndicator();
              }

              if (state is SettingsError && state is! SettingsLoaded) {
                return SettingsErrorView(state: state);
              }

              final settingsState = state is SettingsLoaded ? state : null;

              if (settingsState == null) {
                return const SizedBox.shrink();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UrlInputSection(
                      urlController: _urlController,
                      formKey: _urlFormKey,
                    ),
                    const SizedBox(height: 24),
                    NetworkDevicesSection(state: settingsState),
                    const SizedBox(height: 24),
                    OpenWebViewButton(savedUrl: settingsState.savedUrl),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
