import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/message_repository.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/data/profile_repository.dart';
import 'chat_screen.dart';

import 'user_search_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSearchScreen()),
              );
            },
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: ref
                  .read(messageRepositoryProvider)
                  .getConversationUserIds(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final userIds = snapshot.data ?? [];
                if (userIds.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          color: Colors.white24,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(color: Colors.white60),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Find someone to chat with!',
                          style: TextStyle(color: Colors.white24),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: userIds.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final otherUserId = userIds[index];
                    return _FilteredConversationTile(
                      userId: otherUserId,
                      searchQuery: _searchQuery,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserSearchScreen()),
          );
        },
        backgroundColor: const Color(0xFF6C5DD3),
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
    );
  }
}

class _FilteredConversationTile extends ConsumerWidget {
  final String userId;
  final String searchQuery;
  const _FilteredConversationTile({
    required this.userId,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ProfileModel?>(
      future: ref.read(profileRepositoryProvider).getProfile(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final profile = snapshot.data!;

        // Filter by display name or email
        final name = (profile.displayName ?? 'Standard User').toLowerCase();
        final email = (profile.email ?? '').toLowerCase();
        if (searchQuery.isNotEmpty &&
            !name.contains(searchQuery) &&
            !email.contains(searchQuery)) {
          return const SizedBox.shrink();
        }

        return _ConversationTile(profile: profile);
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ProfileModel profile;
  const _ConversationTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(partnerId: profile.id)),
      ),
      leading: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C5DD3),
              const Color(0xFF6C5DD3).withValues(alpha: 0.5),
            ],
          ),
        ),
        child: Center(
          child: Text(
            (profile.displayName ?? 'N')[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
      title: Text(
        profile.displayName ?? 'Standard User',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        profile.bio ?? 'Let\'s chat!',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white38),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white12),
    );
  }
}
