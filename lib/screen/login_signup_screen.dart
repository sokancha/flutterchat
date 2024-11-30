import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chatapp/config/palette.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao_sdk;
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';
import 'package:chatapp/screen/signup_screen.dart'; // 회원가입 화면 import
import 'package:chatapp/screen/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({Key? key}) : super(key: key);

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {


  Future<void> _loginWithKakao() async {
    try {
      // 카카오톡 앱으로 로그인 시도
      if (await isKakaoTalkInstalled()) {
        await kakao_sdk.UserApi.instance.loginWithKakaoTalk();
      } else {
        // 카카오 계정으로 로그인
        await kakao_sdk.UserApi.instance.loginWithKakaoAccount();
      }

      print('카카오 로그인 성공');

      // 로그인 성공 시 사용자 정보 가져오기
      final user = await kakao_sdk.UserApi.instance.me();
      String kakaoUserId = user.id.toString();
      String? kakaoNickname = user.kakaoAccount?.profile?.nickname;

      await _saveKakaoUserToFirebase(kakaoUserId, kakaoNickname);
      // 회원가입 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignupScreen(
            kakaoUserId: kakaoUserId,
            kakaoNickname: kakaoNickname,
          ),
        ),
      );
    } catch (error) {
      print('카카오 로그인 실패: $error');
    }
  }
  Future<void> _saveKakaoUserToFirebase(String kakaoUserId, String? kakaoNickname) async {
    try {
      print('저장 시작: Kakao User ID: $kakaoUserId, Kakao Nickname: $kakaoNickname');

      firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;

      if (user == null) {
        print('Firebase 인증 사용자 없음. 익명으로 로그인합니다.');
        // 익명 로그인
        user = (await firebase_auth.FirebaseAuth.instance.signInAnonymously()).user;
      }

      String firebaseUserId = user?.uid ?? '';
      print('Firebase UID 생성: $firebaseUserId');

      // Firebase Firestore에 카카오 사용자 정보 저장
      await FirebaseFirestore.instance.collection('users').doc(firebaseUserId).set({
        'kakaoUserId': kakaoUserId,
        'name': kakaoNickname ?? 'Unknown',
        'email': user?.email ?? 'Anonymous',  // 실제 이메일을 카카오에서 가져오지 않았다면 null
      });

      print('카카오 사용자 정보가 Firebase에 저장되었습니다.');
    } catch (e) {
      print('Firebase 저장 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase 저장 실패: ${e.toString()}')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.backgroundColor,
      body: Stack(
        children: [
          // 상단 이미지 및 텍스트 영역
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: Container(
              padding: EdgeInsets.only(top: 90, left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Welcome',
                      style: TextStyle(
                        letterSpacing: 1.0,
                        fontSize: 25,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(
                          text: ' to Sangmyung Community',
                          style: TextStyle(
                            letterSpacing: 1.0,
                            fontSize: 25,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('asset/img/logo2.png'),
                  fit: BoxFit.cover,
                  opacity: 0.5,
                ),
              ),
            ),
          ),
          // 로그인 / 회원가입 탭 및 입력 필드
          Positioned(
            top: 300, // 카카오 로그인 버튼 위치를 아래로 이동
            left: 20,
            right: 20,
            child: Container(
              height: 350.0, // 폼 영역의 높이
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 카카오 로그인 버튼
                  GestureDetector(
                    onTap: _loginWithKakao, // 카카오 로그인 함수 호출
                    child: Image.asset(
                      'asset/img/kakao_logo.png', // 카카오톡 아이콘 이미지
                      width: 200, // 아이콘 크기
                      height: 50,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
