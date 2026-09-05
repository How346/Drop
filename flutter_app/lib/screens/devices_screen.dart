import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final known = state.knownDevices.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final onlineIds = state.peers.map((p) => p.id).toSet();
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return ListView(padding: EdgeInsets.fromLTRB(20, wide ? 28 : 20, 20, 28), children: [
      HDFadeIn(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Devices', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Paired devices keep sending without a code. Trust, unpair or block '
                  'any device here.',
              style: Theme.of(context).textTheme.bodyMedium),
        ]),
      ),
      const SizedBox(height: 20),
      HDFadeIn(
        delayMs: 60,
        child: HDPanel(
          child: known.isEmpty
              ? const EmptyState(
                  icon: Icons.devices_other_rounded,
                  title: 'No devices yet',
                  body: 'Devices you discover or transfer with appear here.',
                )
              : Column(
                  children: [
                    for (final d in known)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DeviceTile(
                          device: d,
                          trusted: d.trusted,
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (state.isPaired(d.id)) ...[
                              const StatusPill(label: 'Paired', color: HDColors.primary),
                              const SizedBox(width: 6),
                            ],
                            StatusPill(
                              label: onlineIds.contains(d.id) ? 'Online' : 'Offline',
                              color: onlineIds.contains(d.id)
                                  ? HDColors.success
                                  : Theme.of(context).colorScheme.outline,
                              dot: true,
                            ),
                            const SizedBox(width: 2),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 20),
                              onSelected: (v) {
                                if (v == 'trust') state.setTrusted(d.id, !d.trusted);
                                if (v == 'block') state.setBlocked(d.id, !d.blocked);
                                if (v == 'unpair') state.unpair(d.id);
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'trust',
                                  child: Text(d.trusted ? 'Remove trust' : 'Trust device'),
                                ),
                                if (state.isPaired(d.id))
                                  const PopupMenuItem(
                                    value: 'unpair',
                                    child: Text('End pairing (ask for code)'),
                                  ),
                                PopupMenuItem(
                                  value: 'block',
                                  child: Text(d.blocked ? 'Unblock' : 'Block device'),
                                ),
                              ],
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    ]);
  }
}
