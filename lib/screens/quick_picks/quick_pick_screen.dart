import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart'; // Corrected import path
import 'coin_flip_screen.dart';
import 'dice_roll_screen.dart';

class QuickPickScreen extends StatelessWidget {
  const QuickPickScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quickPickTitle)),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _buildMenuCard(
            context,
            l10n.quickPickCoinFlip,
            Icons.monetization_on_outlined,
            Colors.orange,
            const CoinFlipScreen(),
          ),
          _buildMenuCard(
            context,
            l10n.quickPickDiceRoll,
            Icons.casino_outlined,
            Colors.blue,
            const DiceRollScreen(),
          ),
          _buildMenuCard(
            context,
            l10n.quickPickDrawCard,
            Icons.style_outlined,
            Colors.red,
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, Widget? targetPage) {
    return InkWell(
      onTap: () {
        if (targetPage != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title is coming soon!')));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(77), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
