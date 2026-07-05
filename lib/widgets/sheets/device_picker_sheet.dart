import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_routes.dart';
import '../../services/device_service.dart';
import '../../theme/app_theme.dart';

Future<void> showDevicePickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF282828),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => const _DevicePickerBody(),
  );
}

class _DevicePickerBody extends StatelessWidget {
  const _DevicePickerBody();

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'computer':
        return Icons.computer;
      case 'phone':
        return Icons.smartphone;
      case 'tv':
        return Icons.tv;
      case 'laptop':
        return Icons.laptop_mac;
      default:
        return Icons.speaker_group;
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceService>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Listening on',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surfaceHighlight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.graphic_eq, color: AppColors.musikAccent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      devices.activeDevice.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.check, color: AppColors.musikAccent),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Available outputs', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh outputs',
                  onPressed: devices.refreshDevices,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final device in devices.devices)
              if (device.id != devices.activeDeviceId)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_iconFor(device.icon), color: Colors.white),
                  title: Text(device.name),
                  onTap: () {
                    devices.selectDevice(device.id);
                    Navigator.pop(context);
                  },
                ),
            if (devices.devices.length == 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No external audio outputs are exposed by this device right now.',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
              ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF3E3E3E)),
            const SizedBox(height: 12),
            const Text(
              'Group Session (BETA)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Listen together with friends, wherever they are.',
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.musikAccent,
                  foregroundColor: Colors.black,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Start Session'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                AppRoutes.scanner(context);
              },
              child: Text('Scan to join', style: TextStyle(color: context.textSecondary)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.volume_down, color: Colors.white.withValues(alpha: 0.7)),
                Expanded(
                  child: Slider(
                    value: devices.volume,
                    onChanged: devices.setVolume,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                  ),
                ),
                Icon(Icons.volume_up, color: Colors.white.withValues(alpha: 0.7)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


