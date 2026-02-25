import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile(String id) async {
    await ref
        .read(profileRepositoryProvider)
        .updateProfile(
          id: id,
          displayName: _nameController.text.trim(),
          bio: _bioController.text.trim(),
        );
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (!_isEditing) {
            _nameController.text = profile.displayName ?? '';
            _bioController.text = profile.bio ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5DD3), Color(0xFFFE80A5)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6C5DD3,
                            ).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (profile.displayName ?? 'N')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4EE1D1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Form
                _buildField(
                  label: 'Display Name',
                  controller: _nameController,
                  enabled: _isEditing,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 20),
                _buildField(
                  label: 'Bio',
                  controller: _bioController,
                  enabled: _isEditing,
                  icon: Icons.info_outline_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                _buildReadOnlyField(
                  label: 'Email',
                  value: profile.email ?? 'Not set',
                  icon: Icons.email_outlined,
                ),

                if (_isEditing) ...[
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => _saveProfile(profile.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5DD3),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 48,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 40),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Account Security',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    onTap: () => _showBlockedUsers(context, profile),
                    leading: const Icon(
                      Icons.block_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Blocked Accounts',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white24,
                    ),
                    tileColor: Colors.white.withValues(alpha: 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showBlockedUsers(BuildContext context, ProfileModel profile) {
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
              'Blocked Users',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (profile.blockedIds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No blocked users',
                  style: TextStyle(color: Colors.white38),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: profile.blockedIds.length,
                itemBuilder: (context, index) {
                  final blockedId = profile.blockedIds[index];
                  return ListTile(
                    title: Text(
                      'User ID: ${blockedId.substring(0, 8)}...',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: TextButton(
                      onPressed: () {
                        ref
                            .read(profileRepositoryProvider)
                            .toggleBlockUser(profile.id, blockedId, false);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Unblock',
                        style: TextStyle(color: Color(0xFF4EE1D1)),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6C5DD3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white24, size: 20),
              const SizedBox(width: 12),
              Text(value, style: const TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      ],
    );
  }
}
