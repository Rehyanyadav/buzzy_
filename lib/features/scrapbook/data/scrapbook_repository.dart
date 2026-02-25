import 'package:image_picker/image_picker.dart' show XFile;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/data/auth_service.dart';
import 'package:buzzy/core/database/local_database.dart';

final scrapbookRepositoryProvider = Provider(
  (ref) => ScrapbookRepository(
    ref.watch(supabaseProvider),
    ref.watch(localDatabaseProvider),
  ),
);

class ScrapbookItem {
  final String id;
  final String uploaderId;
  final String coupleId;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;

  ScrapbookItem({
    required this.id,
    required this.uploaderId,
    required this.coupleId,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
  });

  factory ScrapbookItem.fromJson(Map<String, dynamic> json) => ScrapbookItem(
    id: json['id'],
    uploaderId: json['uploader_id'],
    coupleId: json['couple_id'],
    imageUrl: json['image_url'],
    caption: json['caption'],
    createdAt: DateTime.parse(json['created_at']),
  );
}

class ScrapbookRepository {
  final SupabaseClient _supabase;
  final LocalDatabase _localDb;
  ScrapbookRepository(this._supabase, this._localDb);

  Future<void> _syncToLocal(List<Map<String, dynamic>> data) async {
    final localItems = data.map((json) {
      final item = ScrapbookItem.fromJson(json);
      return LocalScrapbookItem(
        id: item.id,
        uploaderId: item.uploaderId,
        coupleId: item.coupleId,
        imageUrl: item.imageUrl,
        caption: item.caption,
        createdAt: item.createdAt,
      );
    }).toList();
    await _localDb.saveScrapbookItems(localItems);
  }

  Stream<List<ScrapbookItem>> watchItems(String coupleKey) {
    _supabase
        .from('scrapbook_items')
        .stream(primaryKey: ['id'])
        .eq('couple_id', coupleKey)
        .order('created_at', ascending: false)
        .listen((data) => _syncToLocal(data));

    return _localDb.watchScrapbookItems(coupleKey).map((locals) {
      return locals.map((l) {
        return ScrapbookItem(
          id: l.id,
          uploaderId: l.uploaderId,
          coupleId: l.coupleId,
          imageUrl: l.imageUrl,
          caption: l.caption,
          createdAt: l.createdAt,
        );
      }).toList();
    });
  }

  Future<void> addItem({
    required String uploaderId,
    required String coupleId,
    required XFile imageFile,
    String? caption,
  }) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$uploaderId.jpg';
      final path = 'shared/$fileName';

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await _supabase.storage.from('scrapbook').uploadBinary(path, bytes);
      } else {
        await _supabase.storage
            .from('scrapbook')
            .upload(path, File(imageFile.path));
      }

      final imageUrl = _supabase.storage.from('scrapbook').getPublicUrl(path);

      await _supabase.from('scrapbook_items').insert({
        'uploader_id': uploaderId,
        'couple_id': coupleId,
        'image_url': imageUrl,
        'caption': caption,
      });
    } catch (e) {
      rethrow;
    }
  }
}
