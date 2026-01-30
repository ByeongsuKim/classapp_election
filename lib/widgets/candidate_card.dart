import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CandidateCard extends StatelessWidget {
  final int index;
  final String name;
  final Color backgroundColor;
  final Color fontColor;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final int? voteCount;
  final bool isWinner;

  // [추가] 투표 모드에서의 선택 상태 관리를 위한 변수
  final bool isSelected;
  final bool showSelectionBorder;

  // [수정 1] isResultMode 필드를 여기에 추가합니다.
  final bool isResultMode;

  const CandidateCard({
    required this.index,
    required this.name,
    required this.backgroundColor,
    required this.fontColor,
    required this.onTap,
    this.onDelete,
    this.voteCount,
    this.isWinner = false,
    // [추가] 생성자에 매개변수 포함
    this.isSelected = false,
    this.showSelectionBorder = false,
    this.isResultMode = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // [추가] 테두리 결정 로직: 투표 시 '보이게' 옵션이고 선택된 경우 주황색 5.0 두께 표시
    // 그렇지 않고 결과 창에서 1위(isWinner)인 경우 주황색 4.0 두께 표시
    BoxBorder? cardBorder;
    if (isSelected && showSelectionBorder) {
      cardBorder = Border.all(color: Colors.orange, width: 5.0);
    } else if (isWinner) {
      cardBorder = Border.all(color: Colors.orange, width: 4.0);
    }

    return Container(
      margin: const EdgeInsets.all(12.0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. 버튼 본체
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12.0),
              border: cardBorder, // 결정된 테두리 적용
              boxShadow: [
                if (isSelected && showSelectionBorder)
                // 선택되었을 때의 강조 효과
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.8),
                    spreadRadius: 5,
                    blurRadius: 10,
                  )
                else if (isWinner)
                // 결과창 1위일 때의 효과 (기존 유지)
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.6),
                    spreadRadius: 4,
                    blurRadius: 15,
                    offset: const Offset(0, 0),
                  )
                else
                // 기본 그림자
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12.0),
              child: Stack(
                children: [
                  // 중앙: 후보자 이름
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AutoSizeText(
                        name,
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: fontColor,
                        ),
                        maxLines: 1,
                        minFontSize: 12,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // 우측 상단 내부: 득표수 표시
                  if (voteCount != null)
                    Positioned(
                      top: 10,
                      right: 15,
                      child: Text(
                        "$voteCount표",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. 후보자 번호 (좌측 상단 바깥쪽)
          Positioned(
            left: -10,
            top: -10,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2.0),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),

          // 3. 삭제 버튼 (X)
          if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDelete,
              ),
            ),
        ],
      ),
    );
  }
}
