import 'package:chatapp/screen/login_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatapp/screen/login_screen.dart'; // 로그아웃을 위한 로그인 화면

class HomeScreen extends StatefulWidget {
  final String email;
  final String username;
  final String userId;

  HomeScreen({
    Key? key,
    this.email = '', // 기본값 지정
    this.username = 'Guest',
    this.userId = '',
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 네비게이션 바 선택
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 로그아웃 처리
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginSignupScreen()), // 로그인 화면으로 이동
    );
  }

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0:
        return "홈 화면";
      case 1:
        return "채팅 화면";
      case 2:
        return "놀거리 화면";
      case 3:
        return "식당 화면";
      case 4:
        return "내 정보";
      default:
        return "알 수 없는 화면";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.account_circle, size: 30.0),
                onPressed: () {
                  // 사용자 로고를 누르면 홈 화면으로 돌아감
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
                        username: widget.username,
                        email: widget.email, // email 전달
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 4.0),
              Text(
                widget.username,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) {
              if (value == 5) {
                // 로그아웃 처리
                _logout();
              } else {
                // 다른 화면으로 전환
                _onItemTapped(value);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 1, child: Text('채팅')),
              PopupMenuItem(value: 2, child: Text('놀거리')),
              PopupMenuItem(value: 3, child: Text('음식점')),
              PopupMenuItem(value: 4, child: Text('내 정보')),
              PopupMenuItem(value: 5, child: Text('로그아웃')),
            ],
          ),
        ],
      ),
        body: Center(
        child: Text(
        _getScreenTitle(), // 현재 화면 이름 표시
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
