import 'package:flutter/foundation.dart';

import 'dummy_address.dart';

/// Lightweight global store to keep the user's currently selected address
/// without modifying the const dummy list.
class AddressStore extends ChangeNotifier {
  AddressStore._();
  static final AddressStore instance = AddressStore._();

  DummyAddress? _selected;

  /// Returns the selected address if any, otherwise the default from dummy data.
  DummyAddress get selected {
    if (_selected != null) return _selected!;
    try {
      return dummyAddresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return dummyAddresses.first;
    }
  }

  void select(DummyAddress a) {
    _selected = a;
    notifyListeners();
  }
}
