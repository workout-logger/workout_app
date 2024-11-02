class User {
  final String id;
  final String name;
  final String avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });
}

class Message {
  final User sender;
  final String content;
  final DateTime timestamp;

  Message({
    required this.sender,
    required this.content,
    required this.timestamp,
  });
}

class Item {
  final String id;
  final String name;
  final String imageUrl;

  Item({
    required this.id,
    required this.name,
    required this.imageUrl,
  });
}
