import 'dart:math';
import 'package:flutter/material.dart';
import 'package:classapp_election/widgets/candidate_layout.dart';

// vote_setting_bar.dart를 더 이상 사용하지 않습니다.

class ResultPage extends StatelessWidget {
  final String title;
  final int columnCount;
  final List<List<TextEditingController>> descriptionColumns;
  final List<List<TextEditingController>> candidateColumns;
  final List<Color> candidateColors;
  final List<Color> fontColors;
  final List<List<int>> voteResults;

  const ResultPage({
    super.key,
    required this.title,
    required this.columnCount,
    required this.descriptionColumns,
    required this.candidateColumns,
    required this.candidateColors,
    required this.fontColors,
    required this.voteResults,
  });

  @override
  Widget build(BuildContext context) {
    // 하단 바에 전달할 총 투표 수를 계산
    int totalVoteCount = 0;
    if (voteResults.isNotEmpty) {
      totalVoteCount = voteResults
          .expand((votes) => votes)
          .fold(0, (sum, item) => sum + item);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("$title 최종 결과", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
        toolbarHeight: 70,
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: List.generate(columnCount, (colIdx) {
                return Expanded(
                  child: _buildResultColumnWidget(colIdx),
                );
              }),
            ),
          ),
          // [핵심 수정] VoteSettingsBar 대신 자체 제작한 하단 바 위젯을 호출
          _buildResultBottomBar(context, totalVoteCount),
        ],
      ),
    );
  }

  // 각 선거(열)를 구성하는 위젯
  Widget _buildResultColumnWidget(int colIdx) {
    int maxVotes = 0;
    if (voteResults[colIdx].isNotEmpty) {
      maxVotes = voteResults[colIdx].reduce(max);
    }

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              columnIndex: colIdx,
              columnCount: columnCount,
              candidates: candidateColumns[colIdx],
              backgroundColor: candidateColors[colIdx],
              fontColor: fontColors[colIdx],
              voteResults: voteResults[colIdx],
              isResultMode: true,
              isVotingMode: false,
              maxVotes: maxVotes,
              onTapCandidate: (candiIdx) {},
              onDeleteCandidate: (index) {},
            ),
          ),
        ],
      ),
    );
  }

  // [새로운 기능] 결과 페이지 전용 하단 바 UI를 직접 그리는 함수
  Widget _buildResultBottomBar(BuildContext context, int totalVoteCount) {
    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 총 투표 수
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('총 투표 수', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('$totalVoteCount 표', style: const TextStyle(fontSize: 32, color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
          // 투표 상태
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('투표 상태', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('투표 완료', style: TextStyle(fontSize: 32, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
