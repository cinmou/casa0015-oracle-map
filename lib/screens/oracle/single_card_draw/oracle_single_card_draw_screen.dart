import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../../providers/tarot_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../models/tarot_card.dart';
import '../../../models/history_item.dart';
import '../../../widgets/tarot_card_widget.dart';
import 'oracle_single_card_history_screen.dart';

class SingleCardDrawScreen extends StatefulWidget {
  const SingleCardDrawScreen({super.key});

  @override
  State<SingleCardDrawScreen> createState() => _SingleCardDrawScreenState();
}

class _SingleCardDrawScreenState extends State<SingleCardDrawScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _feedbackController;

  double _currentPage = 0.0;
  int _lastSnappedPage = 0;

  // 状态标记
  bool _hasRevealed = false;    // 是否已经确认抽牌
  bool _isResultFaceUp = false; // 结果展示时，卡牌是否正面朝上

  List<TarotCard> _shuffledPool = [];
  List<bool> _isReversedPool = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.7);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
      int roundedPage = _currentPage.round();
      if (roundedPage != _lastSnappedPage) {
        HapticFeedback.selectionClick();
        _lastSnappedPage = roundedPage;
      }
    });

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _prepareCards(List<TarotCard> allCards) {
    if (allCards.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _shuffledPool = List.from(allCards)..shuffle();
        _isReversedPool = List.generate(_shuffledPool.length, (_) => Random().nextBool());
      });
    });
  }

  // 确认抽牌逻辑
  void _confirmSelection() {
    if (_hasRevealed) return;

    HapticFeedback.mediumImpact();
    _saveToHistory();

    setState(() {
      _hasRevealed = true;
      _isResultFaceUp = false; // 初始状态为背面，为了稍后播放翻开动画
    });

    // 延迟 100ms 自动翻开，制造仪式感
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isResultFaceUp = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TarotProvider>();
    const Color goldColor = Color(0xFFD4AF37);
    const Color bgColor = Color(0xFF1A1221);

    if (provider.isLoading || provider.cards.isEmpty || _shuffledPool.isEmpty) {
      if (!provider.isLoading && provider.cards.isNotEmpty && _shuffledPool.isEmpty) {
        _prepareCards(provider.cards);
      }
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: goldColor)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Reveal Fate", style: TextStyle(color: goldColor, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: goldColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 历史图标的光芒反馈动画
          AnimatedBuilder(
            animation: _feedbackController,
            builder: (context, child) {
              double glowScale = 0.5 + (_feedbackController.value * 1.5);
              double glowOpacity = (1.0 - _feedbackController.value).clamp(0.0, 0.6);
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (_feedbackController.isAnimating)
                    Transform.scale(
                      scale: glowScale,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [goldColor.withValues(alpha: glowOpacity), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.history, color: _feedbackController.isAnimating ? Colors.white : goldColor),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OracleSingleCardHistoryScreen())),
                  )
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Spacer(),

          // === 卡牌显示区域 ===
          SizedBox(
            height: 480,
            child: _hasRevealed
                ? _buildRevealedResult() // 结果视图 (可交互翻转)
                : _buildSwipeDeck(),      // 选牌视图 (点击整张牌触发选择)
          ),

          const Spacer(),

          // 底部信息区域
          // 只要 _hasRevealed 为 true，底部信息就永久显示，不再随卡牌翻转而消失
          Padding(
            padding: const EdgeInsets.only(
                left: 40,
                right: 40,
                top: 20,   // 离卡牌近一点
                bottom: 80 // 底部留出大片空白，防止滑动条太靠下
            ),
            child: _hasRevealed
                ? _buildBottomInfo()
                : _buildControlPanel(goldColor),
          ),

        ],
      ),
    );
  }

  // 1. 抽牌前的滑动牌堆 (已修复点击问题)
  Widget _buildSwipeDeck() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _shuffledPool.length,
      itemBuilder: (context, index) {
        double delta = index - _currentPage;
        double absDelta = delta.abs();
        double scale = (1.0 - (absDelta * 0.3)).clamp(0.8, 1.2);

        bool isCentered = absDelta < 0.1;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            // 确保点击区域覆盖整个卡片范围，甚至包括一点边缘
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // 只有点击中间的牌才有效
              if (isCentered) _confirmSelection();
            },
            child: Center(
              // 专门负责绘制选中时的金色光晕容器
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isCentered ? [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                      blurRadius: 25,
                      spreadRadius: 2,
                    )
                  ] : [],
                ),
                // 【核心修复】：使用 IgnorePointer 包裹 Widget。
                // 这样卡牌内部的 GestureDetector 就不会吞掉点击事件，
                // 点击事件会直接穿透给外层的 GestureDetector (_confirmSelection)。
                child: IgnorePointer(
                  ignoring: true,
                  child: TarotCardWidget(
                    card: _shuffledPool[index],
                    isFaceUp: false,
                    animateOnTap: false,
                    enableTilt: false,
                    isReversed: _isReversedPool[index],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 2. 抽牌后的结果展示 (恢复可交互性)
  Widget _buildRevealedResult() {
    int idx = _currentPage.round();

    // 这里不需要 IgnorePointer，因为我们希望用户能跟卡牌内部交互(3D倾斜/翻转)
    return Center(
      child: TarotCardWidget(
        card: _shuffledPool[idx],
        isFaceUp: _isResultFaceUp, // 初始自动翻转由这里控制
        isReversed: _isReversedPool[idx],
        animateOnTap: true,        // 允许用户点击卡牌自身来翻面
        enableTilt: true,          // 开启 3D 物理手感
        allowReversed: true,
        // 当用户点击卡牌内部翻面时，同步状态，防止逻辑错乱
        onFlip: () {
          setState(() => _isResultFaceUp = !_isResultFaceUp);
        },
      ),
    );
  }

  // 底部控制面板 (抽牌前)
  Widget _buildControlPanel(Color goldColor) {
    int currentNum = _currentPage.round() + 1;
    return Column(
      children: [
        Text(
          "$currentNum / ${_shuffledPool.length}",
          style: TextStyle(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Slider(
          value: (_currentPage / (_shuffledPool.length - 1)).clamp(0.0, 1.0),
          activeColor: goldColor,
          onChanged: (val) {
            int targetPage = (val * (_shuffledPool.length - 1)).round();
            _pageController.animateToPage(
              targetPage,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
            );
          },
        ),
        const SizedBox(height: 79),
      ],
    );
  }

  // 底部信息 (抽牌后 - 永久显示)
  Widget _buildBottomInfo() {
    int idx = _currentPage.round();
    final card = _shuffledPool[idx];
    final isRev = _isReversedPool[idx];

    return Column(
      children: [
        Text(
          card.name.toUpperCase(),
          style: const TextStyle(fontSize: 26, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (isRev)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(4)
            ),
            child: const Text("REVERSED", style: TextStyle(color: Colors.redAccent, fontSize: 10, letterSpacing: 1.2)),
          ),
        const SizedBox(height: 15),
        Text(
          (isRev ? card.reversedKeywords : card.uprightKeywords).join(" • "),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  void _saveToHistory() {
    int idx = _currentPage.round();
    final card = _shuffledPool[idx];
    final isRev = _isReversedPool[idx];

    final newItem = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: HistoryType.singleTarot,
      timestamp: DateTime.now(),
      payload: {
        'name': card.name,
        'img': card.img,
        'isReversed': isRev,
        'arcana': card.arcana,
        'keywords': isRev ? card.reversedKeywords : card.uprightKeywords,
      },
      question: "Myriad Truths",
      isFavorite: false,
    );

    context.read<HistoryProvider>().addRecord(newItem);
    _feedbackController.forward(from: 0.0);
  }
}