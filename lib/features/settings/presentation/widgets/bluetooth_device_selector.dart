import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../models/device_model.dart';
import '../../cubit/settings_cubit.dart';

class BluetoothDeviceSelector extends StatelessWidget {
  final SettingsLoaded state;

  const BluetoothDeviceSelector({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bluetooth Devices',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (state.isScanningBluetooth)
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
              labelText: 'Select Bluetooth Device',
              prefixIcon: const Icon(Icons.bluetooth),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: state.bluetoothDevices.isEmpty
                ? [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No devices available'),
                    ),
                  ]
                : state.bluetoothDevices.map(
                    (device) => DropdownMenuItem<String>(
                      value: device.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            device.type == DeviceType.printer
                                ? Icons.print
                                : Icons.bluetooth,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              device.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (device.isConnected)
                            const Icon(Icons.check_circle,
                                size: 16, color: Colors.green),
                        ],
                      ),
                    ),
                  ).toList(),
            value: state.bluetoothDevices.isNotEmpty &&
                    state.selectedBluetoothDeviceId != null &&
                    state.bluetoothDevices.any(
                      (device) => device.id == state.selectedBluetoothDeviceId,
                    )
                ? state.selectedBluetoothDeviceId
                : null,
            onChanged: (value) {
              if (value != null) {
                final device = state.bluetoothDevices.firstWhere(
                  (d) => d.id == value,
                  orElse: () => const DeviceModel(
                    id: '',
                    name: '',
                    type: DeviceType.bluetooth,
                  ),
                );
                context.read<SettingsCubit>().selectDevice(value, device.type);
              }
            },
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            context.read<SettingsCubit>().scanBluetoothDevices();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Scan Bluetooth'),
        ),
      ],
    );
  }
}

