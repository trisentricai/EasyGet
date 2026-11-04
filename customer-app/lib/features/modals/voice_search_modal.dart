import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Voice Search modal.
class VoiceSearchModal extends ConsumerStatefulWidget {
  const VoiceSearchModal({super.key});

  @override
  ConsumerState<VoiceSearchModal> createState() => _VoiceSearchModalState();
}

class _VoiceSearchModalState extends ConsumerState<VoiceSearchModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
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
                Text('Voice Search', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120 + _controller.value * 30,
                          height: 120 + _controller.value * 30,
                          decoration: BoxDecoration(
                            color: colors.primaryTint.withValues(alpha: 0.3 * _controller.value),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: colors.primaryTint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_listening ? Icons.mic : Icons.mic_none, size: 40, color: colors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _listening ? 'Listening... say "Avocado" or "Gir cow milk"' : 'Tap the mic to start voice search',
                    style: AppTypography.body(theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _listening = !_listening);
                      if (_listening) {
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _listening = false);
                        });
                      }
                    },
                    icon: Icon(_listening ? Icons.stop : Icons.mic),
                    label: Text(_listening ? 'Stop Listening' : 'Start Voice Search'),
                  ),
                  const SizedBox(height: 24),
                  Text('Quick Speech Triggers', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      'Organic Hass Avocado',
                      'A2 Gir Cow Milk',
                      'Country Sourdough Loaf',
                    ].map((s) => ActionChip(
                      label: Text(s, style: AppTypography.body(theme.colorScheme.onSurface)),
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to search with this query
                      },
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}