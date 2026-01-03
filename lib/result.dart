import 'package:flutter/material.dart';
import 'package:classapp_election/widgets/candidate_layout.dart';

class ResultPage extends StatelessWidget {
  final String title;
  final int columnCount;
  final List<List<TextEditingController>> candidateColumns;
  final List<List<TextEditingController>> descriptionColumns;
  final List<Color> candidateColors;
  final List<Color> fontColors;

  // 가상의 투표 결과 데이터 (후보자별 index에 매칭되는 득표수 리스트)
  // 예: [[3, 5], [2, 1]] -> 1단 후보들 득표, 2단 후보들 득표
  final List<List<int>> votes;

  const ResultPage({
    super.key,
    required this.title,
    required this.columnCount,
    required this.candidateColumns,
    required this.descriptionColumns,
    required this.candidateColors,
    required this.fontColors,
    this.votes = const [], // 실제 데이터가 넘어오지 않을 경우 대비
  });

  @override
  Widget build(BuildContext context) {
    // 1. 전체 후보 중 최고 득표수 찾기 (공동 1위 포함)
    int maxVotes = 0;
    for (var colVotes in votes) {
      for (var v in colVotes) {
        if (v > maxVotes) maxVotes = v;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          // 상단 타이틀 바
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            color: Colors.white,
            width: double.infinity,
            height: 60,
            child: Center(
              child: Text("$title - 투표 결과",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
          ),
          const Divider(height: 1),

          // 후보자 영역
          Expanded(
            child: Row(
              children: List.generate(columnCount, (colIndex) {
                int totalCandidates = candidateColumns[colIndex].length;
                bool isSpecialLayout = (columnCount == 1 && totalCandidates == 1);

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(descriptionColumns[colIndex].first.text,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Row(
                            children: [
                              if (isSpecialLayout) const Spacer(flex: 25),
                              Expanded(
                                flex: isSpecialLayout ? 50 : 100,
                                child: CandidateLayout(
                                  columnIndex: colIndex,
                                  columnCount: columnCount,
                                  candidates: candidateColumns[colIndex],
                                  backgroundColor: candidateColors[colIndex],
                                  fontColor: fontColors[colIndex],
                                  isVotingMode: true,

                                  // [추가된 속성들] - CandidateLayout 위젯 수정 필요
                                  votes: votes.isNotEmpty ? votes[colIndex] : List.filled(totalCandidates, 0),
                                  maxVotes: maxVotes,

                                  onTapCandidate: (idx) {},
                                  onDeleteCandidate: (idx) {},
                                ),
                              ),
                              if (isSpecialLayout) const Spacer(flex: 25),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Center(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home, color: Colors.white),
            label: const Text('메인 화면으로 돌아가기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF134686),
              minimumSize: const Size(250, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
