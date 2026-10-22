import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/storage/local_storage.dart';

/// Historique global de toutes les rubriques
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'Tous';

  static const _modules = [
    'Tous',
    'Calculatrice',
    'Graphique',
    'Complexes',
    'Matrices',
    'Suites',
    'Convertisseur',
    'Systèmes',
    'Autres',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Effacer tout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Effacer l\'historique ?'),
                  content: const Text('Cette action est irréversible.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Effacer'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<LocalStorage>().clearHistory();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: _modules
                  .map((m) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(m),
                          selected: _filter == m,
                          onSelected: (_) => setState(() => _filter = m),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: Consumer<LocalStorage>(
              builder: (context, storage, child) {
                var history = storage.history;
                if (_filter != 'Tous') {
                  history = history
                      .where((h) => h.module == _filter)
                      .toList();
                }
                if (history.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Aucun calcul enregistré',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Les résultats de toutes les rubriques\napparaissent ici.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final h = history[i];
                    final time =
                        '${h.timestamp.hour.toString().padLeft(2, '0')}:${h.timestamp.minute.toString().padLeft(2, '0')}';
                    final date =
                        '${h.timestamp.day.toString().padLeft(2, '0')}/${h.timestamp.month.toString().padLeft(2, '0')}';
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        child: Text(
                          h.module.isNotEmpty ? h.module[0] : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        h.expression,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${h.module} · $date $time',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          h.result,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.blue,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
