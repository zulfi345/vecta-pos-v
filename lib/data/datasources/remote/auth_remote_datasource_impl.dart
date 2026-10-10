import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/common/result.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utilities/platform_wrapper.dart';
import '../../../firebase_options.dart';
import '../../models/user_model.dart';
import '../interfaces/auth_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  @override
  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      await googleSignIn.initialize(
        serverClientId: Constants.googleServerClientId,
      );

      final googleSignInAccount = await googleSignIn.authenticate();
      final idToken = googleSignInAccount.authentication.idToken;

      if (idToken == null) {
        return Result.failure(error: 'idToken kosong, cek GOOGLE_SERVER_CLIENT_ID');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential = await firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return Result.failure(error: 'User data is null after sign-in.');
      }

      return Result.success(data: UserModel.fromFirebaseUser(userCredential.user!));
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await firebaseAuth.signOut();
      await googleSignIn.signOut();
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<UserModel?>> getCurrentUser() async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      return Result.success(data: firebaseUser != null ? UserModel.fromFirebaseUser(firebaseUser) : null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
