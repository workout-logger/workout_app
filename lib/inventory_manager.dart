import 'websocket_manager.dart';

class InventoryManager {
  static final InventoryManager _instance = InventoryManager._internal();

  InventoryManager._internal();

  factory InventoryManager() => _instance;

  final List<Map<String, dynamic>> _inventoryItems = [];

  bool isLoading = true; // Loading state variable

  List<Map<String, dynamic>> get inventoryItems => List.unmodifiable(_inventoryItems);

  bool isEquipped(String itemName) {
    return _inventoryItems.any((item) => item['name'] == itemName && item['is_equipped'] == true);
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
  }

  void updateInventory(List<Map<String, dynamic>> updatedItems) {
    _inventoryItems
      ..clear()
      ..addAll(updatedItems);
    if (isLoading) {
      isLoading = false; // Set loading to false when data is received
    }
  }

  void requestInventoryUpdate({bool showLoadingOverlay = true}) {
    // Set isLoading to true only if showLoadingOverlay is true
    if (showLoadingOverlay) {
      isLoading = true;
    }

    // Use WebSocketManager to send the update request
    WebSocketManager().sendMessage({
      "action": "fetch_inventory_data",
    });
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
}
