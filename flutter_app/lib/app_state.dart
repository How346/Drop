import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'services/discovery_service.dart';
import 'services/failures.dart';
import 'services/transfer_service.dart';

/// Single source of truth for the app: identity, discovery, transfers,
/// history and preferences. Everything works fully offline.
class AppState extends ChangeNotifier {
  AppState();

  late DiscoveryService discovery;
  late TransferService transfer;

  String selfId = '';
  String selfName = 'My device';
  DeviceKind selfKind =
      Platform.isWindows ? DeviceKind.windowsDesktop : DeviceKind.androidPhone;

  bool ready = false;
  bool discoverable = true;
  bool autoAcceptTrusted = false;
  ThemeMode themeMode = ThemeMode.dark;
  String saveDirectory = '';

  String? myCode;
  DateTime? codeIssuedAt;

  List<Device> peers = [];
  final Map<String, Device> knownDevices = {};
  List<HistoryEntry> history = [];
  TransferProgress? active;
  String? lastError;

  final List<FileEntry> outbox = [];

  /// Peers we already completed a code handshake with. While a pairing lasts,
  /// files flow both ways without typing the code again.
  final Map<String, String> pairedTokens = {};

  bool isPaired(String deviceId) => pairedTokens.containsKey(deviceId);

  /// Presented when a peer requests to send us files.
  Future<bool> Function(String deviceName, List<FileEntry> files)? incomingPrompt;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    selfId = prefs.getString('selfId') ??
        DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    await prefs.setString('selfId', selfId);
    selfName = prefs.getString('selfName') ?? _defaultName();
    discoverable = prefs.getBool('discoverable') ?? true;
    autoAcceptTrusted = prefs.getBool('autoAcceptTrusted') ?? false;
    themeMode = (prefs.getString('themeMode') ?? 'dark') == 'light'
        ? ThemeMode.light
        : ThemeMode.dark;

    saveDirectory = prefs.getString('saveDirectory') ?? await _defaultSaveDir();
    await Directory(saveDirectory).create(recursive: true);

    for (final raw in prefs.getStringList('knownDevices') ?? const []) {
      final d = Device.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      knownDevices[d.id] = d;
    }
    history = (prefs.getStringList('history') ?? const [])
        .map((r) => HistoryEntry.fromJson(jsonDecode(r) as Map<String, dynamic>))
        .toList();

    for (final raw in prefs.getStringList('sessions') ?? const []) {
      final parts = raw.split('|');
      if (parts.length == 2) pairedTokens[parts[0]] = parts[1];
    }

    transfer = TransferService(selfName: selfName, selfId: selfId)
      ..saveDirectory = saveDirectory
      ..autoAcceptTrusted = autoAcceptTrusted
      ..isBlocked = ((id) => knownDevices[id]?.blocked ?? false)
      ..onIncomingRequest = (name, files) async =>
          await incomingPrompt?.call(name, files) ?? false;
    transfer.sessions.addAll(pairedTokens);
    transfer.onSessionsChanged = () {
      pairedTokens
        ..clear()
        ..addAll(transfer.sessions);
      _persistSessions();
      notifyListeners();
    };
    transfer.onPaired = (id, token) {
      if (pairedTokens[id] == token) return;
      pairedTokens[id] = token;
      transfer.sessions[id] = token;
      _persistSessions();
      notifyListeners();
    };

    final port = await transfer.startServer();

    discovery = DiscoveryService(
      selfId: selfId,
      selfName: selfName,
      selfKind: selfKind,
      transferPort: port,
    )..discoverable = discoverable;
    await discovery.start();

    discovery.peers.listen((list) {
      peers = list.where((d) => !(knownDevices[d.id]?.blocked ?? false)).toList();
      for (final p in peers) {
        knownDevices[p.id] =
            (knownDevices[p.id] ?? p).copyWith(lastSeen: p.lastSeen, address: p.address);
      }
      notifyListeners();
    });

    transfer.progress.listen((p) {
      active = p;
      if (p.state == TransferState.failed) lastError = p.error;
      notifyListeners();
    });

    transfer.completed.listen((entry) {
      history = [entry, ...history].take(200).toList();
      _persistHistory();
      notifyListeners();
    });

    ready = true;
    notifyListeners();
  }

  String _defaultName() => Platform.isWindows ? 'Windows PC' : 'Android device';

  Future<String> _defaultSaveDir() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download/HyperDrop');
      if (await Directory('/storage/emulated/0/Download').exists()) return dir.path;
    }
    final base = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    return '${base.path}${Platform.pathSeparator}HyperDrop';
  }

  // ------------------------------------------------------------- preferences

  Future<void> _prefs(void Function(SharedPreferences p) f) async {
    final p = await SharedPreferences.getInstance();
    f(p);
  }

  Future<void> setName(String value) async {
    selfName = value.trim().isEmpty ? _defaultName() : value.trim();
    discovery.selfName = selfName;
    await _prefs((p) => p.setString('selfName', selfName));
    notifyListeners();
  }

  Future<void> setDiscoverable(bool value) async {
    discoverable = value;
    discovery.discoverable = value;
    await _prefs((p) => p.setBool('discoverable', value));
    notifyListeners();
  }

  Future<void> setAutoAccept(bool value) async {
    autoAcceptTrusted = value;
    transfer.autoAcceptTrusted = value;
    await _prefs((p) => p.setBool('autoAcceptTrusted', value));
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _prefs((p) => p.setString('themeMode', mode == ThemeMode.light ? 'light' : 'dark'));
    notifyListeners();
  }

  Future<void> setSaveDirectory(String dir) async {
    saveDirectory = dir;
    transfer.saveDirectory = dir;
    await Directory(dir).create(recursive: true);
    await _prefs((p) => p.setString('saveDirectory', dir));
    notifyListeners();
  }

  // ------------------------------------------------------------------ codes

  String issueCode() {
    myCode = transfer.issueCode();
    codeIssuedAt = DateTime.now();
    discovery.advertisedCode = myCode;
    notifyListeners();
    return myCode!;
  }

  void clearCode() {
    myCode = null;
    codeIssuedAt = null;
    transfer.clearCode();
    discovery.advertisedCode = null;
    notifyListeners();
  }

  // ------------------------------------------------------------- device book

  void setTrusted(String id, bool trusted) {
    final d = knownDevices[id];
    if (d == null) return;
    knownDevices[id] = d.copyWith(trusted: trusted);
    _persistDevices();
    notifyListeners();
  }

  void setBlocked(String id, bool blocked) {
    final d = knownDevices[id];
    if (d == null) return;
    knownDevices[id] = d.copyWith(blocked: blocked);
    if (blocked) {
      peers = peers.where((p) => p.id != id).toList();
      pairedTokens.remove(id);
      transfer.forgetSession(id);
      _persistSessions();
    }
    _persistDevices();
    notifyListeners();
  }

  Future<void> _persistDevices() => _prefs((p) => p.setStringList(
      'knownDevices', knownDevices.values.map((d) => jsonEncode(d.toJson())).toList()));

  Future<void> _persistSessions() => _prefs((p) => p.setStringList(
      'sessions', pairedTokens.entries.map((e) => '${e.key}|${e.value}').toList()));

  /// Ends a pairing: the peer must enter a fresh code next time.
  void unpair(String deviceId) {
    pairedTokens.remove(deviceId);
    transfer.forgetSession(deviceId);
    _persistSessions();
    notifyListeners();
  }

  Future<void> _persistHistory() => _prefs(
      (p) => p.setStringList('history', history.map((h) => jsonEncode(h.toJson())).toList()));

  void clearHistory() {
    history = [];
    _persistHistory();
    notifyListeners();
  }

  // ------------------------------------------------------------------ outbox

  void addFiles(Iterable<FileEntry> files) {
    outbox.addAll(files);
    notifyListeners();
  }

  void removeFile(FileEntry entry) {
    outbox.remove(entry);
    notifyListeners();
  }

  void clearOutbox() {
    outbox.clear();
    notifyListeners();
  }

  int get outboxBytes => outbox.fold(0, (a, f) => a + f.size);

  /// Sends the current outbox to [target] using [code].
  Future<TransferFailure?> sendOutbox(Device target, String code) async {
    if (outbox.isEmpty) return TransferFailure.noFilesSelected;
    lastError = null;
    final token = pairedTokens[target.id];
    try {
      await transfer.send(
          target: target, code: code, token: token, files: List.of(outbox));
      clearOutbox();
      return null;
    } on HyperDropException catch (e) {
      lastError = e.failure.message;
      notifyListeners();
      return e.failure;
    } catch (_) {
      lastError = TransferFailure.unknown.message;
      notifyListeners();
      return TransferFailure.unknown;
    }
  }

  void cancelTransfer() => transfer.cancel();

  @override
  void dispose() {
    discovery.dispose();
    transfer.dispose();
    super.dispose();
  }
}
