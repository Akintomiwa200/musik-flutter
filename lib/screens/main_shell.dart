import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_navigation_service.dart';
import '../widgets/persistent_bottom_chrome.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  Future<void> _openSettings(BuildContext context, int currentTab) async {
    final selected = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => SettingsScreen(currentTab: currentTab)),
    );
    if (selected != null && context.mounted) {
      context.read<AppNavigationService>().setTab(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<AppNavigationService>().tabIndex;

    final screens = [
      HomeScreen(onOpenSettings: () => _openSettings(context, tab)),
      const SearchScreen(),
      const LibraryScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: tab,
        children: screens,
      ),
      bottomNavigationBar: PersistentBottomChrome(
        selectedIndex: tab,
        onTabSelected: (i) => context.read<AppNavigationService>().setTab(i),
      ),
    );
  }
}
