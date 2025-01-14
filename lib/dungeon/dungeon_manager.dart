// lib/dungeon_manager.dart

import 'dart:async';

import 'package:workout_logger/websocket_manager.dart';

class DungeonManager {
  // Singleton pattern
  static final DungeonManager _instance = DungeonManager._internal();
  factory DungeonManager() => _instance;
  DungeonManager._internal();

  /// Indicates if a dungeon is currently running for this user.
  bool isDungeonRunning = false;

  int currentHealth = 100;

  int maxHealth = 100;

  /// Whether we're in the process of loading/fetching data (e.g., show overlay).
  bool isLoading = false;

  /// Whether we've at least loaded some data from the server once.
  bool isLoaded = false;
  bool deathScreen = false;

  /// Dungeon items the user currently sees (e.g., items in the dungeon).
  List<Map<String, dynamic>> dungeonItems = [];

  /// Current dialogue text from NPC events.
  String dungeonDialogue = "";

  List<Map<String, dynamic>> dungeonLogs = [];

  List<String> dialogueOptions = [];

  /// (Optional) Store a reference to equipped items or other data.
  Map<String, dynamic> equippedItems = {};

  /// Callback to notify the UI whenever data changes.
  Function(dynamic)? _dungeonUpdateCallback;

  Completer<bool>? _dungeonStatusCompleter;


  // -------------------------------------------------------------------
  // UI Registration (the UI calls this to listen for updates)
  // -------------------------------------------------------------------
  void setDungeonUpdateCallback(Function(dynamic) callback) {
    _dungeonUpdateCallback = callback;
  }

  /// Internal helper to notify UI
  void _notifyUI(dynamic data) {
    if (_dungeonUpdateCallback != null) {
      _dungeonUpdateCallback!(data);
    }
  }


  void updateHealth(int newHealth) {
    currentHealth = newHealth.clamp(0, maxHealth); // Ensure health is within bounds
    _notifyUI({"type": "health_updated"});
  }

  void onHealthUpdate(Map<String, dynamic> data) {
    if (data.containsKey('current_health')) {
      currentHealth = data['current_health'];
      _notifyUI({"type": "health_updated"});
    }
  }
  // -------------------------------------------------------------------
  // Fetch Dungeon Data from the Server
  // -------------------------------------------------------------------
  /// Sends an action to fetch all dungeon data (items, NPC event, etc.)
  /// The server should respond with {"type":"dungeon_data","data":{...}}
  Future<void> requestDungeonData({bool showLoadingOverlay = true}) async {
    if (showLoadingOverlay) {
      isLoading = true;
      _notifyUI(null); // Let UI show a spinner
    }

    // Actually send an action to the server
    await WebSocketManager().sendMessage({
      "action": "fetch_dungeon_data",
    });

    // The onDungeonData method will be called when "dungeon_data" arrives.
    // Optionally, you could add a timeout fallback if you want.
  }


  /// Called by WebSocketManager when we receive {"type":"dungeon_data","data":...}
  void onDungeonData(Map<String, dynamic> message) {
    final data = message['data'];
    if (data is Map<String, dynamic>) {
      // Example structure from server:
      // {
      //   "items": [...],
      //   "npc_event": {...},
      //   "paused": bool,
      //   "start_time": "2023-01-01T00:00:00Z",
      //   "end_time": "2023-01-01T01:00:00Z", // Optional end time
      //   "message": "Dungeon data fetched."
      // }
      if (data.containsKey('current_health')) {
        onHealthUpdate(data);
      }

      // Check for end time
      final hasEndTime = data.containsKey('end_time');
      if (hasEndTime) {
        isDungeonRunning = true;
      }
      print(data['death']);
      if (data['death'] == true) {
        deathScreen = true;
      }else{
        deathScreen = false;
      }

      // Extract items
      if (data['items'] is List) {
        dungeonItems = (data['items'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      } else {
        dungeonItems = [];
      }

      if (data['logs'] is List) {
        dungeonLogs = (data['logs'] as List)
            .map((logEntry) => logEntry as Map<String, dynamic>)
            .toList();
      }
      
      // If there's an npc_event, parse out the dialogue + choices
      final npcEvent = data['npc_event'] ?? {};
      if (npcEvent is Map<String, dynamic>) {
        final eventData = npcEvent['event'] ?? {};
        final dialogue = eventData['dialogue'] ?? "";
        final choices = eventData['choices'] ?? [];

        dungeonDialogue = dialogue is String ? dialogue : "";
        dialogueOptions = [];
        if (choices is List) {
          for (var c in choices) {
            final choiceText = c['choice_text'] ?? "Unknown choice";
            dialogueOptions.add(choiceText);
          }
        }
      }
    }

    // Mark data as loaded, stop loading overlay
    isLoaded = true;
    isLoading = false;
    _notifyUI({"type": "dungeon_data_fetched"});
  }

  // -------------------------------------------------------------------
  // Dungeon Lifecycle (Start/Stop)
  // -------------------------------------------------------------------
  /// Instructs the server to start a dungeon session
  Future<void> startDungeon() async {
    await WebSocketManager().sendMessage({
      "action": "start_dungeon",
    });
  }

  /// Instructs the server to stop the current dungeon session
  Future<void> stopDungeon() async {
    await WebSocketManager().sendMessage({
      "action": "stop_dungeon",
    });
  }

  // Called by WebSocketManager when the server replies:
  // {"type":"dungeon_started","message":"Dungeon run started."}
  void onDungeonStarted(Map<String, dynamic> message) {
    isDungeonRunning = true;
    final msg = message['message'] ?? "Dungeon started";
    print("onDungeonStarted: $msg");
    _notifyUI({"type": "dungeon_started", "message": msg});
  }

  // Called by WebSocketManager when the server replies:
  // {"type":"dungeon_stopped","message":"Dungeon run stopped."}
  void onDungeonStopped(Map<String, dynamic> message) {
    isDungeonRunning = false;
    final msg = message['message'] ?? "Dungeon stopped";
    print("onDungeonStopped: $msg");
    _notifyUI({"type": "dungeon_stopped", "message": msg});
  }

  // -------------------------------------------------------------------
  // NPC Events and Choices
  // -------------------------------------------------------------------
  /// Sends a choice index to the server: {"action":"handle_dungeon_choice","choice_index": ...}
  Future<void> makeChoice(int choiceIndex) async {
    await WebSocketManager().sendMessage({
      "action": "handle_dungeon_choice",
      "choice_index": choiceIndex,
    });
  }

  // Called by WebSocketManager for {"type":"dungeon_event","npc":...,"event":...}
  void onDungeonEvent(Map<String, dynamic> message) {
    // e.g. "event":{"dialogue":"...","choices":[...]}
    final eventData = message['event'] ?? {};
    final dialogue = eventData['dialogue'] ?? "";
    final choices = eventData['choices'] ?? [];
    dungeonDialogue = dialogue is String ? dialogue : "";
    dialogueOptions = [];
    if (choices is List) {
      for (var c in choices) {
        final choiceText = c['choice_text'] ?? "";
        dialogueOptions.add(choiceText);
      }
    }
    print("onDungeonEvent: $dungeonDialogue");
    _notifyUI({"type": "dungeon_event"});
  }

  // Called by WebSocketManager for {"type":"choice_feedback","consequence_text":"..."}
  void onChoiceFeedback(Map<String, dynamic> message) {
    final consequenceText = message['consequence_text'] ?? "";
    dungeonDialogue = consequenceText;
    dialogueOptions = []; // Clear choices
    print("onChoiceFeedback: $consequenceText");
    _notifyUI({"type": "choice_feedback"});
  }

  // -------------------------------------------------------------------
  // Dungeon Rewards (Offline or Periodic Items)
  // -------------------------------------------------------------------
  // Called by WebSocketManager for {"type":"dungeon_reward","data":{...}}
  void onDungeonReward(Map<String, dynamic> message) {
    final data = message['data'];
    print(data);
    if (data is Map<String, dynamic>) {
      dungeonItems.add(data);
      print(data);
      print("onDungeonReward: Received item ${data['name']}");
      _notifyUI({"type": "dungeon_reward", "item": data});
    }
  }



}
