import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CandidateCard extends StatelessWidget {
  final int index;
  final String name;
  final Color backgroundColor;
  final Color fontColor;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const CandidateCard({
    super.key,
    required this.index,
    required this.name,
    required this.backgroundColor,
    required this.fontColor,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12.0), // 바깥쪽 번호와 삭제 버튼 공간 유지
      child: Stack(
        clipBehavior: Clip.none, // 번호와 삭제 버튼이 밖으로 나가도 보이게 설정
        alignment: Alignment.center,
        children: [
          // 1. 버튼 본체 (기존 디자인 그대로)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AutoSizeText(
                    name,
                    style: TextStyle(
                      fontSize: 80, // 기존의 대폭 확대된 폰트 크기 유지
                      fontWeight: FontWeight.bold,
                      color: fontColor,
                    ),
                    maxLines: 1,
                    minFontSize: 12,
                    textAlign: TextAlign.center,
                  ),
                ),
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
