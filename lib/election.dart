import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart'; // 패키지 import
import 'package:flutter/material.dart';

class ElectionPage extends StatefulWidget {
  final String electionTitle;
  final int voterCount;
  final List<List<String>> descriptions;
  final List<List<String>> candi;
  final List<List<int>> candidateNumbers;
  final List<Color> candidateButtonColors;
  final String voteDisplayOption;

  const ElectionPage({
    super.key,
    required this.electionTitle,
    required this.voterCount,
    required this.descriptions,
    required this.candi,
    required this.candidateNumbers,
    required this.candidateButtonColors,
    required this.voteDisplayOption,
  });

  @override
  State<ElectionPage> createState() => _ElectionPageState();
}

class _ElectionPageState extends State<ElectionPage> {
  late List<List<int>> voteCounts;
  late List<List<List<bool>>> voted;
  int currentVoterIndex = 0;

  late List<List<_CandidateInfo>> _candidateColumns;

  bool _showUniversalSelectionEffect = false;
  Timer? _effectTimer;

  bool _showArrowAnimation = false;
  Timer? _arrowAnimationTimer;

  @override
  void initState() {
    super.initState();
    voteCounts = List.generate(
      widget.candi.length,
          (i) => List.generate(widget.candi[i].length, (j) => 0),
    );
    voted = List.generate(
      widget.voterCount,
          (k) => List.generate(
        widget.candi.length,
            (i) => List.generate(widget.candi[i].length, (j) => false),
      ),
    );
    _initializeCandidates();
  }

  @override
  void dispose() {
    _effectTimer?.cancel();
    _arrowAnimationTimer?.cancel();
    super.dispose();
  }

  void _initializeCandidates() {
    _candidateColumns = List.generate(widget.candi.length, (i) {
      return List.generate(widget.candi[i].length, (j) {
        return _CandidateInfo(
          name: widget.candi[i][j],
          number: widget.candidateNumbers[i][j],
          originalColumnIndex: i,
          originalCandidateIndex: j,
          color: widget.candidateButtonColors[i],
        );
      });
    });
  }

  void _vote(int columnIndex, int candidateIndex) {
    setState(() {
      // 1인 1표 강제 로직: 해당 컬럼에서 다른 후보를 선택하면 기존 표는 자동으로 취소됨
      final currentVotes = voted[currentVoterIndex][columnIndex];
      final currentlyVotedIndex = currentVotes.indexWhere((v) => v);

      if (currentlyVotedIndex != -1 && currentlyVotedIndex != candidateIndex) {
        // 기존에 투표한 후보가 있고, 다른 후보를 선택했다면
        currentVotes[currentlyVotedIndex] = false; // 기존 투표 취소
        voteCounts[columnIndex][currentlyVotedIndex]--; // 기존 득표 수 감소
      }

      // 현재 선택한 후보에 대한 투표 처리
      if (currentVotes[candidateIndex]) {
        // 이미 선택된 후보를 다시 누르면 투표 취소
        currentVotes[candidateIndex] = false;
        voteCounts[columnIndex][candidateIndex]--;
      } else {
        // 새로운 후보 선택
        currentVotes[candidateIndex] = true;
        voteCounts[columnIndex][candidateIndex]++;
      }

      // '선택 안보이게' 옵션일 때 시각 효과 처리
      if (widget.voteDisplayOption != '선택 보이게') {
        _showUniversalSelectionEffect = true;
        _effectTimer?.cancel();
        _effectTimer = Timer(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _showUniversalSelectionEffect = false);
          }
        });
      }
    });

    // 모든 선거(column)에서 1표씩 투표했는지 확인
    bool allVoted = true;
    for (int i = 0; i < widget.candi.length; i++) {
      if (!voted[currentVoterIndex][i].contains(true)) {
        allVoted = false;
        break;
      }
    }

    // 모든 선거에서 투표를 완료했다면 '투표 완료' 버튼으로 시선 유도 애니메이션 시작
    if (allVoted) {
      _arrowAnimationTimer?.cancel();
      setState(() {
        _showArrowAnimation = true;
      });
      _arrowAnimationTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showArrowAnimation = false;
          });
        }
      });
    }
  }

  void _showResultButtonOverlay() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 0.5,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF134686),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return AlertDialog(
                      titleTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 20),
                      contentTextStyle: const TextStyle(fontSize: 16),
                      title: const Text('투표 결과'),
                      content: _buildResultView(),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          child: const Text('메인으로'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text(
                '결과 보기',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onNextVoterPressed() {
    _showLoadingAndProceed();
  }

  void _showLoadingAndProceed() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SpinningHourglass(),
              SizedBox(height: 20),
              _AnimatedDotsText(text: "투표지를 넣고 있습니다"),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();

        bool isLastVoter = currentVoterIndex >= widget.voterCount - 1;
        if (isLastVoter) {
          _showResultButtonOverlay();
        } else {
          _showNextVoterDialog();
        }
      }
    });
  }

  void _showNextVoterDialog() {
    setState(() {
      currentVoterIndex++;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: _ScaleAndFadeText(
            text: "${currentVoterIndex + 1}번째 투표를\n시작해주세요",
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Widget _buildResultView() {
    List<Widget> results = [];
    for (int i = 0; i < widget.candi.length; i++) {
      if (widget.descriptions[i].isNotEmpty) {
        results.add(Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: Text(
            widget.descriptions[i].join(', '),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ));
      }
      for (int j = 0; j < widget.candi[i].length; j++) {
        results.add(
          Padding(
            padding:
            const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Text(
              '${widget.candi[i][j]}: ${voteCounts[i][j]}표',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      }
      if (i < widget.candi.length - 1) {
        results.add(const Divider());
      }
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: results,
      ),
    );
  }

  Widget _buildCandidateButton(_CandidateInfo candidate) {
    bool isVoted = false;
    if (widget.voteDisplayOption == '선택 보이게') {
      isVoted = voted[currentVoterIndex][candidate.originalColumnIndex]
      [candidate.originalCandidateIndex];
    } else {
      isVoted = _showUniversalSelectionEffect;
    }

    final fontColor =
    (candidate.color.computeLuminance() > 0.5) ? Colors.black : Colors.white;

    List<BoxShadow> selectionEffect = isVoted
        ? [
      BoxShadow(
        color: Colors.blue.shade700,
        spreadRadius: 4,
        blurRadius: 12,
        offset: const Offset(0, 0),
      ),
      BoxShadow(
        color: Colors.blue.shade300.withOpacity(0.5),
        spreadRadius: 8,
        blurRadius: 20,
        offset: const Offset(0, 0),
      )
    ]
        : [];

    return Container(
      margin: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: candidate.color,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          ...selectionEffect,
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () =>
            _vote(candidate.originalColumnIndex, candidate.originalCandidateIndex),
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- 후보자 이름 ---
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    // [핵심 수정] AutoSizeText 위젯 사용
                    child: AutoSizeText(
                      candidate.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: fontColor),
                      textAlign: TextAlign.center,
                      maxLines: 2, // 최대 2줄
                      minFontSize: 15, // 최소 폰트 크기를 15로 설정
                      overflow: TextOverflow.ellipsis, // 그래도 넘치면 ... 처리
                    ),
                  ),
                );
              },
            ),
            // --- 투표 수 (기존) ---
            if (widget.voteDisplayOption == '선택 보이게')
              Positioned(
                bottom: 8,
                right: 12,
                child: Text(
                  '${voteCounts[candidate.originalColumnIndex][candidate.originalCandidateIndex]}표',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: fontColor.withOpacity(0.8)),
                ),
              ),
            // --- 후보자 번호 ---
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${candidate.number}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateLayout(int columnIndex) {
    final List<_CandidateInfo> candidates = _candidateColumns[columnIndex];
    final int totalCandidates = candidates.length;

    if (totalCandidates == 0) {
      return const SizedBox.shrink();
    }

    if (widget.candi.length > 1) {
      List<Widget> children = [];
      for (int i = 0; i < totalCandidates; i += 2) {
        List<Widget> buttonsInRow = [];
        buttonsInRow.add(
          Expanded(
            child: AspectRatio(
                aspectRatio: 1 / 1, child: _buildCandidateButton(candidates[i])),
          ),
        );

        if (i + 1 < totalCandidates) {
          buttonsInRow.add(
            Expanded(
              child: AspectRatio(
                  aspectRatio: 1 / 1,
                  child: _buildCandidateButton(candidates[i + 1])),
            ),
          );
        } else {
          buttonsInRow.add(Expanded(child: Container()));
        }
        children.add(Expanded(child: Row(children: buttonsInRow)));
      }
      int rowCount = (totalCandidates / 2).ceil();
      if (rowCount < 4) {
        for (int i = 0; i < (4 - rowCount); i++) {
          children.add(Expanded(child: Container()));
        }
      }
      return Column(children: children);
    }

    if (totalCandidates <= 3) {
      if (totalCandidates == 1) {
        return Center(
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 0.5,
            child: _buildCandidateButton(candidates.first),
          ),
        );
      } else {
        return Center(
          child: FractionallySizedBox(
            heightFactor: 0.5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: candidates
                  .map((item) => Expanded(child: _buildCandidateButton(item)))
                  .toList(),
            ),
          ),
        );
      }
    }

    List<Widget> rows = [];
    List<int> candidatesPerRow;
    int maxItemsInRow = 0;

    if (totalCandidates == 4) {
      candidatesPerRow = [2, 2];
      maxItemsInRow = 2;
    } else if (totalCandidates == 5) {
      candidatesPerRow = [2, 3];
      maxItemsInRow = 3;
    } else if (totalCandidates == 6) {
      candidatesPerRow = [3, 3];
      maxItemsInRow = 3;
    } else if (totalCandidates == 7) {
      candidatesPerRow = [3, 4];
      maxItemsInRow = 4;
    } else if (totalCandidates == 8) {
      candidatesPerRow = [4, 4];
      maxItemsInRow = 4;
    } else {
      int baseCount = (totalCandidates / 3).ceil();
      maxItemsInRow = baseCount;
      candidatesPerRow = [];
      int remaining = totalCandidates;
      while (remaining > 0) {
        int count = remaining >= baseCount ? baseCount : remaining;
        candidatesPerRow.add(count);
        remaining -= count;
      }
    }

    int candidateIndex = 0;
    for (int count in candidatesPerRow) {
      List<Widget> buttonsInRow = [];
      for (int i = 0; i < count; i++) {
        if (candidateIndex < totalCandidates) {
          buttonsInRow.add(Expanded(
            child: _buildCandidateButton(candidates[candidateIndex]),
          ));
          candidateIndex++;
        }
      }

      if (count < maxItemsInRow) {
        int diff = maxItemsInRow - count;
        for (int i = 0; i < diff; i++) {
          if (i.isEven) {
            buttonsInRow.add(Expanded(child: Container()));
          } else {
            buttonsInRow.insert(0, Expanded(child: Container()));
          }
        }
      }

      rows.add(
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buttonsInRow,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. 배경색 통일
      backgroundColor: const Color(0xFFF3F4F6),
      // 2. AppBar 구조 통일
      appBar: AppBar(
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        // AppBar 제목 영역
        title: Text(
          widget.electionTitle,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        // AppBar 액션 영역 (총원 표시)
        actions: [
          Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("완료: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$currentVoterIndex명', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const Text(" / 총원: "),
                Text('${widget.voterCount}명'),
              ],
            ),
          ),
          const SizedBox(width: 24),
        ],
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      body: Column(
        children: [
          // 3. 설정 Bar 영역 복제 (내용은 '투표 완료' 버튼으로 대체)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currentVoterIndex + 1}번째 투표',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.how_to_vote),
                    label: const Text('나의 투표 완료'),
                    onPressed: _onNextVoterPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF134686),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // 4. 메인 콘텐츠 영역 구조 통일
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: List.generate(widget.candi.length, (columnIndex) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
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
                            if (widget.descriptions[columnIndex].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  widget.descriptions[columnIndex].join(', '),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            Expanded(
                              child: _buildCandidateLayout(columnIndex),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                // '투표 완료' 버튼 위치로 시선 유도하는 화살표 애니메이션
                if (_showArrowAnimation)
                  Positioned(
                    top: -10,
                    right: 24,
                    child: const _BlinkingArrow(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateInfo {
  final String name;
  final int number;
  final int originalColumnIndex;
  final int originalCandidateIndex;
  final Color color;

  _CandidateInfo({
    required this.name,
    required this.number,
    required this.originalColumnIndex,
    required this.originalCandidateIndex,
    required this.color,
  });
}

// 회전하는 모래시계 애니메이션을 위한 위젯
class _SpinningHourglass extends StatefulWidget {
  const _SpinningHourglass();

  @override
  State<_SpinningHourglass> createState() => _SpinningHourglassState();
}

class _SpinningHourglassState extends State<_SpinningHourglass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: const Icon(
        Icons.hourglass_bottom_rounded,
        color: Colors.white,
        size: 80.0,
      ),
    );
  }
}

// 점(...) 애니메이션 텍스트를 위한 위젯
class _AnimatedDotsText extends StatefulWidget {
  final String text;
  final double? fontSize;

  const _AnimatedDotsText({required this.text, this.fontSize});

  @override
  State<_AnimatedDotsText> createState() => _AnimatedDotsTextState();
}

class _AnimatedDotsTextState extends State<_AnimatedDotsText> {
  int _dotCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String dots = '.' * _dotCount;
    return Text(
      '${widget.text}$dots',
      style: TextStyle(
        color: Colors.white,
        fontSize: widget.fontSize ?? 18,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
    );
  }
}

// 커지면서 사라지는 애니메이션 텍스트를 위한 위젯
class _ScaleAndFadeText extends StatefulWidget {
  final String text;
  const _ScaleAndFadeText({required this.text});

  @override
  State<_ScaleAndFadeText> createState() => _ScaleAndFadeTextState();
}

class _ScaleAndFadeTextState extends State<_ScaleAndFadeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

// 깜빡이는 화살표 애니메이션을 위한 위젯
class _BlinkingArrow extends StatefulWidget {
  const _BlinkingArrow();

  @override
  State<_BlinkingArrow> createState() => _BlinkingArrowState();
}

class _BlinkingArrowState extends State<_BlinkingArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Transform.rotate(
        angle: -0.8, // 화살표 각도 조절
        child: const Icon(
          Icons.arrow_forward,
          color: Colors.redAccent,
          size: 60.0,
        ),
      ),
    );
  }
}
