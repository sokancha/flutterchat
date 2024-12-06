import 'package:flutter/material.dart';
import 'package:chatapp/component/time_page.dart'; // TimePage를 가져옴.
import 'package:chatapp/screen/chatting_screen.dart';

class FoodScreen extends StatelessWidget {
  const FoodScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색을 흰색으로 설정
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: foodOptions.length, // 버튼 개수
            itemBuilder: (context, index) {
              final option = foodOptions[index];
              return _buildFoodButton(context, option['title'], option['pageNumber']);
            },
          ),
        ),
      ),
    );
  }

  // 버튼 생성 함수
  Widget _buildFoodButton(BuildContext context, String title, int pageNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // 버튼 간격
      child: ElevatedButton(
        onPressed: () {
          // 버튼 클릭 시 TimePage로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TimePage(title: title), // 제목을 전달
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10.0), // 버튼 크기 조정
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // 텍스트 크기 조정
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // 모서리를 0으로 설정해 직사각형으로 변경
          ),
        ),
        child: Text(title), // 버튼 텍스트
      ),
    );
  }
}

// 놀거리 옵션 리스트
final List<Map<String, dynamic>> foodOptions = [
  {'title': '한솥 도시락', 'pageNumber': 1},
  {'title': '서브밀', 'pageNumber': 2},
  {'title': '호호맛집', 'pageNumber': 3},
  {'title': '한신우동', 'pageNumber': 4},
  {'title': '코코스낵', 'pageNumber': 5},
  {'title': '피자스쿨', 'pageNumber': 6},
  {'title': '장인국밥', 'pageNumber': 7},
  {'title': '별이네 밥집', 'pageNumber': 8},
  {'title': '하이린', 'pageNumber': 9},
];
