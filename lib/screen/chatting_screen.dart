import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChattingScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChattingScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      final user = _auth.currentUser;
      if (user != null) {
        // Firestore에 메시지 저장
        _firestore.collection('chats').add({
          'text': _controller.text,
          'createdAt': Timestamp.now(),
          'userId': user.uid, // 현재 사용자의 ID
        });
        _controller.clear(); // 메시지 입력창 초기화
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅방'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 채팅 메시지 표시
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats') // 'chats' 컬렉션에서 데이터를 가져옵니다.
                  .orderBy('createdAt', descending: true) // createdAt 필드를 기준으로 내림차순으로 정렬
                  .snapshots(), // 실시간 데이터 스트림
              builder: (ctx, chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator()); // 데이터 로딩 중
                }

                if (!chatSnapshot.hasData) {
                  return Center(child: Text('No messages yet.')); // 메시지가 없을 때
                }

                final chatDocs = chatSnapshot.data!.docs; // 채팅 데이터
                return ListView.builder(
                  reverse: true, // 최신 메시지가 위에 보이도록 설정
                  itemCount: chatDocs.length,
                  itemBuilder: (ctx, index) {
                    final chatData = chatDocs[index].data() as Map<String, dynamic>;
                    final userId = chatData['userId']; // 메시지 보낸 사용자 ID
                    final message = chatData['text']; // 메시지 내용

                    final isCurrentUser = userId == _auth.currentUser?.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: isCurrentUser
                            ? MainAxisAlignment.end // 현재 사용자의 메시지는 오른쪽
                            : MainAxisAlignment.start, // 상대방의 메시지는 왼쪽
                        children: [
                          if (!isCurrentUser)
                            CircleAvatar(
                              child: Text(
                                  userId[0].toUpperCase()), // 상대방의 첫 글자 아바타
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 15.0),
                            margin: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 10.0),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Colors.blue
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: isCurrentUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCurrentUser
                                      ? 'You'
                                      : 'Other User', // 보내는 사람 표시
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  message,
                                  style: TextStyle(
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrentUser)
                            CircleAvatar(
                              child: Text(
                                  'Y'), // 본인 아바타 (여기서 'Y'는 예시로 넣은 값입니다)
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
                    controller: _controller,
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
}
