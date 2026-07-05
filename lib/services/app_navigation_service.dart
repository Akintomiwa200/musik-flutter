import 'package:flutter/foundation.dart';

enum AppTab { home, search, recents, queue, profile }

/// Coordinates main-tab navigation and cross-tab actions (search, etc.).
class AppNavigationService extends ChangeNotifier {
  AppTab _tab = AppTab.home;
  String? _pendingSearch;

  AppTab get tab => _tab;
  int get tabIndex => AppTab.values.indexOf(_tab);

  void setTab(AppTab tab) {
    if (_tab == tab && _pendingSearch == null) return;
    _tab = tab;
    notifyListeners();
  }

  void setTabIndex(int index) {
    final t = AppTab.values[index];
    setTab(t);
  }

  void openSearchTab([String? query]) {
    _pendingSearch = query;
    _tab = AppTab.search;
    notifyListeners();
  }

  String? consumePendingSearch() {
    final q = _pendingSearch;
    _pendingSearch = null;
    return q;
  }
}
