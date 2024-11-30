import 'package:chatapp/screen/home_screen.dart';
import 'package:chatapp/screen/login_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'firebase_options.dart';

void main() async {
  KakaoSdk.init(nativeAppKey: '519460859f59203588ac513dc8584a92',
                javaScriptAppKey:'581f4b443da03e657cb5d67352503faa'); // Kakao SDK 초기화
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
      home: SplashScreen(), // 초기 화면 설정
    );
  }
}

class SplashScreen extends StatelessWidget {
  Future<Widget> _checkLoginStatus() async {
    try {
      // 현재 로그인 상태 확인
      User user = await UserApi.instance.me();
      String userId = user.id.toString();
      String? username = user.kakaoAccount?.profile?.nickname;

      // 로그인 상태일 경우 홈 화면 반환
      return HomeScreen(
        userId: userId,
        username: username ?? 'Unknown User',
      );
    } catch (e) {
      // 로그인 상태가 아니면 로그인 화면 반환
      return LoginSignupScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return snapshot.data!;
        } else {
          return LoginSignupScreen();
        }
      },
    );
  }
}
