enum MessageType { text, image, video, audio, file, nudge, mood }

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final String? mediaUrl;
  final int? durationMs;
  final bool isRead;
  final String? replyToId;
  final bool isForwarded;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.mediaUrl,
    this.durationMs,
    this.isRead = false,
    this.replyToId,
    this.isForwarded = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'content': content,
    'created_at': timestamp.toIso8601String(),
    'type': type.name,
    'media_url': mediaUrl,
    'duration_ms': durationMs,
    'is_read': isRead,
    'reply_to_id': replyToId,
    'is_forwarded': isForwarded,
  };

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'],
    senderId: json['sender_id'],
    receiverId: json['receiver_id'],
    content: json['content'],
    timestamp: DateTime.parse(json['created_at']),
    type: MessageType.values.byName(json['type'] ?? 'text'),
    mediaUrl: json['media_url'],
    durationMs: json['duration_ms'],
    isRead: json['is_read'] ?? false,
    replyToId: json['reply_to_id'],
    isForwarded: json['is_forwarded'] ?? false,
  );
}
