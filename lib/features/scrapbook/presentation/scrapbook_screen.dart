import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/scrapbook_repository.dart';
import '../../auth/data/profile_repository.dart';
import '../../auth/data/auth_service.dart';

class ScrapbookScreen extends ConsumerWidget {
  const ScrapbookScreen({super.key});

  Future<void> _pickAndUploadImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (!context.mounted) return;
      final caption = await _showCaptionDialog(context);
      if (caption == null) return; // User cancelled

      final user = ref.read(authServiceProvider).currentUser;
      final profile = await ref
          .read(profileRepositoryProvider)
          .getProfile(user!.id);

      if (profile?.partnerId != null) {
        // Use a logical couple ID (e.g., sorted IDs concatenated)
        final coupleId = [user.id, profile!.partnerId!].toList()..sort();
        final coupleKey = coupleId.join('_');

        await ref
            .read(scrapbookRepositoryProvider)
            .addItem(
              uploaderId: user.id,
              coupleId: coupleKey,
              imageFile: image,

              caption: caption,
            );
      }
    }
  }

  Future<String?> _showCaptionDialog(BuildContext context) async {
    String? caption;
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add a Caption'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter your caption'),
            onChanged: (value) {
              caption = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(dialogContext).pop(caption);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Our Scrapbook')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndUploadImage(context, ref),
        backgroundColor: const Color(0xFFFE80A5),
        child: const Icon(Icons.add_photo_alternate_rounded),
      ),
      body: profileAsync.when(
        data: (profile) {
          final partnerId = profile.partnerId;

          if (partnerId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFE80A5).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.link_off_rounded,
                        color: Color(0xFFFE80A5),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Partner Linked',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Link your partner from the dashboard to start sharing special moments together in this scrapbook.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }

          final coupleId = [user!.id, partnerId].toList()..sort();
          final coupleKey = coupleId.join('_');

          return StreamBuilder<List<ScrapbookItem>>(
            stream: ref
                .watch(scrapbookRepositoryProvider)
                .watchItems(coupleKey),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white24,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Our Scrapbook is Empty',
                        style: TextStyle(color: Colors.white60, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the + button to add a memory',
                        style: TextStyle(color: Colors.white24, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.white10),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Text(
                            item.caption ?? 'Moment',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
