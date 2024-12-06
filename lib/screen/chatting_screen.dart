import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/screen/login_signup_screen.dart';



class ChattingScreen extends StatefulWidget {
  final String times;
  final String title;
  const ChattingScreen({Key? key,
    required this.times,
    required this.title,
  }) : super(key: key);


  @override
  _ChattingScreenState createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<ChattingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userName = '';

  final List<String> _emojiList = [
    '😊', '😂', '😍', '🥺', '😎', '😢', '🤔', '😡', '🥳', '😜',
    '🤩', '😏', '😇', '🙃', '🥰', '😱', '🤭', '😴', '😷', '😈',
    '🥶', '💀', '👀', '👋', '👏', '✌️', '💪', '🙏', '❤️', '💔',
    '💯', '🔥', '🌸', '🌼', '🎉', '🌈', '🌙', '⭐', '⚡', '🌻', '🌞',
  ];

  // 이모티콘 패널의 상태
  bool _isEmojiPanelVisible = false;

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
  Future<void> _sendMessage() async {
    final user = _auth.currentUser;
    if (user != null && _messageController.text.trim().isNotEmpty) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userName = userDoc['name'];

        await _firestore.collection('chats').add({
          'text': _messageController.text.trim(),
          'createdAt': Timestamp.now(),
          'username': userName,
          'userId': user.uid,
          'isActivityMessage': false, // 기본 메시지는 일반 메시지로 저장
        });
        _messageController.clear();
      }
    }
  }
  Future<void> _sendLikeOrDislikeMessage(
      String action, String originalMessage, String originalUserName) async {
    final user = _auth.currentUser;
    if (user != null) {
      String color = action == '좋아요' ? '#008000' : '#FF0000'; // 좋아요는 green, 싫어요는 red
      await _firestore.collection('chats').add({
        'text': '$originalUserName가 보낸 "$originalMessage" 메시지에 대해 $_userName는 $action!',
        'createdAt': Timestamp.now(),
        'username': _userName,
        'userId': user.uid,
        'color': color,
        'isActivityMessage': false, // 좋아요/싫어요 메시지임을 표시
      });
    }
  }
  void _addEmoji(String emoji) {
    setState(() {
      _messageController.text += emoji; // 이모티콘 추가
    });
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
                    final isActivityMessage = chatData['isActivityMessage'] ?? false;
                    final messageColor = chatData['color'] ?? '#000000';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                      child: Column(
                        crossAxisAlignment:
                        isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                          // 메시지 박스
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                            decoration: BoxDecoration(
                              color: isActivityMessage ? Color(0xFF90EE90) : (isCurrentUser ? Colors.blue : Colors.grey[300]),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 메시지 내용
                                Text(
                                  chatData['text'],
                                  style: TextStyle(
                                    color: Color(int.parse('0xFF' + messageColor.substring(1))),
                                    fontSize: isActivityMessage ? 20.0 : 14.0,
                                    fontWeight: isActivityMessage ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                // 좋아요/싫어요 버튼
                                if (isActivityMessage) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.thumb_up, color: Colors.green),
                                        onPressed: () async {
                                          await _sendLikeOrDislikeMessage(
                                              '좋아요', chatData['text'], username);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.thumb_down, color: Colors.red),
                                        onPressed: () async {
                                          await _sendLikeOrDislikeMessage(
                                              '싫어요', chatData['text'], username); // 싫어요 클릭 시 메시지 전송
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
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
                IconButton(
                  icon: const Icon(Icons.emoji_emotions),
                  onPressed: () {
                    setState(() {
                      _isEmojiPanelVisible = !_isEmojiPanelVisible; // 이모티콘 패널 토글
                    });
                  },
                ),
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
          // 이모티콘 패널 (보여주기/숨기기)
          if (_isEmojiPanelVisible)
            Container(
              height: 100, // 높이를 적당히 조절하여 UI 개선
              color: Colors.grey[200],
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // 한 줄에 7개로 늘려서 더 촘촘하게 배치
                  crossAxisSpacing: 4.0, // 수평 간격 줄이기
                  mainAxisSpacing: 4.0, // 수직 간격 줄이기
                ),
                itemCount: _emojiList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _addEmoji(_emojiList[index]),
                    child: Center(child: Text(_emojiList[index], style: TextStyle(fontSize: 30))),
                  );
                },
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
