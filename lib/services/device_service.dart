import 'package:flutter/foundation.dart';

class AudioDevice {
  final String id;
  final String name;
  final String icon;

  const AudioDevice({required this.id, required this.name, required this.icon});
}

class DeviceService extends ChangeNotifier {
  static const devices = [
    AudioDevice(id: 'beatspill', name: 'BeatsPill+', icon: 'speaker'),
    AudioDevice(id: 'bravia', name: 'BRAVIA 4K GB', icon: 'tv'),
    AudioDevice(id: 'macbook', name: "Momitha's MacBook Pro", icon: 'laptop'),
  ];

  String _activeDeviceId = 'beatspill';
  double _volume = 0.72;

  String get activeDeviceId => _activeDeviceId;
  double get volume => _volume;

  AudioDevice get activeDevice =>
      devices.firstWhere((d) => d.id == _activeDeviceId, orElse: () => devices.first);

  String get activeDeviceLabel => activeDevice.name;

  void selectDevice(String id) {
    _activeDeviceId = id;
    notifyListeners();
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    notifyListeners();
  }
}
