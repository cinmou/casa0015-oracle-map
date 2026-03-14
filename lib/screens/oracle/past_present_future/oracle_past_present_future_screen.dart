import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/tarot_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../models/tarot_card.dart';
import '../../../models/history_item.dart';
import '../../../widgets/tarot_card_widget.dart';
import 'oracle_triple_card_history_screen.dart'; // Corrected import

class OraclePastPresentFutureScreen extends StatefulWidget {
  const OraclePastPresentFutureScreen({super.key});

  @override
  State<OraclePastPresentFutureScreen> createState() => _OraclePastPresentFutureScreenState();
}

class _OraclePastPresentFutureScreenState extends State<OraclePastPresentFutureScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _feedbackController;

  List<TarotCard> _spreadCards = [];
  List<bool> _isReversed = [];
  final List<bool> _isFaceUp = [false, false, false];
  int _currentIndex = 0;
  bool _hasSaved = false;

  late List<String> _positionTitles;
  late List<String> _positionDescriptions;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.75);
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocalizations();
      _prepareSpread();
    });
  }

  void _initializeLocalizations() {
    final l10n = AppLocalizations.of(context)!;
    _positionTitles = [l10n.pastPresentFuturePast, l10n.pastPresentFuturePresent, l10n.pastPresentFutureFuture];
    _positionDescriptions = [l10n.pastPresentFuturePastDesc, l10n.pastPresentFuturePresentDesc, l10n.pastPresentFutureFutureDesc];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeLocalizations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _prepareSpread() {
    final provider = context.read<TarotProvider>();
    if (provider.cards.length < 3) return;

    setState(() {
      final shuffled = List<TarotCard>.from(provider.cards)..shuffle();
      _spreadCards = shuffled.take(3).toList();
      _isReversed = List.generate(3, (_) => Random().nextBool());
    });
  }

  void _onCardFlipped(int index) {
    if (_isFaceUp[index]) return;
    setState(() {
      _isFaceUp[index] = true;
    });
    if (!_hasSaved && _isFaceUp.every((v) => v)) {
      _saveSpreadToHistory();
    }
  }

  bool get _allRevealed => _isFaceUp.every((element) => element == true);

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    const bgColor = Color(0xFF1A1221);
    final l10n = AppLocalizations.of(context)!;

    if (_spreadCards.isEmpty) {
      return const Scaffold(backgroundColor: bgColor, body: Center(child: CircularProgressIndicator(color: goldColor)));
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context, goldColor, l10n),
      body: Column(
        children: [
          const SizedBox(height: 4),
          _buildTopIndicator(goldColor),
          const Spacer(),
          SizedBox(
            height: 460,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: 3,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                    HapticFeedback.selectionClick();
                  },
                  itemBuilder: (context, index) {
                    return _buildCardItem(index);
                  },
                ),
                if (_currentIndex > 0)
                  const Positioned(left: 10, child: Icon(Icons.arrow_back_ios, color: Colors.white12, size: 30)),
                if (_currentIndex < 2)
                  const Positioned(right: 10, child: Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 30)),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (_isFaceUp[_currentIndex])
                  _buildShortInfo(_currentIndex, goldColor, l10n)
                else
                  Text(
                    l10n.singleDrawTapToReveal,
                    style: const TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 14),
                  ),
                const SizedBox(height: 20),
                AnimatedOpacity(
                  opacity: _allRevealed ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: _allRevealed ? ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) =>
                          ReadingSummaryScreen(
                            cards: _spreadCards,
                            isReversed: _isReversed,
                          )
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: const StadiumBorder(),
                      // elevation: 8,
                      // shadowColor: goldColor.withAlpha(128),
                    ),
                    child: Text(
                        l10n.pastPresentFutureReadFullMeaning,
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)
                    ),
                  ) : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCardItem(int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        } else {
          value = index == _currentIndex ? 1.0 : 0.7;
        }
        bool isOpen = _isFaceUp[index];
        return Center(
          child: Transform.scale(
            scale: value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: TarotCardWidget(
                card: _spreadCards[index],
                isFaceUp: isOpen,
                isReversed: _isReversed[index],
                animateOnTap: !isOpen,
                enableTilt: true,
                onFlip: () => _onCardFlipped(index),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShortInfo(int index, Color goldColor, AppLocalizations l10n) {
    final card = _spreadCards[index];
    final isRev = _isReversed[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          Text(
            card.name.toUpperCase(),
            style: const TextStyle(fontSize: 26, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            (isRev ? card.reversedKeywords : card.uprightKeywords).join(" • "),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          ),
          if (isRev)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(l10n.singleDrawReversed, style: const TextStyle(color: Colors.redAccent, fontSize: 10, letterSpacing: 1.2)),
            )
        ],
      ),
    );
  }

  Widget _buildTopIndicator(Color goldColor) {
    return Column(
      children: [
        Text(
          _positionTitles[_currentIndex],
          style: TextStyle(
              color: goldColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 3.0,
              shadows: [Shadow(color: goldColor.withAlpha(128), blurRadius: 10)]
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _positionDescriptions[_currentIndex].toUpperCase(),
          style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.0),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color goldColor, AppLocalizations l10n) {
    return AppBar(
      title: Text(l10n.pastPresentFutureTitle, style: TextStyle(color: goldColor, letterSpacing: 1.5)),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFD4AF37)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
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
                          colors: [goldColor.withAlpha((glowOpacity * 255).toInt()), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.history, color: _feedbackController.isAnimating ? Colors.white : goldColor),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OracleTripleCardHistoryScreen())),
                )
              ],
            );
          },
        ),
      ],
    );
  }

  void _saveSpreadToHistory() {
    if (_hasSaved) return;
    final l10n = AppLocalizations.of(context)!;
    final Map<String, dynamic> multiCardPayload = {
      'spreadType': 'PastPresentFuture',
      'cards': [
        _buildMiniSnapshot(_spreadCards[0], _isReversed[0], l10n.pastPresentFuturePast),
        _buildMiniSnapshot(_spreadCards[1], _isReversed[1], l10n.pastPresentFuturePresent),
        _buildMiniSnapshot(_spreadCards[2], _isReversed[2], l10n.pastPresentFutureFuture),
      ]
    };
    final newItem = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: HistoryType.threeSpread,
      timestamp: DateTime.now(),
      payload: multiCardPayload,
      question: l10n.pastPresentFutureTitle,
      isFavorite: false,
    );
    context.read<HistoryProvider>().addRecord(newItem);
    _feedbackController.forward(from: 0.0);
    setState(() => _hasSaved = true);
  }

  Map<String, dynamic> _buildMiniSnapshot(TarotCard card, bool isRev, String position) {
    return {
      'name': card.name,
      'img': card.img,
      'isReversed': isRev,
      'position': position,
      'keywords': isRev ? card.reversedKeywords : card.uprightKeywords,
    };
  }
}

class ReadingSummaryScreen extends StatelessWidget {
  final List<TarotCard> cards;
  final List<bool> isReversed;

  const ReadingSummaryScreen({
    super.key,
    required this.cards,
    required this.isReversed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final titles = [l10n.pastPresentFuturePast, l10n.pastPresentFuturePresent, l10n.pastPresentFutureFuture];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(l10n.readingSummaryTitle),
            centerTitle: false,
            backgroundColor: colorScheme.surface,
            scrolledUnderElevation: 0,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final card = cards[index];
                final isRev = isReversed[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest.withAlpha(128),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titles[index].toUpperCase(),
                            style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                card.name,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (isRev)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(4)
                                    ),
                                    child: Text(
                                        l10n.readingSummaryReversedAbbr,
                                        style: textTheme.labelSmall?.copyWith(
                                            color: colorScheme.error,
                                            fontWeight: FontWeight.bold
                                        )
                                    ),
                                  ),
                                )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: (isRev ? card.reversedKeywords : card.uprightKeywords).map((keyword) {
                              return Chip(
                                label: Text(keyword),
                                labelStyle: textTheme.bodySmall,
                                backgroundColor: colorScheme.surface,
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            isRev ? card.reversedMeaning : card.uprightMeaning,
                            style: textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: 3,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}
