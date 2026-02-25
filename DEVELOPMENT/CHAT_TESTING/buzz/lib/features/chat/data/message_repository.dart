import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'message_model.dart';
import '../../auth/data/auth_service.dart';
import 'package:buzzy/core/database/local_database.dart';
import 'package:drift/drift.dart' as drift;

final messageRepositoryProvider = Provider(
  (ref) => MessageRepository(
    ref.watch(supabaseProvider),
    ref.watch(localDatabaseProvider),
  ),
);

final messagesStreamProvider =
    StreamProvider.family<
      List<MessageModel>,
      ({String userId, String partnerId})
    >((ref, arg) {
      return ref
          .watch(messageRepositoryProvider)
          .watchMessages(arg.userId, arg.partnerId);
    });

class MessageRepository {
  final SupabaseClient _supabase;
  final LocalDatabase _localDb;
  MessageRepository(this._supabase, this._localDb);

  // Sync Supabase messages to Local Drift
  Future<void> _syncToLocal(List<Map<String, dynamic>> data) async {
    final localMsgs = data.map((json) {
      final msg = MessageModel.fromJson(json);
      return LocalMessage(
        id: msg.id,
        senderId: msg.senderId,
        receiverId: msg.receiverId,
        content: msg.content,
        type: msg.type.name,
        mediaUrl: msg.mediaUrl,
        durationMs: msg.durationMs,
        isRead: msg.isRead,
        replyToId: msg.replyToId,
        isForwarded: msg.isForwarded,
        createdAt: msg.timestamp,
      );
    }).toList();
    await _localDb.saveMessages(localMsgs);
  }

  // Watch messages from local DB, while syncing from Supabase in background
  Stream<List<MessageModel>> watchMessages(String userId, String partnerId) {
    // Start background sync
    _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100)
        .listen((data) => _syncToLocal(data));

    return _localDb.watchMessages(userId, partnerId).map((locals) {
      return locals.map((l) {
        return MessageModel(
          id: l.id,
          senderId: l.senderId,
          receiverId: l.receiverId,
          content: l.content,
          timestamp: l.createdAt,
          type: MessageType.values.byName(l.type),
          mediaUrl: l.mediaUrl,
          durationMs: l.durationMs,
          isRead: l.isRead,
          replyToId: l.replyToId,
          isForwarded: l.isForwarded,
        );
      }).toList();
    });
  }

  Future<void> sendMessage(
    String content,
    String myId,
    String partnerId, {
    MessageType type = MessageType.text,
    String? mediaUrl,
    int? durationMs,
    String? replyToId,
    bool isForwarded = false,
  }) async {
    // OPTIONAL: Optimistically add to local DB
    // For now, let Supabase sync handle it back to local
    await _supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': partnerId,
      'content': content,
      'type': type.name,
      'media_url': mediaUrl,
      'duration_ms': durationMs,
      'reply_to_id': replyToId,
      'is_forwarded': isForwarded,
    });
  }

  Future<void> clearMessages(String userId, String partnerId) async {
    await _supabase
        .from('messages')
        .delete()
        .eq('sender_id', userId)
        .eq('receiver_id', partnerId);

    await _supabase
        .from('messages')
        .delete()
        .eq('sender_id', partnerId)
        .eq('receiver_id', userId);

    // Also clear locally
    await (_localDb.delete(_localDb.localMessages)..where(
          (t) =>
              (t.senderId.equals(userId) & t.receiverId.equals(partnerId)) |
              (t.senderId.equals(partnerId) & t.receiverId.equals(userId)),
        ))
        .go();
  }

  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('messages').delete().eq('id', messageId);
    await (_localDb.delete(
      _localDb.localMessages,
    )..where((t) => t.id.equals(messageId))).go();
  }

  Future<List<String>> getConversationUserIds(String userId) async {
    try {
      final sent = await _supabase
          .from('messages')
          .select('receiver_id')
          .eq('sender_id', userId);

      final received = await _supabase
          .from('messages')
          .select('sender_id')
          .eq('receiver_id', userId);

      final ids = {
        ...sent.map((m) => m['receiver_id'] as String),
        ...received.map((m) => m['sender_id'] as String),
      };
      return ids.toList();
    } catch (e) {
      // Offline: Get from local DB
      final locals =
          await (_localDb.select(_localDb.localMessages)..where(
                (t) => t.senderId.equals(userId) | t.receiverId.equals(userId),
              ))
              .get();
      final ids = <String>{
        ...locals.map((l) => l.senderId == userId ? l.receiverId : l.senderId),
      };
      return ids.toList();
    }
  }
}
