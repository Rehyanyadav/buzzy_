import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'dart:html';
import 'dart:typed_data';

final storageServiceProvider = Provider(
  (ref) => StorageService(ref.watch(supabaseProvider)),
);

class StorageService {
  final SupabaseClient _supabase;
  StorageService(this._supabase);

  Future<String?> uploadMedia({
    required String bucket,
    required String filePath,
    required String fileName,
    Uint8List? fileBytes,
  }) async {
    try {
      final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      if (kIsWeb) {
        if (fileBytes != null) {
          await _supabase.storage.from(bucket).uploadBinary(path, fileBytes);
        } else {
          // If no bytes, we can't do much on web with just a path
          throw Exception('Web upload requires bytes');
        }
      } else {
        final file = File(filePath);
        await _supabase.storage.from(bucket).upload(path, file);
      }

      final url = _supabase.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadProfileImage(String userId, String filePath) async {
    return uploadMedia(
      bucket: 'avatars',
      filePath: filePath,
      fileName: 'avatar_$userId.jpg',
    );
  }

  Future<String?> uploadChatMedia(String filePath, String fileName) async {
    return uploadMedia(
      bucket: 'chat_media',
      filePath: filePath,
      fileName: fileName,
    );
  }
}
