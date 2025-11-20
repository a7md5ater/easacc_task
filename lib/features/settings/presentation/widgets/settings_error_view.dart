import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/settings_cubit.dart';

class SettingsErrorView extends StatelessWidget {
  final SettingsError state;

  const SettingsErrorView({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(state.message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<SettingsCubit>().loadUrl();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

