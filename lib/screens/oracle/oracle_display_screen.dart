import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../models/tarot_card.dart';
import '../../widgets/tarot_card_widget.dart';
import '../../providers/tarot_provider.dart';

class OracleDisplayScreen extends StatefulWidget {
  const OracleDisplayScreen({super.key});

  @override
  State<OracleDisplayScreen> createState() => _OracleDisplayScreenState();
}

class _OracleDisplayScreenState extends State<OracleDisplayScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isCurrentCardFaceUp = true;
  bool _testReversed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showCardPicker(BuildContext context, List<TarotCard> cards) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              Text(l10n.tarotDisplaySelectCard, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Text("#${cards[index].number}"),
                      title: Text(cards[index].name),
                      selected: _currentIndex == index,
                      onTap: () {
                        _pageController.jumpToPage(index);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TarotProvider>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    const bgColor = Color(0xFF1A1221);
    const goldColor = Color(0xFFD4AF37);

    if (provider.isLoading) {
      return const Scaffold(backgroundColor: bgColor, body: Center(child: CircularProgressIndicator()));
    }

    final cards = provider.cards;
    if (cards.isEmpty) return const Scaffold(body: Center(child: Text("No Data")));

    final currentCard = cards[_currentIndex];

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.tarotDisplayTitle, style: const TextStyle(color: goldColor)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: goldColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_open, color: goldColor),
            onPressed: () => _showCardPicker(context, cards),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 100),
                SizedBox(
                  height: 450,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: cards.length,
                        onPageChanged: (i) => setState(() {
                          _currentIndex = i;
                          _isCurrentCardFaceUp = true;
                        }),
                        itemBuilder: (context, index) {
                          return Center(
                            child: TarotCardWidget(
                              card: cards[index],
                              isFaceUp: index == _currentIndex ? _isCurrentCardFaceUp : true,
                              isReversed: _testReversed,
                              animateOnTap: true,
                              enableTilt: true,
                              onFlip: () {
                                if (index == _currentIndex) {
                                  setState(() => _isCurrentCardFaceUp = !_isCurrentCardFaceUp);
                                }
                              },
                            ),
                          );
                        },
                      ),
                      _buildArrows(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 20,
            child: _buildReversedToggle(),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.32,
            maxChildSize: 0.86,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      _buildDragHandle(theme.colorScheme),
                      _buildDescriptionContent(currentCard, theme.colorScheme.onSurface, l10n),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionContent(TarotCard card, Color textColor, AppLocalizations l10n) {
    bool isMajor = card.arcana.toLowerCase().contains("major");
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(card.name, style: TextStyle(fontSize: 24, color: textColor)),
              ),
              const SizedBox(width: 10),
              Text(
                _toRoman(card.number),
                style: TextStyle(fontSize: 22, color: textColor.withAlpha(128), letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(card.arcana, Colors.amber.shade700, textColor),
              if (!isMajor && card.suit != null)
                _buildInfoChip(card.suit!, Colors.blueGrey, textColor),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(thickness: 0.5, color: Colors.grey),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMeaningSection(l10n.tarotDisplayUprightMeaning, card.uprightKeywords, card.uprightMeaning, Icons.arrow_upward, Colors.green, textColor, l10n),
              const SizedBox(height: 24),
              _buildMeaningSection(l10n.tarotDisplayReversedMeaning, card.reversedKeywords, card.reversedMeaning, Icons.arrow_downward, Colors.orange, textColor, l10n),
              const SizedBox(height: 30),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMeaningSection(String title, List<String> keywords, String meaning, IconData icon, Color iconColor, Color textColor, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.tarotDisplayKeywords(keywords.join(' · ')), style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(meaning, style: TextStyle(color: textColor.withAlpha(204), fontSize: 16, height: 1.6)),
      ],
    );
  }

  Widget _buildDragHandle(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40, height: 5,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildArrows() {
    const Color darkGold = Color(0xFFB8860B);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: darkGold),
            onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: darkGold),
            onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _buildReversedToggle() {
    return GestureDetector(
      onTap: () async {
        setState(() => _testReversed = !_testReversed);
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 350));
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 230));
        await HapticFeedback.selectionClick();
      },
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: _testReversed ? Colors.amber : Colors.grey.withAlpha(51), shape: BoxShape.circle),
        child: Icon(Icons.rotate_right, color: _testReversed ? Colors.black : Colors.grey),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
    );
  }

  String _toRoman(String numberStr) {
    int? n = int.tryParse(numberStr);
    if (n == null || n == 0) return "0";
    final Map<int, String> romanMap = { 10: 'X', 9: 'IX', 5: 'V', 4: 'IV', 1: 'I' };
    String result = '';
    for (var key in [10, 9, 5, 4, 1]) {
      while (n! >= key) {
        result += romanMap[key]!;
        n -= key;
      }
    }
    return result;
  }
}
