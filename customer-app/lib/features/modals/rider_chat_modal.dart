import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Rider Live Chat modal.
class RiderChatModal extends ConsumerStatefulWidget {
  const RiderChatModal({super.key});

  @override
  ConsumerState<RiderChatModal> createState() => _RiderChatModalState();
}

class _RiderChatModalState extends ConsumerState<RiderChatModal> {
  final _controller = TextEditingController();
  final _messages = [
    _ChatMessage(text: 'Hi! I\'m on my way with your order.', isUser: false, time: '2 min ago'),
    _ChatMessage(text: 'Great, thanks! Please leave at the door.', isUser: true, time: '1 min ago'),
    _ChatMessage(text: 'Noted! Reaching your doorstep in 3 minutes.', isUser: false, time: 'Just now'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primaryTint,
                  child: Icon(Icons.person, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ravi Kumar', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                      Text('KA 01 EK 8812 · Ather 450X', style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.call, color: colors.primary),
                  tooltip: 'Call driver',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[_messages.length - 1 - i];
                return _ChatBubble(message: msg);
              },
            ),
          ),
          // Quick reply chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                'Leave at flat door, thank you!',
                'Please don\'t ring the bell',
                'Call me once at apartment gate',
                'Hand over to security guard',
              ].map((text) => ActionChip(
                label: Text(text, style: AppTypography.caption(theme.colorScheme.onSurface)),
                onPressed: () => _sendMessage(text),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              )).toList(),
            ),
          ),
          // Input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (v) => _sendMessage(v),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: colors.primary,
                  child: IconButton(
                    onPressed: () => _sendMessage(_controller.text),
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, time: 'Just now'));
      _controller.clear();
    });
    // Simulate auto-reply
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: 'Noted! Reaching your doorstep in 3 minutes.', isUser: false, time: 'Just now'));
        });
      }
    });
  }
}

class _ChatMessage {
  _ChatMessage({required this.text, required this.isUser, required this.time});

  final String text;
  final bool isUser;
  final String time;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(radius: 12, backgroundColor: colors.primaryTint, child: Icon(Icons.person, size: 12, color: colors.primary)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser ? colors.primary : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: message.isUser ? Radius.zero : Radius.circular(16),
                  bottomLeft: message.isUser ? Radius.circular(16) : Radius.zero,
                ),
                border: message.isUser ? null : Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message.text, style: AppTypography.body(message.isUser ? Colors.white : theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message.time, style: AppTypography.tabularSmall(message.isUser ? Colors.white.withValues(alpha: 0.7) : theme.colorScheme.onSurfaceVariant)),
                      if (message.isUser) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all, size: 12, color: Colors.white.withValues(alpha: 0.7)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(radius: 12, backgroundColor: colors.primaryTint, child: Icon(Icons.person, size: 12, color: colors.primary)),
          ],
        ],
      ),
    );
  }
}