import 'package:chatapp/screen/login_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'firebase_options.dart';

void main() async {
  KakaoSdk.init(
    nativeAppKey: '519460859f59203588ac513dc8584a92',
    javaScriptAppKey: '581f4b443da03e657cb5d67352503faa',
  ); // Kakao SDK 초기화
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginSignupScreen(), // 로그인 화면으로 시작
    );
  }
}
