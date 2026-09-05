import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final history = state.history;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return ListView(padding: EdgeInsets.fromLTRB(20, wide ? 28 : 20, 20, 28), children: [
      HDFadeIn(
        child: Row(children: [
          Expanded(child: Text('History', style: Theme.of(context).textTheme.headlineSmall)),
          if (history.isNotEmpty)
            TextButton(onPressed: state.clearHistory, child: const Text('Clear')),
        ]),
      ),
      const SizedBox(height: 4),
      Text('Stored on this device only. Nothing is uploaded anywhere.',
          style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 20),
      HDFadeIn(
        delayMs: 60,
        child: HDPanel(
          child: history.isEmpty
              ? const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No transfers yet',
                  body: 'Completed and failed transfers will be listed here.',
                )
              : Column(
                  children: [
                    for (final h in history) ...[
                      _HistoryRow(entry: h),
                      if (h != history.last) const Divider(height: 22),
                    ]
                  ],
                ),
        ),
      ),
    ]);
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final ok = entry.status == 'completed';
    final sent = entry.direction == TransferDirection.send;
    return Row(children: [
      HDIconBadge(
        icon: sent ? Icons.north_east_rounded : Icons.south_west_rounded,
        color: ok ? HDColors.success : HDColors.danger,
        size: 40,
        iconSize: 18,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.fileName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            '${sent ? 'To' : 'From'} ${entry.deviceName} • ${formatBytes(entry.bytes)}'
            '${entry.note == null ? '' : ' • ${entry.note}'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ]),
      ),
      const SizedBox(width: 8),
      Text(_time(entry.at), style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  static String _time(DateTime at) {
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return 'now';
    if (d.inHours < 1) return '${d.inMinutes}m';
    if (d.inDays < 1) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}
