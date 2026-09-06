import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../models.dart';
import 'failures.dart';

/// Chunked TCP transfer engine, tuned to move data at the full speed the
/// underlying link allows (up to 1 Gbps and beyond on wired gigabit LANs).
///
/// Wire format: newline-delimited JSON control frames, followed by raw bytes
/// for each file body, followed by a small trailer frame carrying the
/// SHA-256 digest. Hashing the file *after* streaming its bytes (rather than
/// before) means the sender never reads a file from disk twice, and the
/// receiver verifies against a hash that's computed in the same single pass
/// it uses to write the file to disk — no separate read-through required on
/// either side.
class TransferService {
  TransferService({required this.selfName, this.selfId = ''});

  /// 4 MiB chunks: large enough to keep syscall/flush overhead low at
  /// gigabit speeds, small enough to keep memory use and progress-update
  /// granularity reasonable.
  static const int defaultChunkSize = 4 << 20;
  static const int protoVersion = 2;

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
  bool _paused = false;
  Completer<void> _pauseGate = Completer<void>()..complete();

  bool get isPaused => _paused;

  /// Pauses the active outbound transfer after the chunk in flight finishes.
  /// The connection stays open; the peer simply waits for more bytes.
  void pause() {
    if (_paused) return;
    _paused = true;
    _pauseGate = Completer<void>();
  }

  /// Resumes a paused outbound transfer.
  void resume() {
    if (!_paused) return;
    _paused = false;
    if (!_pauseGate.isCompleted) _pauseGate.complete();
  }

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
          (pairingCode == null ||
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
    final speed = _RollingSpeed();
    try {
      while (received < size) {
        final chunk = await reader.readBytes(min(defaultChunkSize, size - received));
        if (chunk == null) throw HyperDropException(TransferFailure.connectionLost);
        sink.add(chunk);
        hasher.add(chunk);
        received += chunk.length;
        speed.sample(chunk.length);
        progress
          ..transferredBytes = received
          ..bytesPerSecond = speed.bytesPerSecond
          ..speedHistory.add(speed.bytesPerSecond);
        if (progress.speedHistory.length > 60) progress.speedHistory.removeAt(0);
        _progress.add(progress);
      }
      await sink.flush();
      await sink.close();
      hasher.close();

      // Integrity trailer arrives after the body — the receiver has already
      // written every byte to disk by the time it needs this.
      final trailer = await reader.readFrame();
      final expectedHash = trailer?['sha256'] as String?;
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
    _paused = false;
    if (!_pauseGate.isCompleted) _pauseGate.complete();
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

    socket.add(utf8.encode(encodeFrame({
      'type': 'file',
      'name': entry.name,
      'relativePath': entry.relativePath ?? entry.name,
      'size': size,
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

    // Hashed in the same pass as it's sent — one read of the file, not two.
    final digest = AccumulatorSink<Digest>();
    final hasher = sha256.startChunkedConversion(digest);

    var sent = 0;
    final speed = _RollingSpeed();
    final handle = await file.open();
    try {
      while (sent < size) {
        if (_paused) {
          progress.state = TransferState.paused;
          _progress.add(progress);
          await _pauseGate.future;
          if (!_cancelRequested) {
            progress.state = TransferState.running;
            _progress.add(progress);
          }
        }
        if (_cancelRequested) throw HyperDropException(TransferFailure.cancelled);

        final chunk = await handle.read(min(defaultChunkSize, size - sent));
        if (chunk.isEmpty) break;
        hasher.add(chunk);
        socket.add(chunk);
        await socket.flush(); // backpressure: never outrun the socket buffer
        sent += chunk.length;
        speed.sample(chunk.length);
        progress
          ..transferredBytes = sent
          ..bytesPerSecond = speed.bytesPerSecond
          ..speedHistory.add(speed.bytesPerSecond);
        if (progress.speedHistory.length > 60) progress.speedHistory.removeAt(0);
        _progress.add(progress);
      }
    } finally {
      await handle.close();
    }
    hasher.close();
    final hash = digest.events.single.toString();

    socket.add(utf8.encode(encodeFrame({'type': 'trailer', 'sha256': hash})));
    await socket.flush();

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

/// Tracks throughput over a short trailing window rather than a cumulative
/// average since the transfer started, so the reported speed reflects what
/// the link is doing *right now* — important once transfers run fast enough
/// that a slow first chunk would otherwise drag the average down for a while.
class _RollingSpeed {
  final Queue<_Sample> _samples = Queue<_Sample>();
  static const _window = Duration(milliseconds: 1000);

  void sample(int bytes) {
    final now = DateTime.now();
    _samples.addLast(_Sample(now, bytes));
    while (_samples.isNotEmpty && now.difference(_samples.first.at) > _window) {
      _samples.removeFirst();
    }
  }

  double get bytesPerSecond {
    if (_samples.length < 2) {
      return _samples.isEmpty ? 0 : _samples.first.bytes.toDouble();
    }
    final total = _samples.fold<int>(0, (a, s) => a + s.bytes);
    final spanMs = DateTime.now().difference(_samples.first.at).inMilliseconds;
    if (spanMs <= 0) return 0;
    return total / (spanMs / 1000);
  }
}

class _Sample {
  _Sample(this.at, this.bytes);
  final DateTime at;
  final int bytes;
}

/// Reads newline-delimited JSON control frames and raw byte runs off one
/// socket without ever boxing individual bytes: incoming chunks are kept as
/// [Uint8List] views in a queue, and both frame lines and bulk byte reads are
/// served as zero-copy slices of that queue. This is what lets the receiver
/// keep up with a fast sender instead of falling behind on buffer copies.
class _FrameReader {
  _FrameReader(Socket socket) {
    _sub = socket.listen(
      (data) {
        if (data.isNotEmpty) _queue.add(data);
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
  final Queue<Uint8List> _queue = Queue<Uint8List>();
  int _frontOffset = 0;
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

  /// Returns (line without the newline, total bytes including the newline
  /// to consume) if a full line is currently buffered, else null.
  (Uint8List, int)? _peekLine() {
    if (_queue.isEmpty) return null;
    final first = _queue.first;
    final idx = first.indexOf(10, _frontOffset);
    if (idx >= 0) {
      return (Uint8List.sublistView(first, _frontOffset, idx), idx - _frontOffset + 1);
    }
    if (_queue.length == 1) return null;
    // Rare: a control frame line spans more than one socket read. Only
    // control frames (never bulk file data) take this path, so an
    // occasional concat-and-scan here costs nothing measurable.
    final builder = BytesBuilder(copy: false);
    builder.add(Uint8List.sublistView(first, _frontOffset));
    for (final chunk in _queue.skip(1)) {
      builder.add(chunk);
    }
    final all = builder.toBytes();
    final allIdx = all.indexOf(10);
    if (allIdx < 0) return null;
    return (Uint8List.sublistView(all, 0, allIdx), allIdx + 1);
  }

  void _consume(int n) {
    var remaining = n;
    while (remaining > 0 && _queue.isNotEmpty) {
      final first = _queue.first;
      final availableInFirst = first.length - _frontOffset;
      if (availableInFirst <= remaining) {
        _queue.removeFirst();
        _frontOffset = 0;
        remaining -= availableInFirst;
      } else {
        _frontOffset += remaining;
        remaining = 0;
      }
    }
  }

  Future<Map<String, dynamic>?> readFrame() async {
    while (true) {
      final found = _peekLine();
      if (found != null) {
        final (line, totalLen) = found;
        _consume(totalLen);
        if (line.isEmpty) continue;
        return jsonDecode(utf8.decode(line)) as Map<String, dynamic>;
      }
      if (_done) return null;
      await _wait();
    }
  }

  /// Zero-copy read of up to [max] bytes, taken from whatever is already
  /// queued (may return fewer than [max] bytes — callers loop as needed).
  Future<Uint8List?> readBytes(int max) async {
    while (_queue.isEmpty && !_done) {
      await _wait();
    }
    if (_queue.isEmpty) return null;
    final first = _queue.first;
    final avail = first.length - _frontOffset;
    final take = avail < max ? avail : max;
    final out = Uint8List.sublistView(first, _frontOffset, _frontOffset + take);
    _frontOffset += take;
    if (_frontOffset >= first.length) {
      _queue.removeFirst();
      _frontOffset = 0;
    }
    return out;
  }

  Future<void> close() => _sub.cancel();
}
