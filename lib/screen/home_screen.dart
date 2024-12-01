import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 패키지 추가
import 'package:chatapp/screen/login_signup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 현재 선택된 네비게이션 탭 인덱스

  String _userName = ''; // Firestore에서 가져온 사용자 이름

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  // Firestore에서 사용자 정보 가져오기
  void _getUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser; // 현재 사용자 가져오기
    if (user != null) {
      // Firestore에서 사용자 데이터 읽기
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') // 컬렉션 이름은 Firestore에 맞게 수정
          .doc(user.uid) // 문서 ID로 사용자 UID 사용
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'] ?? '사용자'; // name 필드 읽기, 없으면 기본값 '사용자'
        });
      }
    }
  }

  // 네비게이션 바 선택 처리
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
      MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
    );
  }

  // 현재 화면의 타이틀 가져오기
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
        leading: GestureDetector(
          onTap: () {
            // 사용자 아이콘 클릭 시 홈 화면으로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
          child: const Icon(
            Icons.person, // 사람 모양의 아이콘
            size: 30,
          ),
        ),
        title: Text(
          _userName, // Firestore에서 불러온 사용자 이름 표시
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) {
              if (value == 5) {
                _logout(); // 로그아웃 처리
              } else {
                _onItemTapped(value); // 다른 화면으로 전환
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('채팅')),
              const PopupMenuItem(value: 2, child: Text('놀거리')),
              const PopupMenuItem(value: 3, child: Text('음식점')),
              const PopupMenuItem(value: 4, child: Text('내 정보')),
              const PopupMenuItem(value: 5, child: Text('로그아웃')),
            ],
          ),
        ],
      ),
      body: Center(
        child: Text(
          _getScreenTitle(), // 현재 화면 이름 표시
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.celebration), label: '놀거리'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: '식당'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: '내 정보'),
        ],
      ),
    );
  }
}
