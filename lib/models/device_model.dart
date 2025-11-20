import 'package:equatable/equatable.dart';

enum DeviceType {
  wifi,
  bluetooth,
  printer,
}

class DeviceModel extends Equatable {
  final String id;
  final String name;
  final DeviceType type;
  final String? address;
  final bool isConnected;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.isConnected = false,
  });

  @override
  List<Object?> get props => [id, name, type, address, isConnected];
}

