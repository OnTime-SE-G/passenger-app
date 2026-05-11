import 'package:flutter/foundation.dart';

/// Singleton tab controller — any widget can call [jumpTo] to switch tabs
/// without needing a BuildContext or passing callbacks through the tree.
///
/// Usage:
///   AppTabController.instance.jumpTo(5); // → Settings tab
class AppTabController extends ChangeNotifier {
  AppTabController._();
  static final AppTabController instance = AppTabController._();

  int _index = 0;
  int get index => _index;

  void jumpTo(int i) {
    if (_index == i) return;
    _index = i;
    notifyListeners();
  }
}
