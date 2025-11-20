import 'package:equatable/equatable.dart';

class AuthDataModel extends Equatable {
  final String token;
  final String provider;

  const AuthDataModel({
    required this.token,
    required this.provider,
  });

  @override
  List<Object?> get props => [token, provider];
}

