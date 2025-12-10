import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Pantalla de lista de conversaciones
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.loadConversations();
      chatProvider.subscribeToConversations();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<ChatProvider>().loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.userProfile?.id;
    final conversations = chatProvider.conversations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        actions: [
          if (chatProvider.totalUnreadCount > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${chatProvider.totalUnreadCount} sin leer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: chatProvider.isLoading && conversations.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final otherUser =
                          conversation.getOtherParticipant(currentUserId ?? '');

                      return ListTile(
                        onTap: () => context.push('/chat/${conversation.id}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.1),
                              backgroundImage: otherUser?.avatarUrl != null
                                  ? CachedNetworkImageProvider(
                                      otherUser!.avatarUrl!)
                                  : null,
                              child: otherUser?.avatarUrl == null
                                  ? Text(
                                      otherUser?.fullName.isNotEmpty == true
                                          ? otherUser!.fullName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    )
                                  : null,
                            ),
                            if (conversation.hasUnread)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      conversation.unreadCount > 9
                                          ? '9+'
                                          : '${conversation.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                otherUser?.fullName ?? 'Usuario',
                                style: TextStyle(
                                  fontWeight: conversation.hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              conversation.relativeTime,
                              style: TextStyle(
                                color: conversation.hasUnread
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondaryLight,
                                fontSize: 12,
                                fontWeight: conversation.hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              conversation.lastMessage ?? 'Nueva conversación',
                              style: TextStyle(
                                color: conversation.hasUnread
                                    ? AppTheme.textPrimaryLight
                                    : AppTheme.textSecondaryLight,
                                fontWeight: conversation.hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (conversation.product != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 12,
                                    color: AppTheme.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      conversation.product!.name,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryLight,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppTheme.textSecondaryLight.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin conversaciones',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando contactes a un vendedor o\nalguien te contacte, aparecerá aquí',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

