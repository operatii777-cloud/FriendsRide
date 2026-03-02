import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Serviciu pentru Social Login (Google, Apple, Facebook)
class SocialAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _saveUserToFirestore(userCredential.user);
      Logger.info('Google sign-in successful: ${userCredential.user?.email}',
          tag: 'SocialAuth');
      return userCredential;
    } catch (e) {
      Logger.error('Error signing in with Google', error: e, tag: 'SocialAuth');
      return null;
    }
  }

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      await _saveUserToFirestore(userCredential.user,
          appleCredential: appleCredential);
      Logger.info('Apple sign-in successful: ${userCredential.user?.email}',
          tag: 'SocialAuth');
      return userCredential;
    } catch (e) {
      Logger.error('Error signing in with Apple', error: e, tag: 'SocialAuth');
      return null;
    }
  }

  /// Sign in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        Logger.warning('Facebook login failed: ${result.status}',
            tag: 'SocialAuth');
        return null;
      }

      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      final userCredential =
          await _auth.signInWithCredential(facebookAuthCredential);
      final userData = await FacebookAuth.instance.getUserData();
      await _saveUserToFirestore(userCredential.user,
          facebookData: userData);
      Logger.info(
          'Facebook sign-in successful: ${userCredential.user?.email}',
          tag: 'SocialAuth');
      return userCredential;
    } catch (e) {
      Logger.error('Error signing in with Facebook',
          error: e, tag: 'SocialAuth');
      return null;
    }
  }

  /// Save user data to Firestore
  Future<void> _saveUserToFirestore(
    User? user, {
    dynamic appleCredential,
    Map<String, dynamic>? facebookData,
  }) async {
    if (user == null) return;

    try {
      final userData = <String, dynamic>{
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ??
            appleCredential?.givenName ??
            facebookData?['name'] ??
            'User',
        'photoURL':
            user.photoURL ?? facebookData?['picture']?['data']?['url'],
        'provider': user.providerData.first.providerId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      if (appleCredential != null) {
        if (appleCredential.givenName != null) {
          userData['firstName'] = appleCredential.givenName;
        }
        if (appleCredential.familyName != null) {
          userData['lastName'] = appleCredential.familyName;
        }
      }

      if (facebookData != null) {
        if (facebookData['first_name'] != null) {
          userData['firstName'] = facebookData['first_name'];
        }
        if (facebookData['last_name'] != null) {
          userData['lastName'] = facebookData['last_name'];
        }
      }

      await _db.collection('users').doc(user.uid).set(
            userData,
            SetOptions(merge: true),
          );

      Logger.info('User data saved to Firestore: ${user.uid}',
          tag: 'SocialAuth');
    } catch (e) {
      Logger.error('Error saving user to Firestore',
          error: e, tag: 'SocialAuth');
    }
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);
      Logger.info('Signed out from all providers', tag: 'SocialAuth');
    } catch (e) {
      Logger.error('Error signing out', error: e, tag: 'SocialAuth');
    }
  }
}
