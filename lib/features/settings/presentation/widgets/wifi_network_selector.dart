import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../models/device_model.dart';
import '../../cubit/settings_cubit.dart';

class WifiNetworkSelector extends StatelessWidget {
  final SettingsLoaded state;

  const WifiNetworkSelector({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WiFi Networks',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (state.isScanningWifi)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Scanning...'),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Select WiFi Network',
              prefixIcon: const Icon(Icons.wifi),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: state.wifiNetworks.isEmpty
                ? [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No networks available'),
                    ),
                  ]
                : state.wifiNetworks.map(
                    (network) => DropdownMenuItem<String>(
                      value: network.id,
                      child: Text(network.name),
                    ),
                  ).toList(),
            value: state.wifiNetworks.isNotEmpty &&
                    state.selectedWifiDeviceId != null &&
                    state.wifiNetworks.any(
                      (network) => network.id == state.selectedWifiDeviceId,
                    )
                ? state.selectedWifiDeviceId
                : null,
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsCubit>().selectDevice(value, DeviceType.wifi);
              }
            },
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            context.read<SettingsCubit>().scanWifiNetworks();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Scan WiFi'),
        ),
      ],
    );
  }
}

