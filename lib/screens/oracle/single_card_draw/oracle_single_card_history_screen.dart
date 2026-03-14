import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/history_provider.dart';
import '../../../models/history_item.dart';

class OracleSingleCardHistoryScreen extends StatelessWidget {
  const OracleSingleCardHistoryScreen({super.key});

  // Method to show the confirmation dialog before clearing history
  Future<void> _confirmClearHistory(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final historyProvider = context.read<HistoryProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.clearHistory),
          content: Text(l10n.clearHistoryConfirmation),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(l10n.clear, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await historyProvider.clearNonFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const Color goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1221),
      appBar: AppBar(
        title: Text(l10n.oraclePickDailyDraw, style: const TextStyle(color: goldColor, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: l10n.clearHistory,
            onPressed: () => _confirmClearHistory(context),
          ),
        ],
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          // Filter records to show only single tarot draws
          final records = provider.records.where((r) => r.type == HistoryType.singleTarot).toList();

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
    final payload = item.payload;
    final String timeStr = DateFormat('yyyy-MM-dd HH:mm').format(item.timestamp);
    final bool isRev = payload['isReversed'] ?? false;
    final dynamic keywordsData = item.payload['keywords'];
    final String keywordsText = (keywordsData != null)
        ? (keywordsData is List ? keywordsData.join(" • ") : keywordsData.toString())
        : "";

    return Card(
      color: Colors.white.withAlpha(13),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: GestureDetector(
        onLongPress: () {
          _showDeleteConfirmDialog(context, item, provider, l10n);
          HapticFeedback.mediumImpact();
        },
        child: ExpansionTile(
          leading: Icon(
            isRev ? Icons.arrow_downward : Icons.arrow_upward,
            color: isRev ? Colors.orange : Colors.green,
          ),
          title: Text(payload['name'] ?? "Unknown", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${l10n.question}: ", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.question,
                          style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Color(0xFFD4AF37)),
                        onPressed: () => _showEditQuestionDialog(context, item, provider, l10n),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  Text(
                    keywordsText,
                    style: TextStyle(
                      color: goldColor.withAlpha(204),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    softWrap: true,
                  ),
                ],
              ),
            )
          ],
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
          l10n.deleteRecordConfirmation(item.payload['name'] ?? 'this record'),
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
