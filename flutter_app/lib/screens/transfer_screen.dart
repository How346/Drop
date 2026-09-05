import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

IconData _iconForFile(String name) {
  final ext = p.extension(name).toLowerCase().replaceFirst('.', '');
  const images = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'heic', 'bmp', 'svg'};
  const videos = {'mp4', 'mov', 'mkv', 'avi', 'webm'};
  const audio = {'mp3', 'wav', 'flac', 'aac', 'm4a'};
  const docs = {'doc', 'docx', 'txt', 'rtf', 'odt'};
  const sheets = {'xls', 'xlsx', 'csv'};
  const slides = {'ppt', 'pptx', 'key'};
  const archives = {'zip', 'rar', '7z', 'tar', 'gz'};
  if (images.contains(ext)) return Icons.image_outlined;
  if (videos.contains(ext)) return Icons.movie_outlined;
  if (audio.contains(ext)) return Icons.audiotrack_outlined;
  if (docs.contains(ext)) return Icons.description_outlined;
  if (sheets.contains(ext)) return Icons.table_chart_outlined;
  if (slides.contains(ext)) return Icons.slideshow_outlined;
  if (archives.contains(ext)) return Icons.folder_zip_outlined;
  if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
  return Icons.insert_drive_file_outlined;
}

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});

  Future<void> _pickFiles(AppState state) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    state.addFiles(result.files.where((f) => f.path != null).map((f) => FileEntry(
          name: f.name,
          path: f.path!,
          size: f.size,
        )));
  }

  Future<void> _pickFolder(AppState state) async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return;
    final root = Directory(dir);
    final entries = <FileEntry>[];
    await for (final e in root.list(recursive: true, followLinks: false)) {
      if (e is File) {
        entries.add(FileEntry(
          name: p.basename(e.path),
          path: e.path,
          size: await e.length(),
          relativePath: p.relative(e.path, from: root.parent.path),
        ));
      }
    }
    state.addFiles(entries);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final active = state.active;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final queuePanel = HDFadeIn(
      delayMs: active != null ? 60 : 0,
      child: HDPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle('Queue',
              icon: Icons.inbox_outlined,
              trailing: state.outbox.isEmpty
                  ? null
                  : TextButton(
                      onPressed: state.clearOutbox, child: const Text('Clear'))),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _pickFiles(state),
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: const Text('Add files'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickFolder(state),
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Add folder'),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          if (state.outbox.isEmpty)
            const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Nothing queued',
              body: 'Add files or a folder, then pair from the Connect tab.',
            )
          else ...[
            ...state.outbox.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    HDIconBadge(icon: _iconForFile(f.name), size: 36, iconSize: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.relativePath ?? f.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          Text(formatBytes(f.size), style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => state.removeFile(f),
                    ),
                  ]),
                )),
            const Divider(height: 24),
            Row(children: [
              Icon(Icons.folder_copy_outlined, size: 16, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 8),
              Text('${state.outbox.length} files • ${formatBytes(state.outboxBytes)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ],
        ]),
      ),
    );

    final content = <Widget>[
      HDFadeIn(
        child: Text('Transfer', style: Theme.of(context).textTheme.headlineSmall),
      ),
      const SizedBox(height: 20),
    ];

    if (active != null) {
      content.add(HDFadeIn(child: _ActiveTransferCard(active: active, onCancel: state.cancelTransfer)));
      content.add(const SizedBox(height: 16));
    }

    content.add(queuePanel);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, wide ? 28 : 20, 20, 28),
      children: content,
    );
  }
}

class _ActiveTransferCard extends StatelessWidget {
  const _ActiveTransferCard({required this.active, required this.onCancel});
  final TransferProgress active;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final sending = active.direction == TransferDirection.send;
    final color = switch (active.state) {
      TransferState.completed => HDColors.success,
      TransferState.failed => HDColors.danger,
      TransferState.cancelled => HDColors.warning,
      _ => HDColors.primary,
    };

    return HDHeroPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          HDIconBadge(
            icon: sending ? Icons.upload_rounded : Icons.download_rounded,
            color: color,
            size: 44,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sending ? 'Sending' : 'Receiving',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(active.fileName.isEmpty ? '—' : active.fileName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          StatusPill(label: active.state.name, color: color),
        ]),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: active.fraction),
            duration: const Duration(milliseconds: 260),
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 10,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            Text('${formatBytes(active.transferredBytes)} / ${formatBytes(active.totalBytes)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (active.state == TransferState.running) ...[
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.speed_rounded, size: 14, color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 4),
                Text(formatSpeed(active.bytesPerSecond),
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.timer_outlined, size: 14, color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 4),
                Text('${formatDuration(active.eta)} left',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
            ],
          ],
        ),
        if (active.fileCount > 1) ...[
          const SizedBox(height: 8),
          Text('File ${active.fileIndex + 1} of ${active.fileCount}',
              style: Theme.of(context).textTheme.bodySmall),
        ],
        if (active.error != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.error_outline_rounded, size: 16, color: HDColors.danger),
            const SizedBox(width: 6),
            Expanded(child: Text(active.error!, style: const TextStyle(color: HDColors.danger))),
          ]),
        ],
        if (active.state == TransferState.running) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancel transfer'),
          ),
        ],
      ]),
    );
  }
}
