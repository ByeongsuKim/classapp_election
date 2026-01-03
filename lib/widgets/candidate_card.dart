import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CandidateCard extends StatelessWidget {
  final int index;
  final String name;
  final Color backgroundColor;
  final Color fontColor;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final int? voteCount; // 추가: 득표수
  final bool isWinner; // 추가: 1위 여부

  const CandidateCard({
    super.key,
    required this.index,
    required this.name,
    required this.backgroundColor,
    required this.fontColor,
    required this.onTap,
    this.onDelete,
    this.voteCount, // 생성자 추가
    this.isWinner = false, // 생성자 추가 (기본값 false)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12.0), // 바깥쪽 번호와 삭제 버튼 공간 유지
      child: Stack(
        clipBehavior: Clip.none, // 번호와 버튼이 밖으로 나가도 보이게 설정
        alignment: Alignment.center,
        children: [
          // 1. 버튼 본체 (주황색 하이라이트 추가)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12.0),
              // [수정] 1위인 경우 주황색 Blur 테두리 효과 추가
              border: isWinner
                  ? Border.all(color: Colors.orange, width: 4.0)
                  : null,
              boxShadow: [
                if (isWinner)
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.6),
                    spreadRadius: 4,
                    blurRadius: 15,
                    offset: const Offset(0, 0),
                  )
                else
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

                  // [추가] 이름 우측 상단 내부: 득표수 표시 (빨간 글씨, 이름 폰트의 50%)
                  if (voteCount != null)
                    Positioned(
                      // 이름 글자의 위치에 맞춰 적절히 배치 (Center 좌측 기준 우측 상단 느낌)
                      top: 10,
                      right: 15,
                      child: Text(
                        "$voteCount표",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 25, // 기준 80의 약 50%인 40보다 조금 작게 조정(UI 밸런스)
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. 후보자 번호 (좌측 상단 바깥쪽) - 기존 유지
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

          // 3. 삭제 버튼 (X) - 기존 유지
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
