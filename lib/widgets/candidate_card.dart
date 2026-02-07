import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CandidateCard extends StatefulWidget {
  final int index;
  final String name;
  final Color backgroundColor;
  final Color fontColor;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final int? voteCount;
  final bool isWinner;
  final int totalVoterCount;
  final int columnCount;
  final bool isSelected;
  final bool showSelectionBorder;
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
    this.totalVoterCount = 1,
    this.columnCount = 1,
    this.isSelected = false,
    this.showSelectionBorder = false,
    this.isResultMode = false,
    super.key,
  });

  @override
  State<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<CandidateCard> with TickerProviderStateMixin {
  double _targetPercentage = 0.0;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (widget.isResultMode) {
      _calculateAndAnimate();
      if (widget.isWinner) {
        _glowController.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(CandidateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isResultMode && widget.isResultMode) {
      _calculateAndAnimate();
      if (widget.isWinner) {
        _glowController.repeat(reverse: true);
      }
    } else if (!widget.isResultMode) {
      if (mounted) {
        setState(() { _targetPercentage = 0.0; });
      }
      _glowController.stop();
    } else if (oldWidget.isWinner != widget.isWinner) {
      if (widget.isWinner) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
        _glowController.reset(); // 애니메이션 값을 초기 상태로 되돌림
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _calculateAndAnimate() {
    final double percentage = (widget.voteCount != null && widget.totalVoterCount > 0)
        ? (widget.voteCount! / widget.totalVoterCount) * widget.columnCount
        : 0.0;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() { _targetPercentage = percentage; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    BoxBorder? solidBorder;
    if (widget.isSelected && widget.showSelectionBorder) {
      solidBorder = Border.all(color: Colors.orange, width: 5.0);
    }

    // [핵심 수정] AnimatedBuilder의 builder와 child를 올바르게 사용
    return AnimatedBuilder(
      animation: _glowController,
      // 'child'는 아래에 정의된, 애니메이션과 관련 없는 모든 위젯
      child: Container(
        clipBehavior: Clip.none,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 카드 내용물 (이름)
            _buildCardContent(),

            // 그래프 바
            _buildGraphBar(),

            // 장식 요소 (번호, 득표수, 삭제 버튼)
            ..._buildDecorations(),
          ],
        ),
      ),
      builder: (context, child) {
        // builder는 이제 'child'를 감싸는 Container의 decoration만 책임짐
        return Container(
          margin: const EdgeInsets.only(top: 22, left: 12, right: 12, bottom: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12.0),
            border: solidBorder,
            boxShadow: [
              if (widget.isWinner)
                BoxShadow(
                  color: Colors.orange.withOpacity(0.8),
                  spreadRadius: _glowAnimation.value,
                  blurRadius: _glowAnimation.value * 2,
                )
              else if (widget.isSelected && widget.showSelectionBorder)
                BoxShadow(
                  color: Colors.orange.withOpacity(0.8),
                  spreadRadius: 5,
                  blurRadius: 10,
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
          child: child, // [핵심 수정] builder의 파라미터 'child'를 여기에 배치
        );
      },
    );
  }

  // 나머지 위젯 빌드 함수들은 변경 없음
  Widget _buildCardContent() {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AutoSizeText(
            widget.name,
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: widget.fontColor,
            ),
            maxLines: 1,
            minFontSize: 12,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildGraphBar() {
    if (!widget.isResultMode) return const SizedBox.shrink();

    return Positioned(
      top: -10, left: 0, right: 0,
      child: Container(
        height: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black.withOpacity(0.1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeOutCubic,
                  width: (constraints.maxWidth*0.97) * _targetPercentage,
                  //decoration: BoxDecoration(
                  //  color: _targetPercentage > 0 ? Colors.orange.withOpacity(1.0) : Colors.transparent,
                  //),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDecorations() {
    return [
      Positioned(
        left: -10, top: -10,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2.0),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(1, 1),) ],
          ),
          child: Center(child: Text('${widget.index + 1}', style: const TextStyle( color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18, ),),),
        ),
      ),
      if (widget.isResultMode && widget.voteCount != null)
        Positioned(
          top: -10, right: -5,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.2), blurRadius: 3,)],
            ),
            child: Center(child: Text("${widget.voteCount}표", style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold,),),),
          ),
        ),
      if (widget.onDelete != null)
        Positioned(
          top: 4, right: 4,
          child: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: widget.onDelete,),
        ),
    ];
  }
}
