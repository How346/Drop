import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../models.dart';
import 'failures.dart';

/// Chunked TCP transfer engine.
///
/// Wire format: newline-delimited JSON control frames, followed by raw bytes
/// for each file body. Every file is hashed incrementally with SHA-256 and
/// verified by the receiver before the `.part` file is atomically renamed.
class TransferService {
  TransferService({required this.selfName, this.selfId = ''});

  static const int defaultChunkSize = 1 << 20; // 1 MiB
  static const int protoVersion = 1;

  final String selfName;
  final String selfId;

  ServerSocket? _server;
  int get port => _server?.port ?? 0;

  /// Pairing code the receiver currently accepts (null = not accepting).
  String? pairingCode;
  DateTime? _codeIssuedAt;
  int _wrongAttempts = 0;
  DateTime? _lockedUntil;

  String saveDirectory = '';
  bool autoAcceptTrusted = false;

  /// Long-lived pairing secrets. Keyed by peer device id; a peer that presents
  /// a matching secret never has to type the code again. Secrets are only ever
  /// issued after a correct code, are 256-bit random, and are compared in
  /// constant time.
  final Map<String, String> sessions = {};

  /// Fired whenever [sessions] changes so the caller can persist them.
  void Function()? onSessionsChanged;

  /// Lets the caller veto a peer (blocked device book entry).
  bool Function(String deviceId)? isBlocked;

  /// Called on the sending side once a peer hands back a pairing secret.
  void Function(String deviceId, String token)? onPaired;

  final _progress = StreamController<TransferProgress>.broadcast();
  Stream<TransferProgress> get progress => _progress.stream;

  final _completed = StreamController<HistoryEntry>.broadcast();
  Stream<HistoryEntry> get completed => _completed.stream;

  /// Asked when an incoming transfer needs explicit user approval.
  Future<bool> Function(String deviceName, List<FileEntry> files)? onIncomingRequest;

  bool _cancelRequested = false;

  static bool _secretEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static String _newSecret() {
    final rnd = Random.secure();
    return List.generate(32, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// Forgets the pairing secret for one peer (used by "unpair" / "block").
  void forgetSession(String deviceId) {
    if (sessions.remove(deviceId) != null) onSessionsChanged?.call();
  }


  // ---------------------------------------------------------------- receiver

  Future<int> startServer() async {
    if (_server != null) return _server!.port;
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _server!.listen(_handleConnection);
    return _server!.port;
  }

  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
  }

  String issueCode() {
    final rnd = Random.secure();
    final code = List.generate(6, (_) => rnd.nextInt(10)).join();
    pairingCode = code;
    _codeIssuedAt = DateTime.now();
    _wrongAttempts = 0;
    return code;
  }

  void clearCode() {
    pairingCode = null;
    _codeIssuedAt = null;
  }

  bool get codeExpired =>
      _codeIssuedAt == null ||
      DateTime.now().difference(_codeIssuedAt!) > const Duration(minutes: 5);

  Future<void> _handleConnection(Socket socket) async {
    socket.setOption(SocketOption.tcpNoDelay, true);
    final reader = _FrameReader(socket);
    try {
      final hello = await reader.readFrame();
      if (hello == null) return;

      if (_lockedUntil != null && DateTime.now().isBefore(_lockedUntil!)) {
        socket.add(utf8.encode(encodeFrame({'type': 'error', 'reason': 'locked'})));
        await socket.flush();
        await socket.close();
        return;
      }

      final peerId = hello['deviceId'] as String? ?? '';
      if (peerId.isNotEmpty && (isBlocked?.call(peerId) ?? false)) {
        socket.add(utf8.encode(encodeFrame({'type': 'reject', 'reason': 'blocked'})));
        await socket.flush();
        await socket.close();
        return;
      }

      final presented = hello['token'] as String?;
      final stored = peerId.isEmpty ? null : sessions[peerId];
      final paired =
          presented != null && stored != null && _secretEquals(stored, presented);

      if (!paired &&
          (hello['proto'] != protoVersion ||
              pairingCode == null ||
              codeExpired ||
              hello['code'] is! String ||
              !_secretEquals(pairingCode!, hello['code'] as String))) {
        _wrongAttempts++;
        if (_wrongAttempts >= 5) {
          _lockedUntil = DateTime.now().add(const Duration(seconds: 60));
        }
        socket.add(utf8.encode(encodeFrame({
          'type': 'error',
          'reason': codeExpired ? 'expiredCode' : 'invalidCode',
        })));
        await socket.flush();
        await socket.close();
        return;
      }
      if (!paired) _wrongAttempts = 0;

      final senderName = hello['deviceName'] as String? ?? 'Unknown device';
      final files = ((hello['files'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map((f) => FileEntry(
                name: f['name'] as String,
                path: '',
                size: (f['size'] as num).toInt(),
                relativePath: f['relativePath'] as String?,
              ))
          .toList();

      // A device that already completed the code handshake stays connected:
      // no prompt, no code, for every later file it sends.
      final accepted = paired || autoAcceptTrusted
          ? true
          : (await onIncomingRequest?.call(senderName, files) ?? false);

      String? issuedToken;
      if (accepted && peerId.isNotEmpty) {
        issuedToken = stored ?? _newSecret();
        if (sessions[peerId] != issuedToken) {
          sessions[peerId] = issuedToken;
          onSessionsChanged?.call();
        }
      }

      socket.add(utf8.encode(encodeFrame({
        'type': accepted ? 'accept' : 'reject',
        'deviceName': selfName,
        'deviceId': selfId,
        'chunkSize': defaultChunkSize,
        if (issuedToken != null) 'token': issuedToken,
      })));
      await socket.flush();


      if (!accepted) {
        await socket.close();
        return;
      }

      for (final _ in files) {
        final header = await reader.readFrame();
        if (header == null) throw HyperDropException(TransferFailure.connectionLost);
        await _receiveFile(reader, socket, header, senderName);
      }
      await socket.close();
    } on HyperDropException catch (e) {
      _progress.add(TransferProgress(
        fileName: '',
        direction: TransferDirection.receive,
        totalBytes: 0,
        state: TransferState.failed,
        error: e.failure.message,
      ));
      socket.destroy();
    } catch (_) {
      socket.destroy();
    }
  }

  Future<void> _receiveFile(
    _FrameReader reader,
    Socket socket,
    Map<String, dynamic> header,
    String senderName,
  ) async {
    final rawName = header['name'] as String;
    final size = (header['size'] as num).toInt();
    final expectedHash = header['sha256'] as String?;
    final safeName = _sanitizeFileName(rawName);

    final dir = Directory(saveDirectory);
    if (!await dir.exists()) {
      throw HyperDropException(TransferFailure.destinationMissing);
    }

    final finalPath = _uniquePath(p.join(dir.path, safeName));
    final partFile = File('$finalPath.part');
    final sink = partFile.openWrite();

    final progress = TransferProgress(
      fileName: safeName,
      direction: TransferDirection.receive,
      totalBytes: size,
      state: TransferState.running,
    );
    _progress.add(progress);

    final digest = AccumulatorSink<Digest>();
    final hasher = sha256.startChunkedConversion(digest);

    var received = 0;
    final started = DateTime.now();
    try {
      while (received < size) {
        final chunk = await reader.readBytes(min(defaultChunkSize, size - received));
        if (chunk == null) throw HyperDropException(TransferFailure.connectionLost);
        sink.add(chunk);
        hasher.add(chunk);
        received += chunk.length;
        progress
          ..transferredBytes = received
          ..bytesPerSecond = _speed(received, started);
        _progress.add(progress);
      }
      await sink.flush();
      await sink.close();
      hasher.close();

      final actual = digest.events.single.toString();
      if (expectedHash != null && actual != expectedHash) {
        await partFile.delete();
        throw HyperDropException(TransferFailure.checksumMismatch);
      }

      await partFile.rename(finalPath);
      progress.state = TransferState.completed;
      _progress.add(progress);

      socket.add(utf8.encode(encodeFrame({'type': 'ack', 'name': safeName})));
      await socket.flush();

      _completed.add(HistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        fileName: safeName,
        deviceName: senderName,
        direction: TransferDirection.receive,
        bytes: size,
        at: DateTime.now(),
        status: 'completed',
        savedPath: finalPath,
      ));
    } catch (e) {
      await sink.close().catchError((_) {});
      if (await partFile.exists()) await partFile.delete();
      progress
        ..state = TransferState.failed
        ..error = e is HyperDropException
            ? e.failure.message
            : TransferFailure.connectionLost.message;
      _progress.add(progress);
      _completed.add(HistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        fileName: safeName,
        deviceName: senderName,
        direction: TransferDirection.receive,
        bytes: received,
        at: DateTime.now(),
        status: 'failed',
        note: progress.error,
      ));
      rethrow;
    }
  }

  // ------------------------------------------------------------------ sender

  void cancel() => _cancelRequested = true;

  Future<void> send({
    required Device target,
    String code = '',
    String? token,
    required List<FileEntry> files,
  }) async {
    _cancelRequested = false;
    Socket? socket;
    try {
      socket = await Socket.connect(target.address, target.port,
          timeout: const Duration(seconds: 8));
      socket.setOption(SocketOption.tcpNoDelay, true);
      final reader = _FrameReader(socket);

      socket.add(utf8.encode(encodeFrame({
        'proto': protoVersion,
        'type': 'hello',
        'code': code,
        if (token != null) 'token': token,
        'deviceId': selfId,
        'deviceName': selfName,
        'files': files.map((f) => f.toJson()).toList(),
      })));
      await socket.flush();

      final reply = await reader.readFrame();
      if (reply == null) throw HyperDropException(TransferFailure.connectionLost);
      if (reply['type'] == 'error') {
        final reason = reply['reason'] as String?;
        throw HyperDropException(reason == 'expiredCode'
            ? TransferFailure.expiredCode
            : TransferFailure.invalidCode);
      }
      if (reply['type'] != 'accept') {
        throw HyperDropException(TransferFailure.rejected);
      }

      final granted = reply['token'] as String?;
      if (granted != null && target.id.isNotEmpty) {
        onPaired?.call(target.id, granted);
      }


      for (var i = 0; i < files.length; i++) {
        await _sendFile(socket, reader, files[i], i, files.length, target.name);
      }
      await socket.flush();
      await socket.close();
    } on HyperDropException {
      socket?.destroy();
      rethrow;
    } on SocketException {
      socket?.destroy();
      throw HyperDropException(TransferFailure.deviceNotFound);
    } catch (_) {
      socket?.destroy();
      throw HyperDropException(TransferFailure.unknown);
    }
  }

  Future<void> _sendFile(
    Socket socket,
    _FrameReader reader,
    FileEntry entry,
    int index,
    int count,
    String targetName,
  ) async {
    final file = File(entry.path);
    if (!await file.exists()) {
      throw HyperDropException(TransferFailure.fileAccessDenied);
    }
    final size = await file.length();

    // Hash first so the receiver can verify integrity (streamed, low memory).
    final digest = AccumulatorSink<Digest>();
    final hasher = sha256.startChunkedConversion(digest);
    await for (final chunk in file.openRead()) {
      hasher.add(chunk);
    }
    hasher.close();
    final hash = digest.events.single.toString();

    socket.add(utf8.encode(encodeFrame({
      'type': 'file',
      'name': entry.name,
      'relativePath': entry.relativePath ?? entry.name,
      'size': size,
      'sha256': hash,
    })));
    await socket.flush();

    final progress = TransferProgress(
      fileName: entry.name,
      direction: TransferDirection.send,
      totalBytes: size,
      state: TransferState.running,
      fileIndex: index,
      fileCount: count,
    );
    _progress.add(progress);

    var sent = 0;
    final started = DateTime.now();
    final handle = await file.open();
    try {
      while (sent < size) {
        if (_cancelRequested) throw HyperDropException(TransferFailure.cancelled);
        final chunk = await handle.read(min(defaultChunkSize, size - sent));
        if (chunk.isEmpty) break;
        socket.add(chunk);
        await socket.flush(); // backpressure: never outrun the socket buffer
        sent += chunk.length;
        progress
          ..transferredBytes = sent
          ..bytesPerSecond = _speed(sent, started);
        _progress.add(progress);
      }
    } finally {
      await handle.close();
    }

    final ack = await reader.readFrame();
    if (ack == null || ack['type'] != 'ack') {
      progress
        ..state = TransferState.failed
        ..error = TransferFailure.connectionLost.message;
      _progress.add(progress);
      throw HyperDropException(TransferFailure.connectionLost);
    }

    progress.state = TransferState.completed;
    _progress.add(progress);
    _completed.add(HistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fileName: entry.name,
      deviceName: targetName,
      direction: TransferDirection.send,
      bytes: size,
      at: DateTime.now(),
      status: 'completed',
    ));
  }

  double _speed(int bytes, DateTime started) {
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    if (elapsed <= 0) return 0;
    return bytes / (elapsed / 1000);
  }

  String _sanitizeFileName(String name) {
    var clean = p.basename(name).replaceAll(RegExp(r'[\x00-\x1f<>:"/\\|?*]'), '_');
    if (clean.isEmpty || clean == '.' || clean == '..') clean = 'received_file';
    const reserved = {'CON', 'PRN', 'AUX', 'NUL', 'COM1', 'LPT1'};
    if (reserved.contains(clean.toUpperCase())) clean = '_$clean';
    return clean;
  }

  String _uniquePath(String desired) {
    var candidate = desired;
    var n = 1;
    while (File(candidate).existsSync() || File('$candidate.part').existsSync()) {
      final dir = p.dirname(desired);
      final ext = p.extension(desired);
      final base = p.basenameWithoutExtension(desired);
      candidate = p.join(dir, '$base ($n)$ext');
      n++;
    }
    return candidate;
  }

  void dispose() {
    stopServer();
    _progress.close();
    _completed.close();
  }
}

/// Reads newline-delimited JSON frames and raw byte runs off one socket.
class _FrameReader {
  _FrameReader(Socket socket) {
    _sub = socket.listen(
      (data) {
        _buffer.addAll(data);
        _pump();
      },
      onDone: () {
        _done = true;
        _pump();
      },
      onError: (_) {
        _done = true;
        _pump();
      },
      cancelOnError: false,
    );
  }

  late final StreamSubscription<Uint8List> _sub;
  final List<int> _buffer = [];
  bool _done = false;
  Completer<void>? _waiter;

  void _pump() {
    final w = _waiter;
    if (w != null && !w.isCompleted) {
      _waiter = null;
      w.complete();
    }
  }

  Future<void> _wait() {
    if (_done) return Future.value();
    _waiter ??= Completer<void>();
    return _waiter!.future;
  }

  Future<Map<String, dynamic>?> readFrame() async {
    while (true) {
      final idx = _buffer.indexOf(10); // '\n'
      if (idx >= 0) {
        final line = utf8.decode(_buffer.sublist(0, idx));
        _buffer.removeRange(0, idx + 1);
        if (line.trim().isEmpty) continue;
        return jsonDecode(line) as Map<String, dynamic>;
      }
      if (_done) return null;
      await _wait();
    }
  }

  Future<List<int>?> readBytes(int max) async {
    while (_buffer.isEmpty && !_done) {
      await _wait();
    }
    if (_buffer.isEmpty) return null;
    final take = min(max, _buffer.length);
    final out = _buffer.sublist(0, take);
    _buffer.removeRange(0, take);
    return out;
  }

  Future<void> close() => _sub.cancel();
}
