import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(historyVmProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyVmProvider);
    final notifier = ref.watch(historyVmProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: state.items.isEmpty
                ? null
                : () async {
                    final path = await notifier.exportPdf();
                    if (path != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Exported PDF to $path')),
                      );
                    }
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.load,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.items.isEmpty
                ? const Center(child: Text('No history yet.'))
                : ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return ListTile(
                        leading: Icon(item.isFavorite ? Icons.star : Icons.qr_code),
                        title: Text(item.data.value),
                        subtitle: Text(item.createdAt.toLocal().toString()),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'favorite':
                                notifier.toggleFavorite(item.id.value);
                                break;
                              case 'delete':
                                notifier.delete(item.id.value);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'favorite',
                              child: Text(item.isFavorite ? 'Unfavorite' : 'Favorite'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: notifier.load,
        icon: const Icon(Icons.refresh),
        label: const Text('Reload'),
      ),
    );
  }
}
