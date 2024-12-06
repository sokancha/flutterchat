import 'package:chatapp/screen/chatting_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class TimePage extends StatefulWidget {
  final String title; // 버튼에서 받은 제목을 전달받음

  const TimePage({Key? key, required this.title}) : super(key: key);

  @override
  _TimePageState createState() => _TimePageState();
}

class _TimePageState extends State<TimePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 시간 데이터를 생성하는 메서드
  List<String> _generateTimeSlots() {
    List<String> times = [];
    for (int hour = 8; hour <= 20; hour++) {
      times.add('$hour:00');
      if (hour < 20) {
        times.add('$hour:30');
      }
    }
    return times;
  }
  void _navigateToChattingScreen(String time) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChattingScreen(
          times: time,
          title: widget.title, // TimePage에서 받은 제목 전달
        ),
      ),
    );
  }
  // 메시지를 Firebase에 저장하는 메서드
  Future<void> _sendVoteMessage(String time) async {
    final user = _auth.currentUser;
    if (user != null) {
      // 사용자 이름 가져오기
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc['name'] ?? '사용자';

      // 메시지 전송
      await _firestore.collection('chats').add({
        'text': '${time}시에 ${widget.title} 어떤데~',
        'createdAt': Timestamp.now(),
        'username': userName,
        'userId': user.uid,
        'color': '#000000',
        'isActivityMessage': true, // 자동 생성 메시지임을 표시
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    final times = _generateTimeSlots(); // 시간 목록 생성

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // 전달받은 title을 AppBar에 표시
      ),
      body: ListView.builder(
        itemCount: times.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () async {
                // 시간 선택 시 Firebase에 메시지 저장
                await _sendVoteMessage(times[index]);
                _navigateToChattingScreen(times[index]);
                // 선택 완료 후 사용자에게 알림
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text('채팅방에 메세지를 보냈습니다'),
                    actions: [
                      TextButton(
                        onPressed: () {

                          Navigator.pop(context); // 다이얼로그 닫기
                        },
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              },
              child: Text(times[index],style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),), // 시간 텍스트 표시 // 시간 텍스트 표시
            ),
          );
        },
      ),
    );
  }
}
