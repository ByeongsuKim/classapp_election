import 'package:flutter/material.dart';

// 1. StatefulWidget으로 변경하기 위해 페이지 클래스를 분리합니다.
class ResultPage extends StatefulWidget {
  final String electionTitle;
  final Map<String, int> voteResults;
  final List<List<String>> candi;

  const ResultPage({
    super.key,
    required this.electionTitle,
    required this.voteResults,
    required this.candi,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  Widget build(BuildContext context) {
    // 전체 득표수 합계
    final totalVotes =
    widget.voteResults.values.fold(0, (sum, item) => sum + item);
    // 컬럼 개수
    final columnCount = widget.candi.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.electionTitle} 결과'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(columnCount, (columnIndex) {
            final List<String> columnCandidates = widget.candi[columnIndex];

            return Expanded(
              child: ListView.builder(
                itemCount: columnCandidates.length,
                itemBuilder: (context, itemIndex) {
                  final String name = columnCandidates[itemIndex];
                  final int votes = widget.voteResults[name] ?? 0;
                  final double percentage = totalVotes > 0 ? votes / totalVotes : 0;

                  // 2. 각 결과 항목을 AnimatedBar 위젯으로 교체합니다.
                  return AnimatedBar(
                    name: name,
                    votes: votes,
                    percentage: percentage,
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

// 3. 애니메이션을 처리할 별도의 StatefulWidget을 생성합니다.
class AnimatedBar extends StatefulWidget {
  final String name;
  final int votes;
  final double percentage;

  const AnimatedBar({
    super.key,
    required this.name,
    required this.votes,
    required this.percentage,
  });

  @override
  State<AnimatedBar> createState() => _AnimatedBarState();
}

// 4. 애니메이션 컨트롤러를 사용하기 위해 SingleTickerProviderStateMixin을 추가합니다.
class _AnimatedBarState extends State<AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 애니메이션 컨트롤러를 초기화합니다. (0.5초 = 500밀리초)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 애니메이션의 시작(0.0)과 끝(최종 득표율) 값을 설정합니다.
    _animation = Tween<double>(begin: 0.0, end: widget.percentage)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // 애니메이션을 시작합니다.
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose(); // 위젯이 사라질 때 컨트롤러를 정리합니다.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${widget.votes}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 5. 애니메이션 값을 그래프 바에 적용합니다.
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // FractionallySizedBox의 widthFactor를 애니메이션 값으로 설정합니다.
                  FractionallySizedBox(
                    widthFactor: _animation.value,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
