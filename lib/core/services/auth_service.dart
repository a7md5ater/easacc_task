import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../models/user_model.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      return UserModel(
        id: account.id,
        email: account.email,
        name: account.displayName,
        photoUrl: account.photoUrl,
        accessToken: auth.accessToken,
        idToken: auth.idToken,
        provider: 'google',
      );
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  Future<UserModel?> signInWithFacebook() async {
    try {
      final LoginResult result = await _facebookAuth.login();

      if (result.status != LoginStatus.success) {
        return null;
      }

      final AccessToken accessToken = result.accessToken!;
      final userData = await _facebookAuth.getUserData();

      return UserModel(
        id: userData['id']?.toString() ?? '',
        email: userData['email']?.toString(),
        name: userData['name']?.toString(),
        photoUrl: userData['picture']?['data']?['url']?.toString(),
        accessToken: accessToken.token,
        idToken: null,
        provider: 'facebook',
      );
    } catch (e) {
      throw Exception('Facebook sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _facebookAuth.logOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  Future<bool> isSignedIn() async {
    try {
      final googleSignedIn = await _googleSignIn.isSignedIn();
      final facebookAccessToken = await _facebookAuth.accessToken;
      return googleSignedIn || facebookAccessToken != null;
    } catch (e) {
      return false;
    }
  }
}
