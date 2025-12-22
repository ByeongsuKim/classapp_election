import 'package:flutter/material.dart';

class VoteSettingsBar extends StatelessWidget {
  final bool isDesktop; // 사용자 기기 판별
  final int candidateCount;
  final int columnCount;
  final String voteDisplayOption;
  final int voteCount;
  final TextEditingController numberController;
  final Function(int) onColumnCountChanged;
  final Function(String) onVoteDisplayChanged;
  final VoidCallback onIncrementVote;
  final VoidCallback onDecrementVote;
  final Function(String) onVoteCountInput;
  final VoidCallback? onStartVote;

  const VoteSettingsBar({
    super.key,
    required this.isDesktop,
    required this.candidateCount,
    required this.columnCount,
    required this.voteDisplayOption,
    required this.voteCount,
    required this.numberController,
    required this.onColumnCountChanged,
    required this.onVoteDisplayChanged,
    required this.onIncrementVote,
    required this.onDecrementVote,
    required this.onVoteCountInput,
    this.onStartVote,
  });

  @override
  Widget build(BuildContext context) {
    // 기기 종류에 따른 옵션 리스트 정의
    List<String> displayOptions;
    if (isDesktop) {
      displayOptions = [
        '(키보드) 선택 안보이게',
        '(키보드) 선택 보이게',
      ];
    } else {
      displayOptions = [
        '(터치) 선택 안보이게',
        '(터치) 선택 보이게',
        '(키보드) 선택 안보이게',
        '(키보드) 선택 보이게',
      ];
    }


    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          // 1. 좌측: 후보 수
          Expanded(
            flex: 2,
            child: Text(
              '총 $candidateCount명의 후보',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),

          // 2. 중앙: FAB 공간 (Spacer)
          const Spacer(flex: 1),

          // 3. 우측: 설정 메뉴들 + 시작 버튼
          Expanded(
            flex: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 투표제 설정
                _buildSettingBox(
                  label: '투표제',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: columnCount,
                      isDense: true,
                      onChanged: (v) => onColumnCountChanged(v!),
                      items: [1, 2, 3, 4].map((i) => DropdownMenuItem(
                        value: i,
                        child: Text('1인 ${i}표제', style: const TextStyle(fontSize: 13)),
                      )).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 방식 설정
                _buildSettingBox(
                  label: '방식',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: displayOptions.contains(voteDisplayOption)
                          ? voteDisplayOption
                          : displayOptions.first,
                      isDense: true,
                      onChanged: (v) => onVoteDisplayChanged(v!),
                      items: displayOptions.map((String s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(s, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 총원 설정
                _buildSettingBox(
                  label: '총원',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: onDecrementVote,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(
                        width: 30,
                        child: TextField(
                          controller: numberController,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          onChanged: onVoteCountInput,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: onIncrementVote,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // 투표 시작 버튼
                FilledButton(
                  onPressed: onStartVote,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    minimumSize: const Size(110, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('투표 시작', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingBox({required String label, required Widget child}) {
    return CustomPaint(
      painter: DashedBorderPainter(color: Colors.black.withOpacity(0.4), strokeWidth: 1.2, gap: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.amberAccent,
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// 점선 테두리 Painter (함께 분리)
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8.0),
      ));

    for (final measure in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < measure.length) {
        if (draw) {
          canvas.drawPath(measure.extractPath(distance, distance + gap), paint);
        }
        distance += gap;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
