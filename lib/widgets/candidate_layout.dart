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

  // [추가 필드]
  final int? selectedCandidateIndex;
  final bool showSelectionBorder;

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
    this.selectedCandidateIndex,    // 부모(ElectionPage)로부터 전달받음
    this.showSelectionBorder = false, // 부모(ElectionPage)로부터 전달받음
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

    int rowCount = (totalCandidates / 2).ceil();
    if (rowCount < 4) {
      for (int i = 0; i < (4 - rowCount); i++) {
        rows.add(Expanded(child: Container()));
      }
    }
    return Column(children: rows);
  }

  // 단일 레이아웃 로직
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

  // 개별 후보자 카드 생성
  Widget _buildExpandedCard(int index) {
    final bool isWinner = votes != null &&
        votes![index] > 0 &&
        votes![index] == maxVotes;

    // [중요] 현재 카드가 선택된 상태인지 확인
    final bool isSelected = selectedCandidateIndex == index;

    return Expanded(
      child: CandidateCard(
        index: index,
        name: candidates[index].text,
        backgroundColor: backgroundColor,
        fontColor: fontColor,
        voteCount: votes != null ? votes![index] : null,
        isWinner: isWinner,
        // [추가] 선택 상태와 테두리 표시 옵션을 하위 위젯으로 전달
        isSelected: isSelected,
        showSelectionBorder: showSelectionBorder,
        onTap: () => onTapCandidate(index),
        onDelete: isVotingMode ? null : () => onDeleteCandidate(index),
      ),
    );
  }
}
