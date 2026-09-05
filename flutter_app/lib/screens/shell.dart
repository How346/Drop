import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'connect_screen.dart';
import 'devices_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'transfer_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _wired = false;

  static const _destinations = [
    (icon: Icons.home_outlined, selected: Icons.home_rounded, label: 'Home'),
    (icon: Icons.link_outlined, selected: Icons.link_rounded, label: 'Connect'),
    (icon: Icons.swap_vert_outlined, selected: Icons.swap_vert_rounded, label: 'Transfer'),
    (icon: Icons.history_outlined, selected: Icons.history_rounded, label: 'History'),
    (icon: Icons.devices_outlined, selected: Icons.devices_rounded, label: 'Devices'),
    (icon: Icons.settings_outlined, selected: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.ready && !_wired) {
      _wired = true;
      state.incomingPrompt = _promptIncoming;
    }

    if (!state.ready) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const BrandMark(size: 56, iconSize: 30),
            const SizedBox(height: 20),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ]),
        ),
      );
    }

    final pages = [
      HomeScreen(onGoConnect: () => setState(() => _index = 1)),
      ConnectScreen(onConnected: () => setState(() => _index = 2)),
      const TransferScreen(),
      const HistoryScreen(),
      const DevicesScreen(),
      const SettingsScreen(),
    ];

    final page = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
    );

    final wide = MediaQuery.sizeOf(context).width >= 900;
    final extended = MediaQuery.sizeOf(context).width >= 1180;

    if (wide) {
      return Scaffold(
        body: Row(children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).navigationRailTheme.backgroundColor,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? HDColors.darkBorder
                      : HDColors.lightBorder,
                ),
              ),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Row(
                  mainAxisAlignment:
                      extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    const BrandMark(),
                    if (extended) ...[
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('HyperDrop', style: Theme.of(context).textTheme.titleMedium),
                          Text('Fast file share',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: NavigationRail(
                  backgroundColor: Colors.transparent,
                  extended: extended,
                  minExtendedWidth: 200,
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selected),
                        label: Text(d.label),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _ConnectionBadge(extended: extended, state: state),
              ),
            ]),
          ),
          Expanded(child: SafeArea(child: page)),
        ]),
      );
    }

    return Scaffold(
      body: SafeArea(child: page),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
    );
  }

  Future<bool> _promptIncoming(String deviceName, List<FileEntry> files) async {
    final total = files.fold<int>(0, (a, f) => a + f.size);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const HDIconBadge(icon: Icons.download_rounded, size: 36),
          const SizedBox(width: 12),
          const Expanded(child: Text('Incoming transfer')),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$deviceName wants to send ${files.length} '
                '${files.length == 1 ? 'file' : 'files'} (${formatBytes(total)}).'),
            const SizedBox(height: 12),
            ...files.take(5).map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• ${f.name} — ${formatBytes(f.size)}',
                      style: Theme.of(ctx).textTheme.bodySmall),
                )),
            if (files.length > 5)
              Text('and ${files.length - 5} more…',
                  style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Decline')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Accept')),
        ],
      ),
    );
    if (result == true && mounted) setState(() => _index = 2);
    return result ?? false;
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.extended, required this.state});
  final bool extended;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final online = state.discoverable;
    final color = online ? HDColors.success : Theme.of(context).colorScheme.outline;
    if (!extended) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            online ? 'Discoverable' : 'Hidden',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ]),
    );
  }
}
