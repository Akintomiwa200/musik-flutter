import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/app_routes.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/persistent_bottom_chrome.dart';
import '../widgets/sheets/device_picker_sheet.dart';

class SettingsScreen extends StatelessWidget {
  final int currentTab;

  const SettingsScreen({super.key, this.currentTab = 0});

  static const _items = ['Account', 'Devices', 'Storage'];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    final displayName = user?.name ?? 'Musik User';

    return ChromeScaffold(
      selectedTab: currentTab,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text('Settings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            subtitle: const Text('View profile', style: TextStyle(color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () => AppRoutes.profile(context),
          ),
          Divider(color: AppColors.surfaceHighlight, height: 1),
          for (final label in _items)
            ListTile(
              title: Text(label, style: const TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
              onTap: () => _onItemTap(context, label),
            ),
        ],
      ),
    );
  }

  void _onItemTap(BuildContext context, String label) {
    switch (label) {
      case 'Account':
        AppRoutes.account(context);
        break;
      case 'Devices':
        showDevicePickerSheet(context);
        break;
      case 'Storage':
        AppRoutes.storage(context);
        break;
    }
  }
}
