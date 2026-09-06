import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../services/failures.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Pick a peer on the LAN and enter its six-digit code.
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key, required this.onConnected, this.initialDevice});
  final VoidCallback onConnected;
  final Device? initialDevice;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  String _code = '';
  Device? _selected;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDevice;
  }

  @override
  void didUpdateWidget(covariant ConnectScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDevice != null && widget.initialDevice!.id != oldWidget.initialDevice?.id) {
      setState(() {
        _selected = widget.initialDevice;
        _code = '';
      });
    }
  }

  void _tap(String digit) {
    if (_code.length >= 6) return;
    HapticFeedback.selectionClick();
    setState(() {
      _code += digit;
      _error = null;
    });
  }

  void _backspace() {
    if (_code.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  bool _paired(AppState state) =>
      _selected != null && state.isPaired(_selected!.id);

  Future<void> _send(AppState state) async {
    final target = _selected;
    if (target == null) return;
    if (!state.isPaired(target.id) && _code.length != 6) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final failure = await state.sendOutbox(target, _code);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = failure?.message;
    });
    if (failure == null) widget.onConnected();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final peers = state.peers;
    final paired = _paired(state);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final devicesPanel = HDFadeIn(
      child: HDPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(
            'Nearby devices',
            icon: Icons.wifi_find_rounded,
            trailing: StatusPill(
              label: '${peers.length} found',
              color: peers.isEmpty ? Theme.of(context).colorScheme.outline : HDColors.success,
              dot: true,
            ),
          ),
          if (peers.isEmpty)
            const EmptyState(
              icon: Icons.wifi_find_rounded,
              title: 'Looking for devices',
              body: 'Make sure both devices are on the same Wi-Fi or hotspot '
                  'and discoverable.',
            )
          else
            ...peers.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DeviceTile(
                    device: d,
                    trusted: state.knownDevices[d.id]?.trusted ?? false,
                    selected: _selected?.id == d.id,
                    onTap: () => setState(() => _selected = d),
                  ),
                )),
        ]),
      ),
    );

    final codePanel = HDFadeIn(
      delayMs: 60,
      child: HDPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(
            paired ? 'Paired device' : 'Enter their code',
            icon: paired ? Icons.verified_user_rounded : Icons.dialpad_rounded,
          ),
          if (paired)
            Row(children: [
              const HDIconBadge(icon: Icons.verified_user_rounded, color: HDColors.success, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You are already connected to ${_selected!.name}. '
                  'Send as many files as you like — no code needed.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ])
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < _code.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  width: 42,
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: filled
                        ? HDColors.primary.withOpacity(0.1)
                        : Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: filled ? HDColors.primary : Theme.of(context).dividerColor,
                      width: filled ? 1.8 : 1,
                    ),
                  ),
                  child: Text(filled ? _code[i] : '',
                      style: Theme.of(context).textTheme.headlineSmall),
                );
              }),
            ),
            const SizedBox(height: 20),
            _Keypad(onDigit: _tap, onBackspace: _backspace),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Icon(Icons.inbox_outlined, size: 15, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 6),
            Text('${state.outbox.length} file(s) queued • ${formatBytes(state.outboxBytes)}',
                style: Theme.of(context).textTheme.bodySmall),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.error_outline_rounded, size: 16, color: HDColors.danger),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_error!, style: const TextStyle(color: HDColors.danger)),
              ),
            ]),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _sending || _selected == null || (!paired && _code.length != 6)
                ? null
                : () => _send(state),
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.bolt_rounded, size: 18),
            label: Text(_sending ? 'Sending…' : 'Connect & send'),
          ),
        ]),
      ),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(20, wide ? 28 : 20, 20, 28),
      children: [
        HDFadeIn(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Connect', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Devices on this network appear automatically.',
                style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
        const SizedBox(height: 20),
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: devicesPanel),
                const SizedBox(width: 16),
                Expanded(child: codePanel),
              ],
            ),
          )
        else ...[
          devicesPanel,
          const SizedBox(height: 16),
          codePanel,
        ],
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth.clamp(0, 320).toDouble();
      return Center(
        child: SizedBox(
          width: width,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: keys.map((k) {
              if (k.isEmpty) return const SizedBox.shrink();
              final isBackspace = k == '⌫';
              return Material(
                color: dark ? HDColors.darkRaised : HDColors.lightRaised,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => isBackspace ? onBackspace() : onDigit(k),
                  child: Center(
                    child: isBackspace
                        ? const Icon(Icons.backspace_outlined, size: 18)
                        : Text(k,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}
