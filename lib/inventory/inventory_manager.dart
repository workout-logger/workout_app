import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../websocket_manager.dart';

class InventoryManager extends ChangeNotifier {
  // Singleton implementation
  static final InventoryManager _instance = InventoryManager._internal();
  InventoryManager._internal();
  factory InventoryManager() => _instance;

  VoidCallback? onEquipmentChanged;
  final List<Map<String, dynamic>> _inventoryItems = [];
  String? bodyColor; // Store body color
  String? eyeColor;  // Store eye color
  Map<String, dynamic>? _stats = {};
  bool isLoading = true; // Loading state variable

  List<Map<String, dynamic>> get inventoryItems => List.unmodifiable(_inventoryItems);
  Map<String, dynamic>? get stats => _stats;


  bool isEquipped(String itemName) {
    return _inventoryItems.any((item) => item['name'] == itemName && item['is_equipped'] == true);
  }

  void updateStats(Map<String, dynamic> statsData) {
    _stats = statsData;
    notifyListeners();
  }


  void equipItem(String itemName, String fileName, String category) {
    final isItemEquipped = isEquipped(itemName);
    final action = isItemEquipped ? "unequip_item" : "equip_item";

    // Send WebSocket message
    WebSocketManager().sendMessage({
      "action": action,
      "item_name": fileName,
      "category": category,
    });

    // Update local inventory state
    for (var item in _inventoryItems) {
      if (item['name'] == itemName) {
        item['is_equipped'] = !isItemEquipped; // Toggle equipped state
      } else if (item['category'] == category && !isItemEquipped) {
        // Unequip other items in the same category if equipping a new one
        item['is_equipped'] = false;
      }
    }
    onEquipmentChanged?.call();
    notifyListeners();
  }

  void updateInventory(List<Map<String, dynamic>> updatedItems) {
    _inventoryItems
      ..clear()
      ..addAll(updatedItems);
    if (isLoading) {
      isLoading = false; // Set loading to false when data is received
    }
    notifyListeners();
  }



  Map<String, String> get equippedItems {
    Map<String, String> equipped = {};
    for (var item in _inventoryItems) {
      if (item['is_equipped'] == true) {
        equipped[item['category']] = item['file_name'];
      }
    }
    return equipped;
  }
  Future<void>  requestInventoryUpdate({bool showLoadingOverlay = true}) async {
    // Set isLoading to true only if showLoadingOverlay is true
    if (showLoadingOverlay) {
      isLoading = true;
    }

    // Use WebSocketManager to send the update request
    WebSocketManager().sendMessage({
      "action": "fetch_inventory_data",
    });
    
  }

  Future<void> requestCharacterColors() async {
    // Send a WebSocket message to fetch character colors
    WebSocketManager().sendMessage({
      "action": "fetch_character_colors",
    });
    notifyListeners();
  }

  void updateCharacterColors(Map<String, String?> colorsData) async {
    bodyColor = colorsData['body_color'];
    eyeColor = colorsData['eye_color'];

    // Also store them locally for next time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bodyColorIndex', bodyColor ?? '');
    await prefs.setString('eyeColorIndex', eyeColor ?? '');

    notifyListeners();
  }

  bool get hasCharacterData => bodyColor != null && eyeColor != null;
}


