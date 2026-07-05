import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_navigation_service.dart';
import '../widgets/persistent_bottom_chrome.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'queue_screen.dart';
import 'recents_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  Future<void> _openSettings(BuildContext context, int currentTab) async {
    final selected = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => SettingsScreen(currentTab: currentTab)),
    );
    if (selected != null && context.mounted) {
      context.read<AppNavigationService>().setTabIndex(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<AppNavigationService>().tabIndex;
    final screens = <Widget>[
      HomeScreen(onOpenSettings: () => _openSettings(context, tab)),
      const SearchScreen(),
      const RecentsScreen(),
      const QueueScreen(sourceLabel: 'Queue', isTab: true),
      const ProfileScreen(isTab: true),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: tab,
        children: screens,
      ),
      bottomNavigationBar: PersistentBottomChrome(
        selectedIndex: tab,
        onTabSelected: (i) =>
            context.read<AppNavigationService>().setTabIndex(i),
      ),
    );
  }
}
