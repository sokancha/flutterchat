import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/screen/login_signup_screen.dart';

class ChattingScreen extends StatefulWidget {
  const ChattingScreen({Key? key}) : super(key: key);

  @override
  _ChattingScreenState createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<ChattingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  // Firestore에서 사용자 이름 가져오기
  void _getUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'] ?? '사용자';
        });
      }
    }
  }

  // 메시지 전송 메서드
  Future<void> _sendMessage({String? predefinedMessage}) async {
    final user = _auth.currentUser;
    if (user != null && (predefinedMessage != null || _messageController.text.trim().isNotEmpty)) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userName = userDoc['name'];

        await _firestore.collection('chats').add({
          'text': predefinedMessage ?? _messageController.text.trim(),
          'createdAt': Timestamp.now(),
          'username': userName,
          'userId': user.uid,
          'type': 'text',
        });
        _messageController.clear();
      }
    }
  }

  Future<void> _sendButtonMessage(String buttonText) async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userName = userDoc['name'];

        await _firestore.collection('chats').add({
          'text': buttonText,
          'createdAt': Timestamp.now(),
          'username': userName,
          'userId': user.uid,
          'type': 'button', // 메시지 타입을 버튼으로 설정
        });
      }
    }
  }

  Future<void> _sendLikeMessage() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userName = userDoc['name'];

        await _firestore.collection('chats').add({
          'text': '좋아요!',
          'createdAt': Timestamp.now(),
          'username': userName,
          'userId': user.uid,
          'type': 'like', // 메시지 타입을 좋아요로 설정
        });
      }
    }
  }

  void _showCustomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('옵션 선택'),
        content: SizedBox(
          height: 100,
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  // 첫 번째 버튼 클릭 시 버튼 메시지 전송
                  Navigator.of(ctx).pop();
                  _sendButtonMessage('확인 버튼');
                },
                child: const Text('확인 버튼 보내기'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('옵션 2'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('닫기'),
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
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 30,
          ),
        ),
        title: Text(
          _userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCustomDialog(context); // 새 버튼을 눌렀을 때 팝업 창 호출
            },
            tooltip: '옵션 추가',
          ),
        ],
      ),
      body: Column(
        children: [
          // 채팅 메시지 표시
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (ctx, chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                final chatDocs = chatSnapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: chatDocs.length,
                  itemBuilder: (ctx, index) {
                    final chatData = chatDocs[index].data() as Map<String, dynamic>;
                    final username = chatData['username'] ?? 'Unknown User';
                    final isCurrentUser = chatData['userId'] == _auth.currentUser?.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                      child: Column(
                        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          // 이름 표시
                          Text(
                            username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCurrentUser ? Colors.blue : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 메시지 박스 또는 버튼
                          if (chatData['type'] == 'button')
                            ElevatedButton(
                              onPressed: () {
                                // 버튼 클릭 시 "좋아요!" 메시지 전송
                                _sendLikeMessage();
                              },
                              child: Text(chatData['text']),
                            )
                          else if (chatData['type'] == 'like')
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                chatData['text'],
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                              decoration: BoxDecoration(
                                color: isCurrentUser ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                chatData['text'],
                                style: TextStyle(
                                  color: isCurrentUser ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // 메시지 입력 필드
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: '메시지를 입력하세요...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 로그아웃 처리
  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
    );
  }
}
