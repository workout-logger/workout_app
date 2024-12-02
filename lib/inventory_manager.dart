class InventoryManager {
  static final InventoryManager _instance = InventoryManager._internal();
  factory InventoryManager() => _instance;

  InventoryManager._internal();

  List<Map<String, dynamic>> inventoryItems = [];

  void updateInventory(List<Map<String, dynamic>> newItems) {
    inventoryItems = newItems;
  }
}
