import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/data/auth_service.dart';

final vaultRepositoryProvider = Provider(
  (ref) => VaultRepository(ref.watch(supabaseProvider)),
);

class VaultItem {
  final String id;
  final String ownerId;
  final String content;
  final String? type;
  final DateTime createdAt;

  VaultItem({
    required this.id,
    required this.ownerId,
    required this.content,
    this.type,
    required this.createdAt,
  });

  factory VaultItem.fromJson(Map<String, dynamic> json) => VaultItem(
    id: json['id'],
    ownerId: json['owner_id'],
    content: json['content'],
    type: json['type'],
    createdAt: DateTime.parse(json['created_at']),
  );
}

class VaultRepository {
  final SupabaseClient _supabase;
  VaultRepository(this._supabase);

  Stream<List<VaultItem>> watchVaultItems(String ownerId) {
    return _supabase
        .from('vault_items')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => VaultItem.fromJson(json)).toList());
  }

  Future<void> addVaultItem(
    String ownerId,
    String content, {
    String type = 'text',
  }) async {
    await _supabase.from('vault_items').insert({
      'owner_id': ownerId,
      'content': content,
      'type': type,
    });
  }

  Future<void> deleteVaultItem(String id) async {
    await _supabase.from('vault_items').delete().eq('id', id);
  }
}
