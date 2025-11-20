import 'package:flutter/material.dart';
import '../../cubit/settings_cubit.dart';
import 'wifi_network_selector.dart';
import 'bluetooth_device_selector.dart';

class NetworkDevicesSection extends StatelessWidget {
  final SettingsLoaded state;

  const NetworkDevicesSection({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Devices',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            WifiNetworkSelector(state: state),
            const SizedBox(height: 24),
            BluetoothDeviceSelector(state: state),
          ],
        ),
      ),
    );
  }
}

