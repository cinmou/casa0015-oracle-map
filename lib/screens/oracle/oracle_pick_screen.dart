import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/tarot_provider.dart';
import '../../providers/settings_provider.dart';
import 'oracle_display_screen.dart';
import 'single_card_draw/oracle_random_single_draw_screen.dart'; // Updated import
import 'past_present_future/oracle_past_present_future_screen.dart';

class OraclePickScreen extends StatefulWidget {
  const OraclePickScreen({super.key});

  @override
  State<OraclePickScreen> createState() => _OraclePickScreenState();
}

class _OraclePickScreenState extends State<OraclePickScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      context.read<TarotProvider>().init(settings.languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.oraclePickTitle, style: const TextStyle(letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _buildMenuCard(
            context,
            l10n.oraclePickLibrary,
            Icons.auto_stories_rounded,
            Colors.amber,
            const OracleDisplayScreen(),
          ),
          _buildMenuCard(
            context,
            l10n.oraclePickDailyDraw,
            Icons.auto_stories_rounded,
            Colors.deepPurpleAccent,
            const OracleRandomSingleDrawScreen(), // Updated navigation target
          ),
          _buildMenuCard(
            context,
            l10n.oraclePickClassicSpread,
            Icons.style_outlined,
            Colors.blueGrey,
            const OraclePastPresentFutureScreen(),
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
