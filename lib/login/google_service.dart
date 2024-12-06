import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // 구글 로그인 함수
  Future<bool> login() async {
    try {
      // Google 로그인
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        // 구글 로그인 후 인증 토큰 가져오기
        GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Firebase 인증용 자격 증명 만들기
        OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Firebase에 로그인
        UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

        if (userCredential.user != null) {
          print('Firebase 로그인 성공: ${userCredential.user!.displayName}');
          return true;
        } else {
          print('Firebase 로그인 실패');
          return false;
        }
      } else {
        print('구글 로그인 실패');
        return false;
      }
    } catch (error) {
      print('구글 로그인 또는 Firebase 인증 실패: $error');
      return false;
    }
  }

  // 구글 로그아웃 함수
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      print('구글 로그아웃 성공');
    } catch (error) {
      print('구글 로그아웃 실패: $error');
    }
  }

  // 구글 사용자 정보 가져오기
  Future<User?> getCurrentUser() async {
    try {
      User? user = _firebaseAuth.currentUser;
      return user;
    } catch (error) {
      print('현재 사용자 정보 가져오기 실패: $error');
      return null;
    }
  }
}
