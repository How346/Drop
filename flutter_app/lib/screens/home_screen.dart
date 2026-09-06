import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onGoConnect});

  /// Navigates to Connect. When [device] is provided (quick-send tap), the
  /// Connect screen preselects it instead of showing an empty device list.
  final void Function([Device? device]) onGoConnect;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, wide ? 28 : 20, 20, 28),
      children: [
        if (!wide) ...[
          HDFadeIn(
            child: Row(children: [
              const BrandMark(),
              const SizedBox(width: 10),
              Text('HyperDrop', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              StatusPill(
                label: state.discoverable ? 'Discoverable' : 'Hidden',
                color: state.discoverable ? HDColors.success : HDColors.warning,
                icon: state.discoverable ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ] else
          HDFadeIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('Share files instantly — no internet, no accounts.',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        if (wide) const SizedBox(height: 24),
        HDFadeIn(
          child: HDHeroPanel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const HDIconBadge(icon: Icons.qr_code_2_rounded, size: 30, iconSize: 16),
                        const SizedBox(width: 10),
                        Text('Your connection code',
                            style: Theme.of(context).textTheme.titleMedium),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        'Share this with the sending device. Works entirely on your '
                        'local network — no internet required.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              Center(
                child: ShaderMask(
                  shaderCallback: (rect) => HDColors.brandGradient.createShader(rect),
                  child: Text(
                    state.myCode == null ? '— — — — — —' : _spaced(state.myCode!),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          letterSpacing: 6,
                          color: Colors.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      state.issueCode();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(state.myCode == null ? 'Generate code' : 'New code'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.myCode == null
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: state.myCode!));
                            HapticFeedback.selectionClick();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied')),
                            );
                          },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
              ]),
              if (state.myCode != null) ...[
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.timer_outlined, size: 14, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 6),
                  Text('Expires 5 minutes after it was generated.',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 16),
        if (state.recentOnlineDevices.isNotEmpty) ...[
          HDFadeIn(delayMs: 40, child: _quickSendRow(context, state)),
          const SizedBox(height: 16),
        ],
        HDFadeIn(
          delayMs: 60,
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _deviceInfoPanel(context, state)),
                    const SizedBox(width: 16),
                    Expanded(child: _sendPanel(context)),
                  ],
                )
              : Column(children: [
                  _deviceInfoPanel(context, state),
                  const SizedBox(height: 16),
                  _sendPanel(context),
                ]),
        ),
        if (state.totalSentBytes > 0 || state.totalReceivedBytes > 0) ...[
          const SizedBox(height: 16),
          HDFadeIn(
            delayMs: 90,
            child: wide
                ? Row(children: [
                    Expanded(
                        child: HDStatTile(
                            icon: Icons.north_east_rounded,
                            label: 'Total sent',
                            value: formatBytes(state.totalSentBytes),
                            color: HDColors.primary)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: HDStatTile(
                            icon: Icons.south_west_rounded,
                            label: 'Total received',
                            value: formatBytes(state.totalReceivedBytes),
                            color: HDColors.accent)),
                  ])
                : Row(children: [
                    Expanded(
                        child: HDStatTile(
                            icon: Icons.north_east_rounded,
                            label: 'Total sent',
                            value: formatBytes(state.totalSentBytes),
                            color: HDColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: HDStatTile(
                            icon: Icons.south_west_rounded,
                            label: 'Total received',
                            value: formatBytes(state.totalReceivedBytes),
                            color: HDColors.accent)),
                  ]),
          ),
        ],
      ],
    );
  }

  Widget _quickSendRow(BuildContext context, AppState state) {
    return HDPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Quick send', icon: Icons.bolt_rounded),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.recentOnlineDevices.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final d = state.recentOnlineDevices[i];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onGoConnect(d),
                child: Container(
                  width: 92,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? HDColors.darkBorder
                                : HDColors.lightBorder),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    HDIconBadge(icon: iconForKind(d.kind), size: 34, iconSize: 17),
                    const SizedBox(height: 6),
                    Text(d.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _deviceInfoPanel(BuildContext context, AppState state) {
    return HDPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('This device', icon: Icons.info_outline_rounded),
        _row(context, Icons.badge_outlined, 'Name', state.selfName),
        _row(context, Icons.folder_outlined, 'Save folder', state.saveDirectory),
        _row(context, Icons.settings_ethernet_rounded, 'Listening port', '${state.transfer.port}'),
        _row(context, Icons.people_outline_rounded, 'Peers online', '${state.peers.length}',
            isLast: true),
      ]),
    );
  }

  Widget _sendPanel(BuildContext context) {
    return HDPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Send to a device', icon: Icons.send_outlined),
        Text(
          'Pick files or a folder, choose a nearby device, and send at full '
          'local-network speed.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => onGoConnect(),
          icon: const Icon(Icons.bolt_rounded, size: 18),
          label: const Text('Send files to a device'),
        ),
      ]),
    );
  }

  static String _spaced(String code) => code.split('').join(' ');

  Widget _row(BuildContext context, IconData icon, String label, String value,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 10),
        SizedBox(
          width: 108,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        ),
      ]),
    );
  }
}
