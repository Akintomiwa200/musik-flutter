import 'package:flutter/foundation.dart';

/// Coordinates main-tab navigation and cross-tab actions (search, etc.).
class AppNavigationService extends ChangeNotifier {
  int _tabIndex = 0;
  String? _pendingSearch;

  int get tabIndex => _tabIndex;

  void setTab(int index) {
    if (_tabIndex == index && _pendingSearch == null) return;
    _tabIndex = index;
    notifyListeners();
  }

  void openSearchTab([String? query]) {
    _pendingSearch = query;
    _tabIndex = 1;
    notifyListeners();
  }

  String? consumePendingSearch() {
    final q = _pendingSearch;
    _pendingSearch = null;
    return q;
  }
}
