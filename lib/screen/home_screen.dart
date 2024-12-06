import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import 'package:chatapp/screen/play.dart'; // play.dart의 PlayScreen 가져오기
import 'package:chatapp/screen/login_signup_screen.dart';
import 'package:chatapp/screen/chatting_screen.dart';
import 'package:chatapp/config/palette.dart';
import 'package:chatapp/screen/food.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_side_sheet/modal_side_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:math';
import 'package:google_sign_in/google_sign_in.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 현재 선택된 네비게이션 탭 인덱스
  String _userName = ''; // Firestore에서 가져온 사용자 이름
  String _userProfilePicUrl = ''; // 구글에서 가져온 사용자 프로필 사진 URL
  late GoogleMapController _mapController; // 구글 맵 컨트롤러
  List<String> _nearbyUsers = []; // 근처 사용자 목록
  LatLng? _currentPosition; // 현재 위치 저장 (초기화 전에는 null)

  final GoogleSignIn _googleSignIn = GoogleSignIn(); // 구글 로그인 객체
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance; // Firebase Auth 객체

  @override
  void initState() {
    super.initState();
    _checkLocationPermission(); // 위치 권한 확인 및 요청
    _getGoogleUserInfo(); // 구글 사용자 정보 가져오기
    _getUserInfo();
  }

  // 구글 사용자 정보 가져오기
  Future<void> _getGoogleUserInfo() async {
    try {
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Firebase 인증
        firebase_auth.UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
        firebase_auth.User? user = userCredential.user;

        if (user != null) {
          // 프로필 정보가 없을 경우 기본값 처리
          String userName = user.displayName ?? '사용자 이름 없음';
          String userProfilePicUrl = user.photoURL ?? 'https://example.com/default_profile_pic.png'; // 기본 프로필 사진 URL

          // Firestore에 구글 사용자 정보 업데이트
          _updateUserInfoInFirestore(userName, userProfilePicUrl);

          // 상태 업데이트
          setState(() {
            _userName = userName;
            _userProfilePicUrl = userProfilePicUrl;
          });
        }
      }
    } catch (error) {
      print("구글 사용자 정보 가져오기 실패: $error");
    }
  }

  // Firestore에 사용자 정보 업데이트
  void _updateUserInfoInFirestore(String userName, String userProfilePicUrl) async {
    firebase_auth.User? user = _firebaseAuth.currentUser;
    if (user != null) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      GeoPoint location = GeoPoint(position.latitude, position.longitude);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': userName,
        'profilePicUrl': userProfilePicUrl,
        'lastLogin': Timestamp.now(),
        'location': location, // 위치 정보 추가
      }, SetOptions(merge: true)); // 기존 정보와 병합
    }
  }


  // 위치 권한 확인 및 요청
  Future<void> _checkLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocationAndFetchNearbyUsers();
    } else {
      // 권한이 거부된 경우 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 권한이 필요합니다. 설정에서 위치 권한을 허용해주세요.')),
      );
    }
  }

  // Firestore에서 사용자 정보 가져오기
  void _getUserInfo() async {
    firebase_auth.User? user = _firebaseAuth.currentUser;
    if (user != null) {
      // Firestore에서 사용자 데이터 읽기
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') // 컬렉션 이름은 Firestore에 맞게 수정
          .doc(user.uid) // 문서 ID로 사용자 UID 사용
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'] ?? '사용자'; // name 필드 읽기, 없으면 기본값 '사용자'
          _userProfilePicUrl = userDoc['profilePicUrl'] ?? '';

        });
      }
    }
  }

  // 현재 위치를 가져와 Firestore에서 근처 사용자 가져오기
  Future<void> _getCurrentLocationAndFetchNearbyUsers() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    double userLat = position.latitude;
    double userLng = position.longitude;

    firebase_auth.User? user = _firebaseAuth.currentUser;
    if (user != null) {
      // 사용자 위치 Firestore에 저장
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('locations').add(
        {
          'location': GeoPoint(userLat, userLng),
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      // 근처 사용자 쿼리 (예: 10km 이내)
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      List<String> nearbyUsers = [];
      for (var userDoc in querySnapshot.docs) {
        if (userDoc.id == user.uid) continue; // 본인 제외

        // 사용자 하위 컬렉션 'locations'에서 최신 위치 정보 가져오기
        QuerySnapshot locationSnapshot = await userDoc.reference
            .collection('locations')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (locationSnapshot.docs.isNotEmpty) {
          var locationData = locationSnapshot.docs.first;
          GeoPoint geoPoint = locationData['location'];
          double distance = _calculateDistance(userLat, userLng, geoPoint.latitude, geoPoint.longitude);
          if (distance <= 10000) { // 10km 이내 사용자 필터링
            nearbyUsers.add(userDoc['name']);
          }
        }
      }

      setState(() {
        _nearbyUsers = nearbyUsers;
      });
    }
  }

  // 두 지점 사이의 거리 계산 (단위: 미터)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371000; // 지구 반경 (미터)
    double phi1 = lat1 * (pi / 180);
    double phi2 = lat2 * (pi / 180);
    double deltaPhi = (lat2 - lat1) * (pi / 180);
    double deltaLambda = (lon2 - lon1) * (pi / 180);

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
  Future<void> _logout() async {
    try {
      // 카카오톡 로그아웃
      try {
        var isKakaoLoggedIn = await _checkKakaoLogin();
        if (isKakaoLoggedIn) {
          await UserApi.instance.logout();
          print('카카오 로그아웃 성공');
        } else {
          print('카카오는 로그인되지 않음');
        }
      } catch (error) {
        print('카카오 로그아웃 오류: $error');
      }

      // 구글 로그아웃
      GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
      if (googleUser != null) {
        await _googleSignIn.signOut();
        print('구글 로그아웃 성공');
      } else {
        print('구글은 로그인되지 않음');
      }

      // Firebase 로그아웃
      firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await _firebaseAuth.signOut();
        print('Firebase 로그아웃 성공');
      } else {
        print('Firebase는 로그인되지 않음');
      }

      // 로그아웃 후 로그인 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
      );
    } catch (error) {
      print('로그아웃 중 오류 발생: $error');
    }
  }

  // 카카오 로그인 상태 확인
  Future<bool> _checkKakaoLogin() async {
    try {
      // 카카오의 accessTokenInfo를 사용하여 로그인 상태 확인
      final tokenInfo = await UserApi.instance.accessTokenInfo();
      return tokenInfo != null;
    } catch (e) {
      // accessToken이 만료되거나 로그인되지 않은 경우 예외가 발생하므로 false 반환
      return false;
    }
  }


  // 화면 별 위젯 반환
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
        return const FoodScreen();
      default:
        return const Center(
          child: Text(
            '알 수 없는 화면',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
    }
  }




  // 홈 화면 빌드 (근처 사용자 목록 표시 및 현재 위치 지도 표시)
  Widget _buildHomeScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userName),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 250, // 지도 높이를 250으로 지정 (크기를 줄이기 위해 설정)
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? LatLng(36.83423, 127.1793),
                zoom: 14,
              ),
              myLocationEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
          ),
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
        leading: _userProfilePicUrl.isEmpty
            ? GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = 0; // 홈 화면으로 전환
            });
          },
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 30,
          ),
        )
            : SizedBox.shrink(), // 프로필이 있을 경우 아이콘을 숨깁니다
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start, // 왼쪽 정렬
          children: [
            if (_userProfilePicUrl.isNotEmpty)
              CircleAvatar(
                backgroundImage: NetworkImage(_userProfilePicUrl),
                radius: 20, // 크기 조정
              ),
            const SizedBox(width: 8),
            Text(
              _userName, // 구글 사용자 이름
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert, // 원하는 아이콘 사용
              color: Colors.white, // 아이콘 색을 하얀색으로 설정
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Align(
                    alignment: Alignment.topCenter, // 모달을 화면 상단에 배치 (위치 조정)
                    child: Container(
                      margin: const EdgeInsets.only(top: 20.0), // 모달 전체를 아래로 100포인트 이동
                      padding: const EdgeInsets.all(16.0),
                      height: 500, // 모달 높이 지정
                      child: ListView(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.chat),
                            title: const Text('채팅'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const ChattingScreen(
                                      times: '10:30 AM',
                                      title: '영화 감상',
                                    )),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.gamepad),
                            title: const Text('놀거리'),
                            onTap: () {
                              Navigator.pop(context);
                              _onItemTapped(2);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.restaurant),
                            title: const Text('음식점'),
                            onTap: () {
                              Navigator.pop(context);
                              _onItemTapped(3);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('로그아웃'),
                            onTap: () {
                              Navigator.pop(context);
                              _logout();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _getBody(), // 선택된 화면 위젯
    );
  }
}
