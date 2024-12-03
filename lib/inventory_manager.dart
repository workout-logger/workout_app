class InventoryManager {
  static final InventoryManager _instance = InventoryManager._internal();
  factory InventoryManager() => _instance;
  InventoryManager._internal();

  List<Map<String, dynamic>> inventoryItems = [];
  String? equippedItem;

  void updateInventory(List<Map<String, dynamic>> items) {
    inventoryItems = items;
  }

  void equipItem(String itemName) {
    equippedItem = itemName;
  }

  bool isEquipped(String itemName) {
    return equippedItem == itemName;
  }
}
