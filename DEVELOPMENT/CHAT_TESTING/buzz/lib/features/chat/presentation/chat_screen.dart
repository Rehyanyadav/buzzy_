import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/data/profile_repository.dart';
import '../data/message_repository.dart';
import '../data/message_model.dart';
import '../data/storage_service.dart';
import '../data/audio_recorder_service.dart';
import 'chat_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? partnerId;
  const ChatScreen({super.key, this.partnerId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorderService _recorderService = AudioRecorderService();

  bool _isTyping = false;
  bool _isRecording = false;
  MessageModel? _replyingTo;
  final Set<String> _selectedMessageIds = {};
  bool _isSelectionMode = false;

  @override
  void dispose() {
    _recorderService.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTyping(String? myId, String? partnerId) {
    if (myId == null || partnerId == null) return;
    if (_controller.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ref.read(profileRepositoryProvider).setTypingStatus(myId, partnerId);
    } else if (_controller.text.isEmpty && _isTyping) {
      _isTyping = false;
      ref.read(profileRepositoryProvider).setTypingStatus(myId, null);
    }
  }

  void _sendMessage(
    String partnerId, {
    String? content,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    final text = content ?? _controller.text.trim();
    if (text.isEmpty && mediaUrl == null && _replyingTo == null) return;

    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        final replyToId = _replyingTo?.id;
        if (content == null) _controller.clear();
        setState(() => _replyingTo = null);
        _onTyping(user.id, partnerId);

        await ref
            .read(messageRepositoryProvider)
            .sendMessage(
              text,
              user.id,
              partnerId,
              type: type,
              mediaUrl: mediaUrl,
              replyToId: replyToId,
            );

        _scrollToBottom();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickMedia(
    String partnerId,
    bool isImage, {
    bool fromCamera = false,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? file = isImage
          ? await picker.pickImage(
              source: fromCamera ? ImageSource.camera : ImageSource.gallery,
            )
          : await picker.pickVideo(
              source: fromCamera ? ImageSource.camera : ImageSource.gallery,
            );

      if (file != null) {
        final url = await ref
            .read(storageServiceProvider)
            .uploadChatMedia(file.path, file.name);
        if (url != null) {
          _sendMessage(
            partnerId,
            type: isImage ? MessageType.image : MessageType.video,
            mediaUrl: url,
            content: isImage ? 'Image' : 'Video',
          );
        }
      }
    } catch (e) {
      // Pick error handled silently or via UI
    }
  }

  Future<void> _pickFile(String partnerId) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final url = await ref
            .read(storageServiceProvider)
            .uploadChatMedia(file.path!, file.name);
        if (url != null) {
          _sendMessage(
            partnerId,
            type: MessageType.file,
            mediaUrl: url,
            content: file.name,
          );
        }
      }
    } catch (e) {
      // File error handled silently or via UI
    }
  }

  Future<void> _startRecording() async {
    await _recorderService.startRecording();
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording(String partnerId) async {
    final path = await _recorderService.stopRecording();
    setState(() => _isRecording = false);
    if (path != null) {
      final url = await ref
          .read(storageServiceProvider)
          .uploadChatMedia(
            path,
            'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
          );
      if (url != null) {
        _sendMessage(
          partnerId,
          type: MessageType.audio,
          mediaUrl: url,
          content: '🎤 Audio Message',
        );
      }
    }
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedMessageIds.add(messageId);
        _isSelectionMode = true;
      }
    });
  }

  void _deleteSelectedMessages() async {
    final count = _selectedMessageIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E2E),
        title: Text('Delete $count messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final id in _selectedMessageIds) {
        await ref.read(messageRepositoryProvider).deleteMessage(id);
      }
      setState(() {
        _selectedMessageIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  void _clearChat(String partnerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E2E),
        title: const Text('Clear conversation?'),
        content: const Text('This will delete all messages for both of you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        await ref
            .read(messageRepositoryProvider)
            .clearMessages(user.id, partnerId);
      }
    }
  }

  void _handleBlock(String myId, String partnerId, bool blocked) async {
    try {
      await ref
          .read(profileRepositoryProvider)
          .toggleBlockUser(myId, partnerId, !blocked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(blocked ? 'User Unblocked' : 'User Blocked')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final myProfileAsync = ref.watch(profileProvider);

    return myProfileAsync.when(
      data: (myProfile) {
        final partnerId = widget.partnerId ?? myProfile.partnerId;
        if (partnerId == null) {
          return const Scaffold(
            body: Center(child: Text('Please link partner')),
          );
        }

        final isBlockedByMe = myProfile.blockedIds.contains(partnerId);

        return StreamBuilder<ProfileModel>(
          stream: ref.watch(profileRepositoryProvider).watchProfile(partnerId),
          builder: (context, snapshot) {
            final partnerProfile = snapshot.data;
            final isPartnerTyping = partnerProfile?.isTypingIn == user?.id;
            final isOnline =
                partnerProfile?.lastSeen != null &&
                DateTime.now().difference(partnerProfile!.lastSeen!).inSeconds <
                    40;

            final lastSeenStr = isOnline
                ? 'Online'
                : _formatLastSeen(partnerProfile?.lastSeen);

            return Scaffold(
              backgroundColor: const Color(0xFF0F111A),
              appBar: AppBar(
                titleSpacing: 0,
                elevation: 0,
                backgroundColor: const Color(0xFF1B1E2E),
                title: Row(
                  children: [
                    if (_isSelectionMode)
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() {
                          _selectedMessageIds.clear();
                          _isSelectionMode = false;
                        }),
                      )
                    else ...[
                      CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Text(
                          partnerProfile?.displayName?[0].toUpperCase() ?? 'P',
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSelectionMode
                              ? '${_selectedMessageIds.length} selected'
                              : (partnerProfile?.displayName ?? 'Partner'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isSelectionMode)
                          Text(
                            isPartnerTyping ? 'typing...' : lastSeenStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isPartnerTyping || isOnline
                                  ? const Color(0xFF4EE1D1)
                                  : Colors.white38,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  if (_isSelectionMode)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: _deleteSelectedMessages,
                    )
                  else
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'block') {
                          _handleBlock(myProfile.id, partnerId, isBlockedByMe);
                        }
                        if (val == 'clear') {
                          _clearChat(partnerId);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep_rounded, size: 20),
                              SizedBox(width: 12),
                              Text('Clear Chat'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.block_rounded,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isBlockedByMe
                                    ? 'Unblock Partner'
                                    : 'Block Partner',
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ref
                        .watch(
                          messagesStreamProvider((
                            userId: user!.id,
                            partnerId: partnerId,
                          )),
                        )
                        .when(
                          data: (messages) => ListView.builder(
                            reverse: true,
                            controller: _scrollController,
                            itemCount: messages.length,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isSelected = _selectedMessageIds.contains(
                                msg.id,
                              );
                              return GestureDetector(
                                onLongPress: () =>
                                    _toggleMessageSelection(msg.id),
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleMessageSelection(msg.id);
                                  }
                                },
                                child: Container(
                                  color: isSelected
                                      ? const Color(
                                          0xFF6C5DD3,
                                        ).withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  child: ChatBubble(
                                    message: msg,
                                    isMe: msg.senderId == user.id,
                                    allMessages: messages,
                                    showTail: true,
                                    onReplyTap: () =>
                                        setState(() => _replyingTo = msg),
                                  ),
                                ),
                              );
                            },
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e')),
                        ),
                  ),
                  if (isBlockedByMe)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      child: const Text(
                        'You have blocked this partner. Unblock to send messages.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    )
                  else
                    _buildInputArea(partnerId),
                ],
              ),
            );
          },
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildInputArea(String partnerId) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        left: 8,
        right: 8,
        top: 10,
      ),
      color: const Color(0xFF1B1E2E),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white54),
            onPressed: () => _showMediaOptions(partnerId),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (v) {
                setState(() {});
                _onTyping(
                  ref.read(authServiceProvider).currentUser?.id,
                  partnerId,
                );
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF0F111A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _controller.text.isEmpty
              ? GestureDetector(
                  onLongPress: _startRecording,
                  onLongPressUp: () => _stopRecording(partnerId),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isRecording
                          ? Colors.redAccent
                          : const Color(0xFF6C5DD3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                )
              : Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          _pickMedia(partnerId, true, fromCamera: true),
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white54,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _sendMessage(partnerId),
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6C5DD3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  void _showMediaOptions(String partnerId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.greenAccent,
            ),
            title: const Text('Camera', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickMedia(partnerId, true, fromCamera: true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image_rounded, color: Colors.blueAccent),
            title: const Text('Gallery', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickMedia(partnerId, true);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.videocam_rounded,
              color: Colors.redAccent,
            ),
            title: const Text('Video', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickMedia(partnerId, false);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.insert_drive_file_rounded,
              color: Colors.orangeAccent,
            ),
            title: const Text(
              'Document',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _pickFile(partnerId);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return DateFormat('HH:mm').format(lastSeen);
    return DateFormat('dd/MM').format(lastSeen);
  }
}
