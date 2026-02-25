import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../data/vault_repository.dart';
import '../../auth/data/auth_service.dart';
import '../../../core/utils/encryption_service.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isUnlocked = false;
  String _status = 'Authenticating...';
  final TextEditingController _addItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _status = 'Biometrics not available on this device.';
          // For testing, we might allow bypass, but user asked for biometrics.
          // Let's keep it locked to show it's "working" (i.e., checking).
        });
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'FaceID required to unlock the Vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow passcode if biometrics fail/unavailable
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        setState(() => _isUnlocked = true);
      } else {
        setState(() => _status = 'Authentication failed. Please try again.');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  void _addSecret(String userId) async {
    final text = _addItemController.text.trim();
    if (text.isEmpty) return;
    final encrypted = await EncryptionService.encrypt(text);
    await ref.read(vaultRepositoryProvider).addVaultItem(userId, encrypted);
    _addItemController.clear();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;

    if (!_isUnlocked) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F111A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF4EE1D1).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  size: 80,
                  color: Color(0xFF4EE1D1),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Vault Locked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4EE1D1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Unlock with Biometrics',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        title: const Text('The Vault'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isUnlocked = false),
            icon: const Icon(Icons.lock_outline_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<VaultItem>>(
        stream: ref.watch(vaultRepositoryProvider).watchVaultItems(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Your vault is empty.\nSave your most private thoughts here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                color: Colors.white.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: FutureBuilder<String>(
                    future: EncryptionService.decrypt(item.content),
                    builder: (context, decSnapshot) {
                      return Text(
                        decSnapshot.data ?? 'Decrypting...',
                        style: const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white24,
                    ),
                    onPressed: () => ref
                        .read(vaultRepositoryProvider)
                        .deleteVaultItem(item.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(user.id),
        backgroundColor: const Color(0xFF4EE1D1),
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
    );
  }

  void _showAddDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E2E),
        title: const Text(
          'Add to Vault',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _addItemController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Type your secret...',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _addSecret(userId),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
