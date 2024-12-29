// lib/inventory_provider.dart

import 'package:flutter/material.dart';

class InventoryProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  /// Called when the server (or some other source) provides new inventory data
  void updateInventory(List<Map<String, dynamic>> updatedItems) {
    _items.clear();
    _items.addAll(updatedItems);
    _isLoading = false;
    notifyListeners();
  }

  bool isEquipped(String itemName) {
    return _items.any((item) =>
      item['name'] == itemName && item['is_equipped'] == true
    );
  }

  Map<String, String> get equippedItems {
    final Map<String, String> equipped = {};
    for (final item in _items) {
      if (item['is_equipped'] == true) {
        equipped[item['category']] = item['file_name'];
      }
    }
    return equipped;
  }

  /// Example toggling equip/unequip for an item
  void equipItem(String itemName, String fileName, String category) {
    final wasEquipped = isEquipped(itemName);

    // Update local state
    for (final item in _items) {
      if (item['name'] == itemName) {
        // Toggle
        item['is_equipped'] = !wasEquipped;
      } else if (item['category'] == category && !wasEquipped) {
        // If equipping a new item, unequip others in same category
        item['is_equipped'] = false;
      }
    }

    notifyListeners();


  }
}
