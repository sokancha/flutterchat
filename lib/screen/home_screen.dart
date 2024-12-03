import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/screen/play.dart'; // play.dart의 PlayScreen 가져오기
import 'package:chatapp/screen/login_signup_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:chatapp/config/palette.dart';
import 'package:chatapp/screens/chatting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 현재 선택된 네비게이션 탭 인덱스
  String _userName = ''; // Firestore에서 가져온 사용자 이름
  late LatLng _currentPosition = LatLng(37.7749, -122.4194); // 초기 위치 (샌프란시스코)
  late GoogleMapController _mapController; // 구글 맵 컨트롤러
  List<String> _nearbyUsers = []; // 근처 사용자 목록

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _getNearbyUsers(); // 근처 사용자 목록 가져오기
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


  // Firestore에서 근처 사용자 가져오기
  Future<void> _getNearbyUsers() async {
    User? user = FirebaseAuth.instance.currentUser; // 현재 사용자 가져오기
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        GeoPoint currentUserLocation = userDoc['location']; // 현재 사용자 위치
        double userLat = currentUserLocation.latitude;
        double userLng = currentUserLocation.longitude;

        // 근처 사용자 쿼리 (예: 10km 이내)
        var querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('isOnline', isEqualTo: true)
            .get();

        List<String> nearbyUsers = [];
        for (var doc in querySnapshot.docs) {
          var userLocation = doc['location'];
          if (userLocation is GeoPoint) {
            double distance = _calculateDistance(userLat, userLng, userLocation.latitude, userLocation.longitude);
            if (distance <= 10000 && doc.id != user.uid) { // 10km 이내, 자신 제외
              nearbyUsers.add(doc['name']);
            }
          }
        }

        setState(() {
          _nearbyUsers = nearbyUsers;
        });
      }
    }
  }


  // 두 지점 사이의 거리 계산 (단위: 미터)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371000; // 지구 반경 (미터)
    double phi1 = lat1 * (3.141592653589793 / 180);
    double phi2 = lat2 * (3.141592653589793 / 180);
    double deltaPhi = (lat2 - lat1) * (3.141592653589793 / 180);
    double deltaLambda = (lon2 - lon1) * (3.141592653589793 / 180);

    double a = (sin(deltaPhi / 2) * sin(deltaPhi / 2)) +
        (cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radius * c; // 미터 단위
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
      MaterialPageRoute(builder: (context) => const LoginSignupScreen()), // login_signup_screen.dart를 import하고 클래스 이름을 맞춰주세요.
    );
  }

  // 화면 별 위젯 반환
  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen(); // 홈 화면 반환
      case 1:
        return const Center(
          child: Text(
            '채팅 화면',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      case 2:
        return PlayScreen(); // play.dart의 PlayScreen 사용
      case 3:
        return const Center(
          child: Text(
            '식당 화면',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      case 4:
        return const Center(
          child: Text(
            '내 정보',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      default:
        return const Center(
          child: Text(
            '알 수 없는 화면',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  // 홈 화면 빌드 (근처 사용자 목록 표시)
  Widget _buildHomeScreen() {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox.shrink(), // Firestore에서 불러온 사용자 이름 표시
      ),
      body: Column(
        children: [
          if (_nearbyUsers.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _nearbyUsers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_nearbyUsers[index]),
                  );
                },
              ),
            )
          else
            const Center(
              child: Text('근처 사용자 없음'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = 0; // 홈 화면으로 전환
            });
          },
          child: const Icon(
            Icons.person, // 사람 모양의 아이콘
            color: Colors.white,
            size: 30,
          ),
        ),
        title: Text(
          _userName, // Firestore에서 불러온 사용자 이름 표시
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) {
              if (value == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChattingScreen()),
                );
              } else if (value == 5) {
                _logout(); // 로그아웃 처리
              } else {
                _onItemTapped(value); // 화면 전환
              }
            },
            icon: Icon(
              Icons.more_vert, // 원하는 아이콘 사용
              color: Colors.white, // 아이콘 색을 하얀색으로 설정
            ),
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
      body: _getBody(), // 선택된 화면 위젯
    );
  }
}
