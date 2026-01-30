import 'package:flutter/material.dart';
import 'package:classapp_election/widgets/candidate_layout.dart';

class ResultPage extends StatelessWidget {
  final String title;
  final int columnCount;
  final List<List<TextEditingController>> descriptionColumns;
  final List<List<TextEditingController>> candidateColumns;
  final List<Color> candidateColors;
  final List<Color> fontColors;
  final List<List<int>> voteResults; // 최종 투표 결과 데이터

  const ResultPage({
    super.key,
    required this.title,
    required this.columnCount,
    required this.descriptionColumns,
    required this.candidateColumns,
    required this.candidateColors,
    required this.fontColors,
    required this.voteResults, // 생성자를 통해 결과 데이터를 받음
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        // [수정] main.dart로 돌아갈 수 있도록 뒤로가기 버튼을 자동으로 생성
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // [수정] 제목에 ' 최종 결과' 텍스트 추가
        title: Text("$title 최종 결과", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
        toolbarHeight: 70,
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: List.generate(columnCount, (colIdx) {
                return Expanded(
                  // [핵심] 결과 컬럼을 만드는 위젯 호출
                  child: _buildResultColumnWidget(colIdx),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // 결과를 표시하는 컬럼 위젯
  Widget _buildResultColumnWidget(int colIdx) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent, width: 6.0),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 25),
          Text(
            descriptionColumns[colIdx].map((e) => e.text).join(" "),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF134686)),
          ),
          const Divider(height: 30),
          Expanded(
            child: CandidateLayout(
              // CandidateLayout에 결과 데이터를 전달
              columnIndex: colIdx,
              columnCount: columnCount,
              candidates: candidateColumns[colIdx],
              backgroundColor: candidateColors[colIdx],
              fontColor: fontColors[colIdx],
              voteResults: voteResults[colIdx], // [핵심] 해당 단의 득표수 리스트 전달
              isResultMode: true, // [핵심] 결과 모드 활성화
              isVotingMode: false,
              onTapCandidate: (candiIdx) {},
              onDeleteCandidate: (index) {},
            ),
          ),
        ],
      ),
    );
  }
}
