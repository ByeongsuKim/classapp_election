import 'dart:async';
import 'dart:math';

// auto_size_text 패키지 import
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'election.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '우리반 반장 선거',
      theme: ThemeData(
        fontFamily: 'NanumSquareNeo',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _columnCount = 1;
  String _voteDisplayOption = '(터치) 선택 보이게';
  String _votePolicyOption = '미투표 시 기권 처리';
  int _voteCount = 20;

  final TextEditingController _electionTitleController = TextEditingController();
  String _electionTitle = '';
  final TextEditingController _numberController = TextEditingController(text: '20');
  final List<TextEditingController> _candidateControllers = [];
  final List<FocusNode> _candidateFocusNodes = [];

  List<List<TextEditingController>> _descriptionColumns = [];
  List<List<TextEditingController>> _candidateColumns = [];

  final List<Color> _fixedButtonColors = const [
    Color(0xFFF7ED79),
    Color(0xFF8BA7F7),
    Color(0xFFD6F5B9),
    Color(0xFFDC8FD3),
  ];

  final List<Color> _fixedFontColors = const [
    Colors.black,
    Colors.white,
    Colors.black,
    Colors.white,
  ];

  List<Color> _candidateButtonColors = [];

  @override
  void initState() {
    super.initState();
    _electionTitleController.addListener(_updateBrowserTabTitle);
    _updateTitleForColumnCount(_columnCount);
    _updateColumns(_columnCount);
    _numberController.text = _voteCount.toString();
  }

  void _updateBrowserTabTitle() {
    setState(() {
      _electionTitle = _electionTitleController.text;
    });
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: _electionTitleController.text,
        primaryColor: Colors.deepPurple.value,
      ),
    );
  }

  void _updateTitleForColumnCount(int count) {
    String newTitle;
    if (count == 1) {
      newTitle = '우리반 반장 선거';
    } else if (count == 2) {
      newTitle = '우리반 부반장 선거';
    } else {
      newTitle = '우리반 부장 선거';
    }
    setState(() {
      _electionTitle = newTitle;
      _electionTitleController.text = newTitle;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateBrowserTabTitle();
    });
  }

  @override
  void dispose() {
    _electionTitleController.removeListener(_updateBrowserTabTitle);
    _electionTitleController.dispose();
    _numberController.dispose();
    for (var controller in _candidateControllers) {
      controller.dispose();
    }
    for (var node in _candidateFocusNodes) {
      node.dispose();
    }
    for (var col in _descriptionColumns) {
      for (var controller in col) {
        controller.dispose();
      }
    }
    for (var col in _candidateColumns) {
      for (var controller in col) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _updateColumns(int count, {bool confirm = false}) {
    if (!confirm && _hasData()) {
      _showConfirmChangeDialog(count);
    } else {
      setState(() {
        _columnCount = count;
        if (confirm) {
          _updateTitleForColumnCount(count);
        }

        _descriptionColumns = List.generate(
            _columnCount,
                (index) => index < _descriptionColumns.length
                ? _descriptionColumns[index]
                : [TextEditingController()]);

        _candidateColumns = List.generate(
            _columnCount,
                (index) => index < _candidateColumns.length ? _candidateColumns[index] : []);

        _candidateButtonColors = List.generate(_columnCount, (index) => _fixedButtonColors[index]);
      });
    }
  }

  bool _hasData() {
    for (var col in _descriptionColumns) {
      for (var controller in col) {
        if (controller.text.isNotEmpty) return true;
      }
    }
    for (var col in _candidateColumns) {
      for (var controller in col) {
        if (controller.text.isNotEmpty) return true;
      }
    }
    return false;
  }

  bool _hasCandidateData() {
    return _candidateColumns.any((col) => col.any((c) => c.text.isNotEmpty));
  }

  void _showConfirmChangeDialog(int newCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        contentTextStyle: const TextStyle(fontSize: 16),
        title: const Text('투표제 변경'),
        content: const Text('입력된 설명과 후보자 정보가 삭제될 수 있습니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData();
              _updateColumns(newCount, confirm: true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showVoteDisplayChangeDialog(String selectedOption) {
    String message;
    if (selectedOption.contains('보이게')) {
      message = "투표자가 후보자 이름을 터치(클릭)할 때 누구를 선택했는지 화면에 표시됩니다.";
    } else {
      message = "투표자가 후보자 이름을 터치(클릭)할 때 누구를 선택했는지 화면에 표시되지 않습니다.";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        contentTextStyle: const TextStyle(fontSize: 16),
        title: Text('\'$selectedOption\' 안내'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    for (var col in _descriptionColumns) {
      for (var controller in col) {
        controller.clear();
      }
    }
    for (var col in _candidateColumns) {
      for (var controller in col) {
        controller.dispose();
      }
    }
    setState(() {
      _descriptionColumns = [];
      _candidateColumns = [];
      _candidateButtonColors = [];
    });
  }

  void _addCandidate(int columnIndex) {
    setState(() {
      _candidateColumns[columnIndex].add(TextEditingController());
    });
  }

  void _removeCandidate(int columnIndex, int candidateIndex) {
    setState(() {
      _candidateColumns[columnIndex][candidateIndex].dispose();
      _candidateColumns[columnIndex].removeAt(candidateIndex);
    });
  }

  void _showAddCandidateDialog(int columnIndex) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        title: const Text('후보 등록'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '후보 이름을 입력하세요'),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _candidateColumns[columnIndex].add(TextEditingController(text: value));
              });
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final value = controller.text;
              if (value.isNotEmpty) {
                setState(() {
                  _candidateColumns[columnIndex].add(TextEditingController(text: value));
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showEditCandidateDialog(int columnIndex, int candidateIndex) {
    final controller = TextEditingController(text: _candidateColumns[columnIndex][candidateIndex].text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        title: const Text('후보 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '후보 이름을 입력하세요'),
          onSubmitted: (value) {
            setState(() {
              _candidateColumns[columnIndex][candidateIndex].text = value;
            });
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _removeCandidate(columnIndex, candidateIndex);
              Navigator.of(context).pop();
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _candidateColumns[columnIndex][candidateIndex].text = controller.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionItem(int columnIndex) {
    final Map<int, List<String>> exampleTexts = {
      1: ['설명 등록 (예: 1분기 반장)'],
      2: ['설명 등록 (예: 여자 부반장)', '설명 등록 (예: 남자 부반장)'],
      3: ['(예: 총무부장)', '(예: 환경부장)', '(예: 예능부장)'],
      4: ['(예: 총무부장)', '(예: 환경부장)', '(예: 예능부장)', '(예: 체육부장)'],
    };

    String currentText = _descriptionColumns[columnIndex].first.text;
    String exampleText = (exampleTexts[_columnCount] ?? ['설명 등록'])[columnIndex % (exampleTexts[_columnCount]?.length ?? 1)];
    String buttonText = currentText.isNotEmpty ? currentText : exampleText;

    if (_columnCount >= 3 && currentText.isEmpty) {
      buttonText = '설명 등록 $exampleText';
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        InkWell(
          onTap: () {
            _showEditDescriptionDialog(columnIndex);
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
            decoration: BoxDecoration(
                color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (currentText.isNotEmpty)
          Positioned(
            right: 20,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _descriptionColumns[columnIndex].first.clear();
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  void _showEditDescriptionDialog(int columnIndex) {
    final controller = TextEditingController(text: _descriptionColumns[columnIndex].first.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        title: const Text('설명 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '설명을 입력하세요'),
          onSubmitted: (value) {
            setState(() {
              _descriptionColumns[columnIndex].first.text = value;
            });
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _descriptionColumns[columnIndex].first.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _descriptionColumns[columnIndex].first.text = controller.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateButtonForMain(int columnIndex, int candidateIndex) {
    return Container(
      margin: const EdgeInsets.all(12.0), // 번호가 튀어나올 공간 확보를 위해 마진 조정
      child: Stack(
        clipBehavior: Clip.none, // 핵심: 번호가 버튼 영역 밖으로 나가도 보이게 설정
        alignment: Alignment.center,
        children: [
          // 배경 및 버튼 본체
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _candidateButtonColors[columnIndex],
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
              onTap: () => _showEditCandidateDialog(columnIndex, candidateIndex),
              borderRadius: BorderRadius.circular(12.0),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AutoSizeText(
                    _candidateColumns[columnIndex][candidateIndex].text,
                    style: TextStyle(
                      fontSize: 80, // 핵심: 기본 크기를 매우 크게 설정 (이전보다 약 8배)
                      fontWeight: FontWeight.bold,
                      color: _fixedFontColors[columnIndex],
                    ),
                    maxLines: 1, // 한 줄로 강제
                    minFontSize: 12,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),

          // --- 후보자 번호 (좌측 상단 바깥쪽 위치) ---
          Positioned(
            left: -10, // 버튼 영역 밖으로 이동
            top: -10, // 버튼 영역 밖으로 이동
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
                  '${candidateIndex + 1}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),

          // --- 삭제 버튼 ---
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close,
                color: _fixedFontColors[columnIndex].withOpacity(0.8),
              ),
              onPressed: () => _removeCandidate(columnIndex, candidateIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateLayout(int columnIndex) {
    final int totalCandidates = _candidateColumns[columnIndex].length;

    if (totalCandidates == 0) {
      return Center(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('후보 추가'),
          onPressed: () => _showAddCandidateDialog(columnIndex),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    Widget layout;

    if (_columnCount > 1) {
      List<Widget> children = [];
      for (int i = 0; i < totalCandidates; i += 2) {
        List<Widget> buttonsInRow = [];
        buttonsInRow.add(
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.5 / 1, // 번호가 잘 보일 수 있도록 비율 조정
              child: _buildCandidateButtonForMain(columnIndex, i),
            ),
          ),
        );

        if (i + 1 < totalCandidates) {
          buttonsInRow.add(
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.5 / 1,
                child: _buildCandidateButtonForMain(columnIndex, i + 1),
              ),
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
      layout = Column(children: children);
    } else {
      if (totalCandidates <= 3) {
        if (totalCandidates == 1) {
          layout = Center(
            child: FractionallySizedBox(
              widthFactor: 0.6,
              heightFactor: 0.4,
              child: _buildCandidateButtonForMain(columnIndex, 0),
            ),
          );
        } else {
          layout = Center(
            child: FractionallySizedBox(
              heightFactor: 0.4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  totalCandidates,
                      (j) => Expanded(
                    child: _buildCandidateButtonForMain(columnIndex, j),
                  ),
                ),
              ),
            ),
          );
        }
      } else {
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
          if (baseCount == 0) baseCount = 1;
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
              buttonsInRow.add(
                Expanded(
                  child: _buildCandidateButtonForMain(columnIndex, candidateIndex),
                ),
              );
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
        layout = Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          ),
        );
      }
    }

    return Column(
      children: [
        Expanded(child: layout),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('후보 추가'),
              onPressed: () => _showAddCandidateDialog(columnIndex),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnSection(int columnIndex) {
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
            _buildDescriptionItem(columnIndex),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildCandidateLayout(columnIndex),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: SizedBox(
          width: 300,
          child: TextField(
            controller: _electionTitleController,
            decoration: const InputDecoration(
              hintText: '선거 제목을 입력하세요',
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
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
                const Text(
                  "총원: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      _voteCount = (_voteCount > 0) ? _voteCount - 1 : 0;
                      _numberController.text = _voteCount.toString();
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Expanded(
                  child: TextField(
                    controller: _numberController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      setState(() {
                        _voteCount = int.tryParse(value) ?? 0;
                      });
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _voteCount++;
                      _numberController.text = _voteCount.toString();
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Text("명"),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('투표제 설정: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    ToggleButtons(
                      isSelected: [_columnCount == 1, _columnCount == 2, _columnCount == 3, _columnCount == 4],
                      onPressed: (int index) {
                        _updateColumns(index + 1);
                      },
                      borderRadius: BorderRadius.circular(8),
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('1인 1표')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('1인 2표')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('1인 3표')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('1인 4표')),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('투표 방식 설정: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _voteDisplayOption,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _voteDisplayOption = newValue;
                              });
                              _showVoteDisplayChangeDialog(newValue);
                            }
                          },
                          items: <String>[
                            '(키보드) 선택 안보이게',
                            '(키보드) 선택 보이게',
                            '(터치) 선택 안보이게',
                            '(터치) 선택 보이게',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: Row(
              children: List.generate(_columnCount, (index) {
                return _buildColumnSection(index);
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_columnCount개의 선거 | 총 ${_candidateColumns.fold(0, (prev, col) => prev + col.length)}명의 후보',
                  style: const TextStyle(color: Colors.grey)),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: !_hasCandidateData()
                      ? null
                      : () {
                    List<List<String>> descriptionTexts =
                    _descriptionColumns.map((col) => col.map((c) => c.text).toList()).toList();
                    List<List<String>> candiTexts = _candidateColumns.map((col) => col.map((c) => c.text).toList()).toList();

                    List<List<int>> candiNumbers = [];
                    for (int i = 0; i < _candidateColumns.length; i++) {
                      List<int> numbersInCol = [];
                      for (int j = 0; j < _candidateColumns[i].length; j++) {
                        numbersInCol.add(j + 1); // 1부터 시작하는 번호
                      }
                      candiNumbers.add(numbersInCol);
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ElectionPage(
                          electionTitle: _electionTitleController.text,
                          voterCount: _voteCount,
                          descriptions: descriptionTexts,
                          candi: candiTexts,
                          candidateNumbers: candiNumbers,
                          candidateButtonColors: _candidateButtonColors,
                          voteDisplayOption: _voteDisplayOption.contains('보이게') ? '선택 보이게' : '선택 안보이게',
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF134686),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('투표 시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
