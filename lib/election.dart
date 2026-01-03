import 'package:flutter/material.dart';
import 'package:classapp_election/widgets/candidate_layout.dart';
import 'package:classapp_election/widgets/candidate_card.dart';

class ElectionPage extends StatefulWidget {
  final String title;
  final int totalVoteCount;
  final int columnCount;
  final List<List<TextEditingController>> descriptionColumns;
  final List<List<TextEditingController>> candidateColumns;
  final List<Color> candidateColors;
  final List<Color> fontColors;

  const ElectionPage({
    super.key,
    required this.title,
    required this.totalVoteCount,
    required this.columnCount,
    required this.descriptionColumns,
    required this.candidateColumns,
    required this.candidateColors,
    required this.fontColors,
  });

  @override
  State<ElectionPage> createState() => _ElectionPageState();
}

class _ElectionPageState extends State<ElectionPage> {
  int currentVoterIndex = 1;

  // --- 이 부분을 추가하세요 ---
  @override
  void initState() {
    super.initState();
    print("==============================");
    print("📢 election.dart 페이지로 전환됨");
    print("==============================");
  }
  // -----------------------

  @override
  Widget build(BuildContext context) {
    int totalCandidates = widget.candidateColumns.fold(0, (sum, col) => sum + col.length);
    bool isSpecialSingleLayout = (widget.columnCount == 1 && totalCandidates == 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0, // [추가] 스크롤 시 배경색/여백 변함 방지
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 0,
          ),
        ),
        shape: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        toolbarHeight: 70,
      ),
      body: Column(
        children: [
          // [추가] AppBar와 첫 번째 후보자 구역 사이의 여백 (main.dart와 일치시키기 위한 공간)
          const SizedBox(height: 8),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(widget.candidateColumns.length, (colIdx) {
                return Expanded(
                  child: Container(
                    // [수정] main.dart와 동일하게 마진을 8.0으로 조정
                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    // [수정] 내부 패딩을 16으로 조정하여 버튼 공간 확보
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12), // [수정] 16 -> 12로 변경 (main.dart 기준)
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        // 제목(설명) 위젯 부분
                        Text(
                          widget.descriptionColumns[colIdx].map((e) => e.text).join(" "),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF134686)
                          ),
                        ),
                        const SizedBox(height: 16), // [일치] main.dart와 동일한 간격
                        const Divider(),             // [일치]
                        const SizedBox(height: 16), // [일치]

                        Expanded(
                          child: Row(
                            children: [
                              if (isSpecialSingleLayout) const Spacer(flex: 25),
                              Expanded(
                                flex: isSpecialSingleLayout ? 50 : 100,
                                child: _buildCandiLayout(colIdx),
                              ),
                              if (isSpecialSingleLayout) const Spacer(flex: 25),
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

          // [추가] 후보자 구역과 하단 설정바 사이의 간격
          const SizedBox(height: 8),

          // 하단 바 디자인
          Container(
            height: 100,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF134686).withOpacity(0.5), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin, color: Color(0xFF134686), size: 28),
                      const SizedBox(width: 10),
                      Text("현재 $currentVoterIndex번째 투표자",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF134686))),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Text("/  전체 ${widget.totalVoteCount}명",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandiLayout(int colIdx) {
    return CandidateLayout(
      columnIndex: colIdx,
      columnCount: widget.columnCount,
      candidates: widget.candidateColumns[colIdx],
      backgroundColor: widget.candidateColors[colIdx],
      fontColor: widget.fontColors[colIdx],
      isVotingMode: true,
      onTapCandidate: (index) {
        // 투표 선택 로직
      },
      onDeleteCandidate: (index) {},
    );
  }
}
