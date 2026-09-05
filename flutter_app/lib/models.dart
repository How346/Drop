import 'dart:convert';

enum DeviceKind { androidPhone, androidTablet, windowsDesktop, windowsLaptop }

DeviceKind kindFromName(String v) => DeviceKind.values.firstWhere(
      (k) => k.name == v,
      orElse: () => DeviceKind.androidPhone,
    );

class Device {
  Device({
    required this.id,
    required this.name,
    required this.kind,
    required this.address,
    required this.port,
    this.trusted = false,
    this.blocked = false,
    this.lastSeen,
  });

  final String id;
  final String name;
  final DeviceKind kind;
  final String address;
  final int port;
  final bool trusted;
  final bool blocked;
  final DateTime? lastSeen;

  bool get isWindows =>
      kind == DeviceKind.windowsDesktop || kind == DeviceKind.windowsLaptop;

  Device copyWith({bool? trusted, bool? blocked, DateTime? lastSeen, String? address}) => Device(
        id: id,
        name: name,
        kind: kind,
        address: address ?? this.address,
        port: port,
        trusted: trusted ?? this.trusted,
        blocked: blocked ?? this.blocked,
        lastSeen: lastSeen ?? this.lastSeen,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'address': address,
        'port': port,
        'trusted': trusted,
        'blocked': blocked,
        'lastSeen': lastSeen?.toIso8601String(),
      };

  factory Device.fromJson(Map<String, dynamic> j) => Device(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: kindFromName(j['kind'] as String? ?? 'androidPhone'),
        address: j['address'] as String? ?? '',
        port: (j['port'] as num?)?.toInt() ?? 0,
        trusted: j['trusted'] as bool? ?? false,
        blocked: j['blocked'] as bool? ?? false,
        lastSeen: j['lastSeen'] == null ? null : DateTime.tryParse(j['lastSeen'] as String),
      );
}

class FileEntry {
  FileEntry({
    required this.name,
    required this.path,
    required this.size,
    this.relativePath,
  });

  final String name;
  final String path;
  final int size;
  final String? relativePath;

  Map<String, dynamic> toJson() => {
        'name': name,
        'size': size,
        'relativePath': relativePath ?? name,
      };
}

enum TransferState { idle, negotiating, running, paused, completed, failed, cancelled }

enum TransferDirection { send, receive }

class TransferProgress {
  TransferProgress({
    required this.fileName,
    required this.direction,
    required this.totalBytes,
    this.transferredBytes = 0,
    this.bytesPerSecond = 0,
    this.state = TransferState.idle,
    this.fileIndex = 0,
    this.fileCount = 1,
    this.error,
  });

  final String fileName;
  final TransferDirection direction;
  final int totalBytes;
  int transferredBytes;
  double bytesPerSecond;
  TransferState state;
  int fileIndex;
  int fileCount;
  String? error;

  double get fraction => totalBytes == 0 ? 0 : (transferredBytes / totalBytes).clamp(0, 1);

  Duration get eta {
    if (bytesPerSecond <= 0) return Duration.zero;
    final remaining = totalBytes - transferredBytes;
    return Duration(seconds: (remaining / bytesPerSecond).round());
  }
}

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.fileName,
    required this.deviceName,
    required this.direction,
    required this.bytes,
    required this.at,
    required this.status,
    this.note,
    this.savedPath,
  });

  final String id;
  final String fileName;
  final String deviceName;
  final TransferDirection direction;
  final int bytes;
  final DateTime at;
  final String status; // completed | failed | cancelled
  final String? note;
  final String? savedPath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'deviceName': deviceName,
        'direction': direction.name,
        'bytes': bytes,
        'at': at.toIso8601String(),
        'status': status,
        'note': note,
        'savedPath': savedPath,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as String,
        fileName: j['fileName'] as String,
        deviceName: j['deviceName'] as String,
        direction: j['direction'] == 'send' ? TransferDirection.send : TransferDirection.receive,
        bytes: (j['bytes'] as num).toInt(),
        at: DateTime.parse(j['at'] as String),
        status: j['status'] as String,
        note: j['note'] as String?,
        savedPath: j['savedPath'] as String?,
      );
}

/// Newline-delimited JSON control frames used by the transfer protocol.
String encodeFrame(Map<String, dynamic> frame) => '${jsonEncode(frame)}\n';

/// Human formatting helpers (decimal units, matching the design reference).
String formatBytes(int bytes, {int digits = 2}) {
  if (bytes < 1000) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1000;
  var i = 0;
  while (value >= 1000 && i < units.length - 1) {
    value /= 1000;
    i++;
  }
  return '${value.toStringAsFixed(value >= 100 ? 0 : digits)} ${units[i]}';
}

String formatSpeed(double bytesPerSecond) =>
    '${formatBytes(bytesPerSecond.round(), digits: 1)}/s';

String formatDuration(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds}s';
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '${m}m ${s.toString().padLeft(2, '0')}s';
}
