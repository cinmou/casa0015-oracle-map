import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:the_oracle/l10n/app_localizations.dart';
import 'package:the_oracle/providers/tarot_provider.dart';
import 'package:the_oracle/providers/choice_provider.dart';
import 'package:the_oracle/services/auth_service.dart';
import 'package:the_oracle/models/tarot_card.dart';
import 'package:the_oracle/widgets/tarot_card_widget.dart';
import 'package:the_oracle/screens/oracle/oracle_display_screen.dart';

class OracleRandomSingleDrawScreen extends StatefulWidget {
  const OracleRandomSingleDrawScreen({super.key});

  @override
  State<OracleRandomSingleDrawScreen> createState() => _OracleRandomSingleDrawScreenState();
}

class _OracleRandomSingleDrawScreenState extends State<OracleRandomSingleDrawScreen> with SingleTickerProviderStateMixin {
  static const goldColor = Color(0xFFD4AF37);
  static const bgColor = Color(0xFF1A1221);

  TarotCard? _drawnCard;
  bool? _isReversed;
  bool _isFaceUp = false;
  bool _hasFlippedOnce = false;
  bool _hasSaved = false;
  late AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drawRandomCard();
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _drawRandomCard() {
    final provider = context.read<TarotProvider>();
    if (provider.cards.isEmpty) return;
    setState(() {
      final random = Random();
      _drawnCard = provider.cards[random.nextInt(provider.cards.length)];
      _isReversed = random.nextBool();
      _isFaceUp = false;
      _hasFlippedOnce = false;
      _hasSaved = false;
    });
  }

  void _onCardFlipped() {
    if (!_hasFlippedOnce) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isFaceUp = true;
        _hasFlippedOnce = true;
      });
    } else {
      setState(() {
        _isFaceUp = !_isFaceUp;
      });
    }
  }

  void _showSaveDialog() {
    if (_drawnCard == null || _isReversed == null) return;

    final l10n = AppLocalizations.of(context)!;
    final questionController = TextEditingController();
    final solutionController = TextEditingController();
    String selectedMood = '🤔'; 
    
    String resultString = "${_drawnCard!.name} ${_isReversed! ? l10n.singleDrawReversed : ''}".trim();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(l10n.saveToMap),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.saveToMapResult(resultString)), 
                    const SizedBox(height: 16),
                    Text(l10n.saveToMapQuestionHint, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        hintText: "e.g., What should I focus on today?",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.saveToMapMood),
                    DropdownButton<String>(
                      value: selectedMood,
                      isExpanded: true,
                      items: <String>['😃', '😐', '😔', '🤔', '😎', '😠', '😭'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 24)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setStateDialog(() {
                            selectedMood = newValue; 
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.saveToMapSolutionHint, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextField(
                      controller: solutionController,
                      decoration: const InputDecoration(
                        hintText: "e.g., I will meditate for 10 minutes.",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(l10n.cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text(l10n.save),
                  onPressed: () {
                    final question = questionController.text.trim();
                    final solution = solutionController.text.trim();
                    
                    context.read<ChoiceProvider>().addDecisionNode(
                      tool: 'Tarot Draw',
                      result: resultString,
                      question: question,
                      solution: solution,
                      mood: selectedMood,
                    );

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.savedToMapSuccess)),
                    );
                    setState(() {
                      _hasSaved = true;
                    });
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_drawnCard == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: goldColor)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context, l10n),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          SizedBox(
            height: 480,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isFaceUp ? [
                    BoxShadow(
                      color: goldColor.withAlpha(100),
                      blurRadius: 25,
                      spreadRadius: 2,
                    )
                  ] : [],
                ),
                child: TarotCardWidget(
                  card: _drawnCard!,
                  isFaceUp: _isFaceUp,
                  isReversed: _isReversed!,
                  animateOnTap: !_hasFlippedOnce,
                  enableTilt: true,
                  onFlip: _onCardFlipped,
                ),
              ),
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: _hasFlippedOnce ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: _hasFlippedOnce
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildBottomInfo(l10n),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _showMeaningSheet(context, _drawnCard!, _isReversed!, l10n),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            l10n.singleDrawShowMeaning,
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 70),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        highlightElevation: 0,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OracleDisplayScreen()),
          );
        },
        shape: const CircleBorder(),
        backgroundColor: goldColor.withOpacity(0.8),
        child: const Icon(
          Icons.book_outlined,
          color: Colors.white,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppLocalizations l10n) {
    return AppBar(
      title: Text(l10n.oraclePickDailyDraw, style: const TextStyle(color: goldColor, letterSpacing: 1.5)),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: goldColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (_hasFlippedOnce && AuthService().currentUser != null)
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined, color: goldColor),
            tooltip: l10n.saveToMap,
            onPressed: _hasSaved ? null : _showSaveDialog,
          ),
      ],
    );
  }

  void _showMeaningSheet(BuildContext context, TarotCard card, bool isRev, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (BuildContext context, ScrollController scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withAlpha(51),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            card.name,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isRev)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.singleDrawReversed,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
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
                          backgroundColor: colorScheme.surfaceContainer,
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
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomInfo(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          _drawnCard!.name.toUpperCase(),
          style: const TextStyle(fontSize: 26, color: goldColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_isReversed == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent.withAlpha(128)),
                borderRadius: BorderRadius.circular(4)
            ),
            child: Text(l10n.singleDrawReversed, style: const TextStyle(color: Colors.redAccent, fontSize: 10, letterSpacing: 1.2)),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Text(
            (_isReversed! ? _drawnCard!.reversedKeywords : _drawnCard!.uprightKeywords).join(" • "),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
