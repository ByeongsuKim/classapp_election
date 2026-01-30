import 'package:flutter/material.dart';
import 'candidate_card.dart';

class CandidateLayout extends StatelessWidget {
  // 기본 설정
  final int columnIndex;
  final int columnCount;
  final List<TextEditingController> candidates;
  final Color backgroundColor;
  final Color fontColor;

  // 모드 및 상태 관련
  final bool isVotingMode;
  final bool isResultMode; // 결과 표시 모드

  // 투표 및 결과 데이터
  final List<int>? votes; // 실시간 투표 상황 (당선자 표시용)
  final int? maxVotes;
  final List<int>? voteResults; // 최종 투표 결과 (득표수 표시용)

  // 선택 상태
  final int? selectedCandidateIndex;
  final bool showSelectionBorder;

  // 콜백 함수
  final Function(int index) onTapCandidate;
  final Function(int index) onDeleteCandidate;


  const CandidateLayout({
    // 기본 설정
    required this.columnIndex,
    required this.columnCount,
    required this.candidates,
    required this.backgroundColor,
    required this.fontColor,
    required this.onTapCandidate,
    required this.onDeleteCandidate,

    // 모드 및 상태 관련
    required this.isVotingMode,
    this.isResultMode = false, // 기본값은 false

    // 투표 및 결과 데이터
    this.votes,
    this.maxVotes,
    this.voteResults, // 결과 모드에서 사용

    // 선택 상태
    this.selectedCandidateIndex,
    this.showSelectionBorder = false,

    super.key,
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
    // isWinner 로직은 실시간 투표 상황에만 사용
    final bool isWinner = votes != null &&
        votes!.isNotEmpty &&
        votes![index] > 0 &&
        votes![index] == maxVotes;

    // 현재 카드가 선택된 상태인지 확인 (투표 진행 시)
    final bool isSelected = selectedCandidateIndex == index;

    // [핵심] 결과 모드일 때 보여줄 득표수
    final int? resultVoteCount = isResultMode && voteResults != null && voteResults!.length > index
        ? voteResults![index]
        : null;

    return Expanded(
      child: CandidateCard(
        index: index,
        name: candidates[index].text,
        backgroundColor: backgroundColor,
        fontColor: fontColor,
        // [수정] 결과 모드일 때는 최종 득표수를, 아닐 때는 실시간 득표수를 전달
        voteCount: isResultMode ? resultVoteCount : (votes != null ? votes![index] : null),
        isWinner: isWinner,
        isSelected: isSelected,
        showSelectionBorder: showSelectionBorder,
        onTap: () => onTapCandidate(index),
        // [수정] 투표 모드나 결과 모드에서는 삭제 버튼 비활성화
        onDelete: (isVotingMode || isResultMode) ? null : () => onDeleteCandidate(index),
        // [추가] 결과 모드 여부를 CandidateCard에 전달
        isResultMode: isResultMode,
      ),
    );
  }
}
