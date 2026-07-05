import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class AudioDevice {
  final String id;
  final String name;
  final String icon;

  const AudioDevice({required this.id, required this.name, required this.icon});
}

class DeviceService extends ChangeNotifier {
  late final AudioDevice _localDevice = _buildLocalDevice();
  double _volume = 0.72;

  List<AudioDevice> get devices => [_localDevice];
  String get activeDeviceId => _localDevice.id;
  double get volume => _volume;

  AudioDevice get activeDevice => _localDevice;
  String get activeDeviceLabel => activeDevice.name;

  AudioDevice _buildLocalDevice() {
    final platform = kIsWeb
        ? 'Web player'
        : Platform.isAndroid
            ? 'Android device'
            : Platform.isWindows
                ? 'Windows PC'
                : Platform.isIOS
                    ? 'iPhone'
                    : Platform.operatingSystem;

    String host = '';
    if (!kIsWeb) {
      try {
        host = Platform.localHostname.trim();
      } catch (_) {
        host = '';
      }
    }

    return AudioDevice(
      id: 'local-output',
      name: host.isEmpty ? platform : host,
      icon: kIsWeb || Platform.isAndroid || Platform.isIOS ? 'phone' : 'computer',
    );
  }

  void refreshDevices() {
    notifyListeners();
  }

  void selectDevice(String id) {
    notifyListeners();
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    notifyListeners();
  }
}
