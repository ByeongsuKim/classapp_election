import 'package:flutter/material.dart';

class VoteSettingsBar extends StatelessWidget {
  final bool isDesktop;
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
  final bool isVotingMode; // 추가된 필드

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
    required this.isVotingMode, // 생성자 추가
    this.onStartVote,
  });

  @override
  Widget build(BuildContext context) {
    List<String> displayOptions;
    if (isDesktop) {
      displayOptions = ['(키보드) 선택 안보이게', '(키보드) 선택 보이게'];
    } else {
      displayOptions = [
        '(터치) 선택 안보이게', '(터치) 선택 보이게',
        '(키보드) 선택 안보이게', '(키보드) 선택 보이게'
      ];
    }

    // [추가] 현재 부모가 가진 값이 현재 환경의 리스트에 없는 값(예: 데스크탑인데 터치 옵션인 경우)이라면
    // 혹은 초기값이 리스트와 다르다면 첫 번째 옵션으로 강제 동기화
    if (!displayOptions.contains(voteDisplayOption)) {
      // build 중에 setState를 직접 호출할 수 없으므로 프레임 렌더링 후 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onVoteDisplayChanged(displayOptions[0]);
      });
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
          Expanded(
            flex: 2,
            child: Text(
              '총 $candidateCount명의 후보',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(flex: 1),
          Expanded(
            flex: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSettingBox(
                  label: '투표제',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: columnCount,
                      isDense: true,
                      onChanged: isVotingMode ? null : (v) => onColumnCountChanged(v!),
                      items: [1, 2, 3, 4].map((i) => DropdownMenuItem(
                        value: i,
                        child: Text('1인 ${i}표제', style: const TextStyle(fontSize: 13)),
                      )).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildSettingBox(
                  label: '방식',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: displayOptions.contains(voteDisplayOption)
                          ? voteDisplayOption
                          : displayOptions.first,
                      isDense: true,
                      onChanged: isVotingMode ? null : (v) => onVoteDisplayChanged(v!),
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
                _buildSettingBox(
                  label: '총원',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: isVotingMode ? null : onDecrementVote,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(
                        width: 30,
                        child: TextField(
                          controller: numberController,
                          enabled: !isVotingMode,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          onChanged: onVoteCountInput,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: isVotingMode ? null : onIncrementVote,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 에러가 났던 버튼 영역 수정 완료
                FilledButton(
                  onPressed: onStartVote,
                  style: FilledButton.styleFrom(
                    backgroundColor: isVotingMode ? Colors.red : Colors.deepOrange,
                    minimumSize: const Size(110, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                      isVotingMode ? '투표 종료' : '투표 시작',
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingBox({required String label, required Widget child}) {
    return Container(
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
    );
  }
}
