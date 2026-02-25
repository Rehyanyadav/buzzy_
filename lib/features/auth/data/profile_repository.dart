import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'package:buzzy/core/database/local_database.dart';

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(
    ref.watch(supabaseProvider),
    ref.watch(localDatabaseProvider),
  ),
);

final profileProvider = StreamProvider.autoDispose((ref) {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(profileRepositoryProvider).watchProfile(user.id);
});

class ProfileModel {
  final String id;
  final String? displayName;
  final String? email;
  final String? bio;
  final String? partnerId;
  final String moodEmoji;
  final String? isTypingIn;
  final DateTime? lastSeen;
  final List<String> blockedIds;

  ProfileModel({
    required this.id,
    this.displayName,
    this.email,
    this.bio,
    this.partnerId,
    required this.moodEmoji,
    this.isTypingIn,
    this.lastSeen,
    this.blockedIds = const [],
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'],
    displayName: json['display_name'],
    email: json['email'],
    bio: json['bio'],
    partnerId: json['partner_id'],
    moodEmoji: json['mood_emoji'] ?? '🤍',
    isTypingIn: json['is_typing_in'],
    lastSeen: json['last_seen'] != null
        ? DateTime.parse(json['last_seen'])
        : null,
    blockedIds: json['blocked_ids'] != null
        ? List<String>.from(json['blocked_ids'])
        : const [],
  );
}

class ProfileRepository {
  final SupabaseClient _supabase;
  final LocalDatabase _localDb;
  ProfileRepository(this._supabase, this._localDb);

  Future<void> _syncToLocal(Map<String, dynamic> json) async {
    final model = ProfileModel.fromJson(json);
    await _localDb.saveProfile(
      LocalProfile(
        id: model.id,
        email: model.email,
        displayName: model.displayName,
        bio: model.bio,
        partnerId: model.partnerId,
        moodEmoji: model.moodEmoji,
        lastSeen: model.lastSeen,
        blockedIds: model.blockedIds,
      ),
    );
  }

  Future<ProfileModel?> getProfile(String id) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data != null) {
        await _syncToLocal(data);
        return ProfileModel.fromJson(data);
      }
    } catch (e) {
      // Offline: handled by watchProfile typically, but if direct call:
      final local = await _localDb.watchProfile(id).first;
      if (local != null) {
        return ProfileModel(
          id: local.id,
          displayName: local.displayName,
          email: local.email,
          bio: local.bio,
          partnerId: local.partnerId,
          moodEmoji: local.moodEmoji,
          lastSeen: local.lastSeen,
          blockedIds: local.blockedIds,
        );
      }
    }
    return null;
  }

  Stream<ProfileModel> watchProfile(String id) async* {
    // Sync from Supabase in background
    _supabase.from('profiles').stream(primaryKey: ['id']).eq('id', id).listen((
      data,
    ) {
      if (data.isNotEmpty) _syncToLocal(data.first);
    });

    yield* _localDb.watchProfile(id).map((l) {
      if (l == null) return ProfileModel(id: id, moodEmoji: '🤍');
      return ProfileModel(
        id: l.id,
        displayName: l.displayName,
        email: l.email,
        bio: l.bio,
        partnerId: l.partnerId,
        moodEmoji: l.moodEmoji,
        lastSeen: l.lastSeen,
        blockedIds: l.blockedIds,
      );
    });
  }

  Future<void> ensureProfileExists(String id, String email) async {
    final existing = await getProfile(id);
    if (existing == null) {
      await _supabase.from('profiles').insert({
        'id': id,
        'email': email,
        'display_name': email.split('@').first,
      });
    }
  }

  Future<void> linkPartnerByEmail(String myId, String partnerEmail) async {
    final sanitizedEmail = partnerEmail.trim().toLowerCase();
    final partnerData = await _supabase
        .from('profiles')
        .select()
        .ilike('email', sanitizedEmail)
        .maybeSingle();

    if (partnerData == null) {
      throw 'Partner email not found. Make sure they have signed up first!';
    }

    final partnerId = partnerData['id'];

    await _supabase
        .from('profiles')
        .update({'partner_id': partnerId})
        .eq('id', myId);
  }

  Future<void> updateMood(String id, String emoji) async {
    await _supabase
        .from('profiles')
        .update({
          'mood_emoji': emoji,
          'mood_updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> updateProfile({
    required String id,
    String? displayName,
    String? bio,
  }) async {
    final updates = {
      if (displayName != null) 'display_name': displayName,
      if (bio != null) 'bio': bio,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _supabase.from('profiles').update(updates).eq('id', id);
  }

  Future<void> setTypingStatus(String myId, String? targetId) async {
    await _supabase
        .from('profiles')
        .update({'is_typing_in': targetId})
        .eq('id', myId);
  }

  Future<void> updateLastSeen(String id) async {
    await _supabase
        .from('profiles')
        .update({'last_seen': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> toggleBlockUser(
    String myId,
    String partnerId,
    bool block,
  ) async {
    final profile = await getProfile(myId);
    if (profile == null) return;

    final blockedIds = List<String>.from(profile.blockedIds);
    if (block) {
      if (!blockedIds.contains(partnerId)) blockedIds.add(partnerId);
    } else {
      blockedIds.remove(partnerId);
    }

    await _supabase
        .from('profiles')
        .update({'blocked_ids': blockedIds})
        .eq('id', myId);
  }

  Future<List<ProfileModel>> searchUsers(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final response = await _supabase
        .from('profiles')
        .select()
        .or('email.ilike.%$cleanQuery%,display_name.ilike.%$cleanQuery%')
        .limit(20);

    return (response as List)
        .map((json) => ProfileModel.fromJson(json))
        .toList();
  }
}
