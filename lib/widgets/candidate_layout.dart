import 'package:flutter/material.dart';
import 'candidate_card.dart';

class CandidateLayout extends StatelessWidget {
  final int columnIndex;
  final int columnCount;
  final List<TextEditingController> candidates;
  final List<int>? votes;
  final int? maxVotes;
  final Color backgroundColor;
  final Color fontColor;
  final Function(int index) onTapCandidate;
  final Function(int index) onDeleteCandidate;
  final bool isVotingMode;

  const CandidateLayout({
    super.key,
    required this.columnIndex,
    required this.columnCount,
    required this.candidates,
    required this.backgroundColor,
    required this.fontColor,
    required this.onTapCandidate,
    required this.onDeleteCandidate,
    required this.isVotingMode,
    this.votes,
    this.maxVotes,
  });

  @override
  Widget build(BuildContext context) {
    final int totalCandidates = candidates.length;

    if (totalCandidates == 0) {
      return const Center(
        child: Text("후보를 추가해주세요", style: TextStyle(color: Colors.grey)),
      );
    }

    // 2표제 이상 (다단 레이아웃)
    if (columnCount > 1) {
      return _buildMultiColumnGrid(totalCandidates);
    }
    // 1표제 (단일 레이아웃)
    else {
      return _buildSingleColumnGrid(totalCandidates);
    }
  }

  // 다단 레이아웃 로직
  Widget _buildMultiColumnGrid(int totalCandidates) {
    List<Widget> rows = [];
    for (int i = 0; i < totalCandidates; i += 2) {
      List<Widget> rowItems = [];
      rowItems.add(_buildExpandedCard(i));

      if (i + 1 < totalCandidates) {
        rowItems.add(_buildExpandedCard(i + 1));
      } else {
        rowItems.add(Expanded(child: Container()));
      }
      rows.add(Expanded(child: Row(children: rowItems)));
    }

    // 최소 4줄 유지 로직
    int rowCount = (totalCandidates / 2).ceil();
    if (rowCount < 4) {
      for (int i = 0; i < (4 - rowCount); i++) {
        rows.add(Expanded(child: Container()));
      }
    }
    return Column(children: rows);
  }

  // 단일 레이아웃 로직 (1~8인 이상)
  Widget _buildSingleColumnGrid(int totalCandidates) {
    if (totalCandidates <= 3) {
      return Center(
        child: FractionallySizedBox(
          heightFactor: 0.4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(totalCandidates, (i) => _buildExpandedCard(i)),
          ),
        ),
      );
    }

    // 4인 이상 격자 계산 로직
    List<int> candidatesPerRow;
    int maxItems;
    if (totalCandidates == 4) { candidatesPerRow = [2, 2]; maxItems = 2; }
    else if (totalCandidates == 5) { candidatesPerRow = [2, 3]; maxItems = 3; }
    else if (totalCandidates == 6) { candidatesPerRow = [3, 3]; maxItems = 3; }
    else if (totalCandidates == 7) { candidatesPerRow = [3, 4]; maxItems = 4; }
    else if (totalCandidates == 8) { candidatesPerRow = [4, 4]; maxItems = 4; }
    else {
      int base = (totalCandidates / 3).ceil();
      maxItems = base;
      candidatesPerRow = [];
      int rem = totalCandidates;
      while (rem > 0) {
        int count = rem >= base ? base : rem;
        candidatesPerRow.add(count);
        rem -= count;
      }
    }

    int currentIndex = 0;
    List<Widget> rowWidgets = [];
    for (int count in candidatesPerRow) {
      List<Widget> rowItems = [];
      for (int i = 0; i < count; i++) {
        rowItems.add(_buildExpandedCard(currentIndex++));
      }
      // 정렬용 빈칸
      if (count < maxItems) {
        int diff = maxItems - count;
        for (int i = 0; i < diff; i++) {
          if (i.isEven) rowItems.add(Expanded(child: Container()));
          else rowItems.insert(0, Expanded(child: Container()));
        }
      }
      rowWidgets.add(Expanded(child: Row(children: rowItems)));
    }
    return Column(children: rowWidgets);
  }

  // _buildExpandedCard 메서드 수정
  Widget _buildExpandedCard(int index) {
    // 현재 후보가 1위인지 확인 (득표수가 있고, 0보다 크며, 최고 득표수와 같은 경우)
    final bool isWinner = votes != null &&
        votes![index] > 0 &&
        votes![index] == maxVotes;

    return Expanded(
      child: CandidateCard(
        index: index,
        name: candidates[index].text,
        backgroundColor: backgroundColor,
        fontColor: fontColor,
        // [추가 속성 전달]
        voteCount: votes != null ? votes![index] : null,
        isWinner: isWinner,
        onTap: () => onTapCandidate(index),
        onDelete: isVotingMode ? null : () => onDeleteCandidate(index),
      ),
    );
  }
}
