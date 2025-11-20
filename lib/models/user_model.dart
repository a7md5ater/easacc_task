import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String? email;
  final String? name;
  final String? photoUrl;
  final String? accessToken;
  final String? idToken;
  final String provider;

  const UserModel({
    required this.id,
    this.email,
    this.name,
    this.photoUrl,
    this.accessToken,
    this.idToken,
    required this.provider,
  });

  /// Gets the token to use for authentication
  /// Prefers accessToken, falls back to idToken
  String? get token => accessToken ?? idToken;

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        photoUrl,
        accessToken,
        idToken,
        provider,
      ];
}

