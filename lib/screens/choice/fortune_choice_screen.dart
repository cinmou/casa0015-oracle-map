import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:the_oracle/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:the_oracle/providers/choice_provider.dart';

enum FortuneStickResult { short, medium, long }

class FortuneStickScreen extends StatefulWidget {
  const FortuneStickScreen({super.key});

  @override
  State<FortuneStickScreen> createState() => _FortuneStickScreenState();
}

class _FortuneStickScreenState extends State<FortuneStickScreen> with SingleTickerProviderStateMixin {
  FortuneStickResult? _currentResult;
  bool _hasResult = false;

  // Shake-related state variables
  bool _isShakeEnabled = false;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastShakeTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _accelerometerSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      if (!_isShakeEnabled) return;
      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (acceleration > 15.0) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inMilliseconds > 400) {
          _drawStick();
          _lastShakeTime = now;
        }
      }
    });
  }

  void _drawStick() {
    setState(() {
      _hasResult = false;
    });

    final random = Random();
    final int resultIndex = random.nextInt(FortuneStickResult.values.length);
    _currentResult = FortuneStickResult.values[resultIndex];

    HapticFeedback.mediumImpact();
    setState(() {
      _hasResult = true;
    });
  }

  void _showSaveDialog() {
    if (_currentResult == null) return;

    final l10n = AppLocalizations.of(context)!;
    final questionController = TextEditingController();
    final solutionController = TextEditingController();
    String selectedMood = '🤔'; 
    
    String resultString = '';
    switch(_currentResult) {
      case FortuneStickResult.short: resultString = "Short Stick"; break; // TODO: Localize
      case FortuneStickResult.medium: resultString = "Medium Stick"; break; // TODO: Localize
      case FortuneStickResult.long: resultString = "Long Stick"; break; // TODO: Localize
      default: resultString = "Unknown";
    }

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
                        hintText: "e.g., Should I take this new opportunity?",
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
                    Text("My final decision is...", style: Theme.of(context).textTheme.labelLarge), // TODO: Add to l10n
                    const SizedBox(height: 8),
                    TextField(
                      controller: solutionController,
                      decoration: const InputDecoration(
                        hintText: "e.g., I will go for it!",
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
                      tool: 'Fortune Stick', // TODO: Localize
                      result: resultString,
                      question: question,
                      solution: solution, 
                      mood: selectedMood,
                    );

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.savedToMapSuccess)),
                    );
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
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text("Fortune Stick"), // TODO: Localize
        actions: [
          if (_hasResult)
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: l10n.saveToMap,
              onPressed: _showSaveDialog,
            ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _drawStick,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStickCylinder(),
              const SizedBox(height: 40),
              if (_hasResult && _currentResult != null)
                _buildDrawnStick(_currentResult!),
              const SizedBox(height: 20),
              Text(
                _hasResult ? _getStickResultText(l10n) : "Tap or shake to draw a stick", // TODO: Localize
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        highlightElevation: 0,
        onPressed: () {
          setState(() {
            _isShakeEnabled = !_isShakeEnabled;
          });
          if (_isShakeEnabled) {
            HapticFeedback.selectionClick();
          }
        },
        shape: const CircleBorder(),
        backgroundColor: _isShakeEnabled ? Colors.amber.shade700 : Colors.grey.shade400,
        child: Icon(
          _isShakeEnabled ? Icons.vibration : Icons.mobile_off,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStickCylinder() {
    return Container(
      width: 120,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.brown.shade700,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.brown.shade900, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Sticks inside the cylinder
          Positioned(
            top: 10,
            child: Column(
              children: List.generate(5, (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Container(
                  width: 80,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
          ),
          // Top rim
          Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.brown.shade800,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: Colors.brown.shade900, width: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawnStick(FortuneStickResult result) {
    double height;
    String text;
    final l10n = AppLocalizations.of(context)!;

    switch (result) {
      case FortuneStickResult.short:
        height = 80;
        text = "Short"; // TODO: Localize
        break;
      case FortuneStickResult.medium:
        height = 100;
        text = "Medium"; // TODO: Localize
        break;
      case FortuneStickResult.long:
        height = 120;
        text = "Long"; // TODO: Localize
        break;
    }

    return Container(
      width: 30,
      height: height,
      decoration: BoxDecoration(
        color: Colors.amber.shade200,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.amber.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _getStickResultText(AppLocalizations l10n) {
    switch (_currentResult) {
      case FortuneStickResult.short: return "You drew a Short Stick!"; // TODO: Localize
      case FortuneStickResult.medium: return "You drew a Medium Stick!"; // TODO: Localize
      case FortuneStickResult.long: return "You drew a Long Stick!"; // TODO: Localize
      default: return "Draw a stick to see your fortune."; // TODO: Localize
    }
  }
}
