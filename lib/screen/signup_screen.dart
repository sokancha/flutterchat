import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore 사용
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication 사용
import 'package:chatapp/screen/login_screen.dart'; // LoginScreen import
import 'package:chatapp/screen/home_screen.dart';

class SignupScreen extends StatelessWidget {
  final String kakaoUserId;
  final String? kakaoNickname;

  const SignupScreen({
    Key? key,
    required this.kakaoUserId,
    this.kakaoNickname,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 컨트롤러 선언
    TextEditingController nameController = TextEditingController(text: kakaoNickname ?? '');
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('회원가입', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: '이메일'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Firebase Auth로 계정 생성
                  UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  String uid = userCredential.user?.uid ?? '';

                  // Firestore에 사용자 정보 저장
                  await FirebaseFirestore.instance.collection('users').doc(uid).set({
                    'firebaseUserId': uid,
                    'kakaoUserId': kakaoUserId,
                    'name': nameController.text,
                    'email': emailController.text,
                  });

                  print('회원가입 정보 저장 완료');

                  // 로그인 화면으로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                } catch (e) {
                  print('회원가입 실패: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('회원가입 실패: ${e.toString()}')),
                  );
                }
              },
              child: Text('회원가입 완료'),
            ),
          ],
        ),
      ),
    );
  }
}
