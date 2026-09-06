import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.history;
    final history = _query.trim().isEmpty
        ? all
        : all
            .where((h) =>
                h.fileName.toLowerCase().contains(_query.toLowerCase()) ||
                h.deviceName.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return ListView(padding: EdgeInsets.fromLTRB(20, wide ? 28 : 20, 20, 28), children: [
      HDFadeIn(
        child: Row(children: [
          Expanded(child: Text('History', style: Theme.of(context).textTheme.headlineSmall)),
          if (all.isNotEmpty)
            TextButton(onPressed: state.clearHistory, child: const Text('Clear')),
        ]),
      ),
      const SizedBox(height: 4),
      Text('Stored on this device only. Nothing is uploaded anywhere.',
          style: Theme.of(context).textTheme.bodyMedium),
      if (all.isNotEmpty) ...[
        const SizedBox(height: 16),
        HDFadeIn(
          delayMs: 30,
          child: Row(children: [
            Expanded(
                child: HDStatTile(
                    icon: Icons.north_east_rounded,
                    label: 'Sent',
                    value: formatBytes(state.totalSentBytes),
                    color: HDColors.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: HDStatTile(
                    icon: Icons.south_west_rounded,
                    label: 'Received',
                    value: formatBytes(state.totalReceivedBytes),
                    color: HDColors.accent)),
          ]),
        ),
        const SizedBox(height: 16),
        HDFadeIn(
          delayMs: 45,
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded, size: 20),
              hintText: 'Search by file name or device',
            ),
          ),
        ),
      ],
      const SizedBox(height: 20),
      HDFadeIn(
        delayMs: 60,
        child: HDPanel(
          child: history.isEmpty
              ? EmptyState(
                  icon: Icons.history_rounded,
                  title: all.isEmpty ? 'No transfers yet' : 'No matches',
                  body: all.isEmpty
                      ? 'Completed and failed transfers will be listed here.'
                      : 'Try a different search term.',
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
