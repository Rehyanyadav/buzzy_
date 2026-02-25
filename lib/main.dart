import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/data/profile_repository.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/chat/presentation/chat_list_screen.dart';
import 'features/scrapbook/presentation/scrapbook_screen.dart';
import 'features/vault/presentation/vault_screen.dart';
import 'features/auth/presentation/profile_screen.dart';
import 'core/services/notification_service.dart';
import 'package:intl/intl.dart';

import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await NotificationService.init();

  runApp(const ProviderScope(child: NexusApp()));
}

class NexusApp extends ConsumerStatefulWidget {
  const NexusApp({super.key});

  @override
  ConsumerState<NexusApp> createState() => _NexusAppState();
}

class _NexusAppState extends ConsumerState<NexusApp>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Timer? _lastSeenTimer;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ChatListScreen(),
    const ScrapbookScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLastSeenTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lastSeenTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateLastSeen();
    }
  }

  void _startLastSeenTimer() {
    _lastSeenTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _updateLastSeen();
    });
  }

  void _updateLastSeen() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      ref.read(profileRepositoryProvider).updateLastSeen(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'BUZZY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authState.when(
        data: (state) {
          if (state.session != null) {
            return Scaffold(
              body: _screens[_selectedIndex],
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1E2E),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  backgroundColor: Colors.transparent,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: const Color(0xFF6C5DD3),
                  unselectedItemColor: Colors.white24,
                  showSelectedLabels: true,
                  showUnselectedLabels: false,
                  elevation: 0,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_rounded),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.forum_rounded),
                      label: 'Chats',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.auto_awesome_mosaic_rounded),
                      label: 'Photos',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_rounded),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            );
          }
          return const AuthScreen();
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final profileAsync = ref.watch(profileProvider);

    if (user != null) {
      Future.microtask(
        () => ref
            .read(profileRepositoryProvider)
            .ensureProfileExists(user.id, user.email ?? ''),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C5DD3).withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  profileAsync.when(
                    data: (p) => _buildHeader(context, ref, user, p),
                    loading: () => _buildHeader(
                      context,
                      ref,
                      user,
                      ProfileModel(id: '', moodEmoji: '...'),
                    ),
                    error: (_, __) => _buildHeader(
                      context,
                      ref,
                      user,
                      ProfileModel(id: '', moodEmoji: '⚠️'),
                    ),
                  ),
                  const SizedBox(height: 40),
                  profileAsync.when(
                    data: (profile) => _buildBody(context, ref, profile),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6C5DD3),
                      ),
                    ),
                    error: (e, _) => Center(child: Text('Syncing issue: $e')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    User? user,
    ProfileModel profile,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF6C5DD3), Color(0xFFFE80A5)],
                ),
              ),
              child: Center(
                child: Text(
                  (profile.displayName ?? 'N')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                Text(
                  profile.displayName ?? 'BUZZY',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () => ref.read(authServiceProvider).signOut(),
          icon: const Icon(Icons.logout_rounded, color: Colors.white24),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProfileModel profile) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPartnerStatusCard(context, ref, profile),
          const SizedBox(height: 40),
          const Text(
            'Our Space',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.9,
            children: [
              _FeatureCard(
                title: 'Messaging',
                subtitle: 'Talk to your person',
                icon: Icons.forum_rounded,
                color: const Color(0xFF6C5DD3),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                ),
              ),
              _FeatureCard(
                title: 'Memories',
                subtitle: 'Captured moments',
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFFFE80A5),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScrapbookScreen()),
                ),
              ),
              _FeatureCard(
                title: 'The Vault',
                subtitle: 'Private & Secure',
                icon: Icons.lock_rounded,
                color: const Color(0xFF4EE1D1),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VaultScreen()),
                ),
              ),
              _FeatureCard(
                title: 'Mood Sync',
                subtitle: 'Sync feelings',
                icon: Icons.favorite_rounded,
                color: const Color(0xFFFFA970),
                onTap: () => _showMoodPicker(context, ref, profile.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerStatusCard(
    BuildContext context,
    WidgetRef ref,
    ProfileModel myProfile,
  ) {
    final partnerId = myProfile.partnerId;
    if (partnerId == null) {
      return _buildEmptyPartnerState(context, ref, myProfile.id);
    }

    return StreamBuilder<ProfileModel>(
      stream: ref.watch(profileRepositoryProvider).watchProfile(partnerId),
      builder: (context, snapshot) {
        final partner = snapshot.data;
        final isOnline =
            partner?.lastSeen != null &&
            DateTime.now().difference(partner!.lastSeen!).inSeconds < 40;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6C5DD3).withValues(alpha: 0.1),
                      border: Border.all(
                        color: const Color(0xFF6C5DD3).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        partner?.moodEmoji ?? '🤍',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  if (isOnline)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4EE1D1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0F111A),
                          width: 2,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner?.displayName ?? 'Your Partner',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOnline
                          ? 'Active right now'
                          : (partner?.lastSeen != null
                                ? 'Last seen ${DateFormat('HH:mm').format(partner!.lastSeen!)}'
                                : 'Offline'),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(partnerId: partnerId),
                  ),
                ),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyPartnerState(
    BuildContext context,
    WidgetRef ref,
    String myId,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5DD3).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFF6C5DD3).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.link_off_rounded,
            color: Color(0xFF6C5DD3),
            size: 32,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'No partner linked yet. Start your journey together!',
              style: TextStyle(color: Colors.white60, fontSize: 14),
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => _showLinkPartnerDialog(context, ref, myId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5DD3).withValues(alpha: 0.2),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Link',
              style: TextStyle(color: Color(0xFFC7BDFF)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLinkPartnerDialog(
    BuildContext context,
    WidgetRef ref,
    String myId,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E2E),
        title: const Text(
          'Link Partner',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Enter Partner's Email",
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Removed NotificationService.requestPermission() as it fails on Web

                await ref
                    .read(profileRepositoryProvider)
                    .linkPartnerByEmail(myId, controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  void _showMoodPicker(BuildContext context, WidgetRef ref, String myId) {
    final moods = ['❤️', '😊', '😢', '😴', '🔥', '🧗', '🍿', '💡'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How are you feeling?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: moods
                  .map(
                    (m) => GestureDetector(
                      onTap: () {
                        ref.read(profileRepositoryProvider).updateMood(myId, m);
                        Navigator.pop(context);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(m, style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1E2E),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
