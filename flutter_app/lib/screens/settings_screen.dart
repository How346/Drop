import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name =
      TextEditingController(text: context.read<AppState>().selfName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final panels = <Widget>[
      HDPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Identity', icon: Icons.badge_outlined),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Device name'),
            onSubmitted: state.setName,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                state.setName(_name.text);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Name updated')));
              },
              child: const Text('Save'),
            ),
          ),
        ]),
      ),
      HDPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Discovery & security', icon: Icons.shield_outlined),
          SwitchListTile(
            value: state.discoverable,
            onChanged: state.setDiscoverable,
            title: const Text('Discoverable on this network'),
            subtitle: const Text('Broadcast a beacon so peers can find this device.'),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            value: state.autoAcceptTrusted,
            onChanged: state.setAutoAccept,
            title: const Text('Auto-accept from trusted devices'),
            subtitle: const Text('Skip the approval prompt for devices you trust.'),
          ),
        ]),
      ),
      HDPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Storage', icon: Icons.folder_outlined),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(state.saveDirectory, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final dir = await FilePicker.platform.getDirectoryPath();
              if (dir != null) await state.setSaveDirectory(dir);
            },
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: const Text('Change save folder'),
          ),
        ]),
      ),
      HDPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Appearance', icon: Icons.palette_outlined),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light')),
            ],
            selected: {state.themeMode},
            onSelectionChanged: (s) => state.setThemeMode(s.first),
          ),
        ]),
      ),
      HDPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('About', icon: Icons.info_outline_rounded),
          Text(
            'HyperDrop transfers files directly between devices over your local '
            'network using UDP discovery and an encrypted-integrity TCP stream. '
            'No account, no cloud, no internet required.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ]),
      ),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(20, wide ? 28 : 20, 20, 28),
      children: [
        HDFadeIn(child: Text('Settings', style: Theme.of(context).textTheme.headlineSmall)),
        const SizedBox(height: 20),
        if (wide)
          _wideGrid(panels)
        else
          Column(
            children: [
              for (final panel in panels) ...[panel, const SizedBox(height: 16)],
            ],
          ),
      ],
    );
  }

  Widget _wideGrid(List<Widget> panels) {
    Widget col(List<Widget> items) => Column(
          children: [for (final w in items) ...[w, const SizedBox(height: 16)]],
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: col([panels[0], panels[1]])),
        const SizedBox(width: 16),
        Expanded(child: col([panels[2], panels[3], panels[4]])),
      ],
    );
  }
}
