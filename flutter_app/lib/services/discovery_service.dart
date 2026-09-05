import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models.dart';

/// LAN discovery over UDP broadcast.
///
/// Each peer broadcasts a small JSON beacon on [discoveryPort] every 2s and
/// listens for beacons from others. No internet access is required.
class DiscoveryService {
  DiscoveryService({
    required this.selfId,
    required this.selfName,
    required this.selfKind,
    required this.transferPort,
  });

  static const int discoveryPort = 45789;
  static const int protoVersion = 1;

  final String selfId;
  String selfName;
  final DeviceKind selfKind;
  int transferPort;

  RawDatagramSocket? _socket;
  Timer? _beaconTimer;
  bool _discoverable = true;

  final Map<String, Device> _peers = {};
  final _controller = StreamController<List<Device>>.broadcast();

  Stream<List<Device>> get peers => _controller.stream;
  List<Device> get currentPeers => _peers.values.toList();

  /// The six-digit pairing code currently advertised, if any.
  String? advertisedCode;

  Future<void> start() async {
    if (_socket != null) return;
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort,
        reuseAddress: true, reusePort: false);
    _socket!.broadcastEnabled = true;
    _socket!.listen(_onEvent);
    _beaconTimer = Timer.periodic(const Duration(seconds: 2), (_) => _broadcast());
    _broadcast();
  }

  Future<void> stop() async {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    _socket?.close();
    _socket = null;
  }

  set discoverable(bool value) {
    _discoverable = value;
    if (value) _broadcast();
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _socket?.receive();
    if (dg == null) return;
    try {
      final json = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
      if (json['proto'] != protoVersion) return;
      final id = json['id'] as String;
      if (id == selfId) return;

      final device = Device(
        id: id,
        name: json['name'] as String? ?? 'Unknown device',
        kind: kindFromName(json['kind'] as String? ?? 'androidPhone'),
        address: dg.address.address,
        port: (json['port'] as num?)?.toInt() ?? 0,
        lastSeen: DateTime.now(),
      );
      final isNew = !_peers.containsKey(id);
      _peers[id] = device;
      _prune();
      _controller.add(currentPeers);
      // Answer directly. On a phone hotspot, broadcast traffic is often only
      // seen in one direction, so a unicast reply makes discovery mutual:
      // whoever created the hotspot and whoever joined it both show up.
      if (isNew || !json.containsKey('reply')) {
        _sendTo(dg.address, reply: true);
      }
    } catch (_) {
      // Malformed beacons are ignored by design.
    }
  }

  void _prune() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 10));
    _peers.removeWhere((_, d) => d.lastSeen != null && d.lastSeen!.isBefore(cutoff));
  }

  List<int> _payload({bool reply = false}) => utf8.encode(jsonEncode({
        'proto': protoVersion,
        'id': selfId,
        'name': selfName,
        'kind': selfKind.name,
        'port': transferPort,
        'code': advertisedCode,
        if (reply) 'reply': true,
      }));

  void _sendTo(InternetAddress address, {bool reply = false}) {
    final socket = _socket;
    if (socket == null || !_discoverable) return;
    try {
      socket.send(_payload(reply: reply), address, discoveryPort);
    } catch (_) {
      // Interfaces change while Wi-Fi/hotspot toggles; ignore transient errors.
    }
  }

  /// Directed broadcast addresses for every active IPv4 interface (a hotspot
  /// interface frequently ignores the global 255.255.255.255 address).
  Future<void> _refreshTargets() async {
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLoopback: false);
      final targets = <String>{};
      for (final i in interfaces) {
        for (final a in i.addresses) {
          final parts = a.address.split('.');
          if (parts.length == 4) targets.add('${parts[0]}.${parts[1]}.${parts[2]}.255');
        }
      }
      _targets = targets.toList();
    } catch (_) {
      _targets = const [];
    }
  }

  List<String> _targets = const [];

  void _broadcast() {
    final socket = _socket;
    if (socket == null || !_discoverable) return;
    _sendTo(InternetAddress('255.255.255.255'));
    for (final t in _targets) {
      _sendTo(InternetAddress(t));
    }
    // Keep talking to peers we already know, even if broadcast stops working.
    for (final d in _peers.values) {
      if (d.address.isNotEmpty) _sendTo(InternetAddress(d.address));
    }
    _refreshTargets();
    _prune();
    _controller.add(currentPeers);
  }



  /// Finds a peer currently advertising [code]. Returns null when not found.
  Device? peerForCode(String code) {
    for (final d in _peers.values) {
      if (_codesSeen[d.id] == code) return d;
    }
    return null;
  }

  final Map<String, String> _codesSeen = {};

  void recordCode(String deviceId, String? code) {
    if (code == null) {
      _codesSeen.remove(deviceId);
    } else {
      _codesSeen[deviceId] = code;
    }
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
