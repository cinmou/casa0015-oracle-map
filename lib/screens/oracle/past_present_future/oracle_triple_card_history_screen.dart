import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/history_provider.dart';
import '../../../models/history_item.dart';

class OracleTripleCardHistoryScreen extends StatelessWidget {
  const OracleTripleCardHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const Color goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1221),
      appBar: AppBar(
        title: Text(l10n.tripleCardHistoryTitle, style: const TextStyle(color: goldColor, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          final records = provider.records.where((r) => r.type == HistoryType.threeSpread).toList();

          if (records.isEmpty) {
            return Center(child: Text(l10n.noHistory, style: const TextStyle(color: Colors.white24)));
          }

          return ListView.builder(
            itemCount: records.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = records[index];
              return _buildHistoryItem(context, item, provider, goldColor, l10n);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, HistoryItem item, HistoryProvider provider, Color goldColor, AppLocalizations l10n) {
    final String timeStr = DateFormat('yyyy-MM-dd HH:mm').format(item.timestamp);
    final List<dynamic> cards = item.payload['cards'] ?? [];

    return Card(
      color: Colors.white.withAlpha(13),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Ensures the InkWell ripple effect respects the border radius
      child: InkWell(
        onLongPress: () {
          _showDeleteConfirmDialog(context, item, provider, l10n);
          HapticFeedback.mediumImpact();
        },
        child: ExpansionTile(
          title: Text(
            item.question,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          trailing: IconButton(
            icon: Icon(
              item.isFavorite ? Icons.bookmark : Icons.bookmark_border,
              color: item.isFavorite ? goldColor : Colors.white24,
            ),
            onPressed: () {
              item.isFavorite = !item.isFavorite;
              provider.updateRecord(item);
            },
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 10),
                  ...List.generate(cards.length, (index) {
                    final cardData = cards[index];
                    final cardName = cardData['name'] ?? 'Unknown';
                    final isReversed = cardData['isReversed'] ?? false;
                    final position = cardData['position'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          _buildPositionChip(position, goldColor),
                          const SizedBox(width: 12),
                          Expanded(child: Text(cardName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                          if (isReversed) Text(l10n.singleDrawReversed, style: const TextStyle(color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Color(0xFFD4AF37)),
                      onPressed: () => _showEditQuestionDialog(context, item, provider, l10n),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionChip(String position, Color goldColor) {
    return Container(
      width: 80, // Fixed width for alignment
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: goldColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goldColor.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          position.toUpperCase(),
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, HistoryItem item, HistoryProvider provider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.deleteRecord, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.deleteRecordConfirmation(item.question),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRecord(item.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.recordDeleted), duration: const Duration(seconds: 1)),
              );
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showEditQuestionDialog(BuildContext context, HistoryItem item, HistoryProvider provider, AppLocalizations l10n) {
    final TextEditingController controller = TextEditingController(text: item.question);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.editQuestion, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.editQuestionHint,
            hintStyle: const TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              item.question = controller.text;
              provider.updateRecord(item);
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
