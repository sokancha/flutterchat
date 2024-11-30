import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatapp/screen/home_screen.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                  UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  String uid = userCredential.user?.uid ?? '';

                  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

                  if (userDoc.exists) {
                    print('로그인 성공 및 사용자 정보: ${userDoc.data()}');

                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                            email: userDoc['email'] ?? 'unknown',
                            username: userDoc['name'] ?? 'unknown',
                            userId: uid,
                          ),
                        ),
                      );
                  } else {
                  print('Firestore에 사용자 정보가 존재하지 않습니다.');
                  }

                } catch (e) {
                  print('로그인 실패: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('로그인 실패: ${e.toString()}')),
                  );
                }
              },
              child: Text('로그인'),
            ),
          ],
        ),
      ),
    );
  }
}
