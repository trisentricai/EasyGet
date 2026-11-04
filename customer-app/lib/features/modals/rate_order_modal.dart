import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Order & Rider Rating modal.
class RateOrderModal extends ConsumerStatefulWidget {
  const RateOrderModal({super.key});

  @override
  ConsumerState<RateOrderModal> createState() => _RateOrderModalState();
}

class _RateOrderModalState extends ConsumerState<RateOrderModal> {
  int _produceRating = 0;
  int _riderRating = 0;
  final Set<String> _selectedTags = {};
  final _controller = TextEditingController();

  final _feedbackTags = [
    'Super Fresh Produce',
    'Crisp Packaging',
    '10-Min Fast Delivery',
    'Polite Rider',
    'Perfect Ripeness',
    'Zero Plastic Used',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                Text('Rate Your Order', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Produce rating
                  Text('How was the produce quality?', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  _StarRating(rating: _produceRating, onChanged: (v) => setState(() => _produceRating = v)),
                  const SizedBox(height: 4),
                  Text(_produceRating == 0 ? 'Tap to rate' : _ratingLabel(_produceRating), style: AppTypography.caption(colors.marigold)),
                  const SizedBox(height: 24),
                  // Rider rating
                  Text('How was rider Ravi Kumar?', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  _StarRating(rating: _riderRating, onChanged: (v) => setState(() => _riderRating = v)),
                  const SizedBox(height: 4),
                  Text(_riderRating == 0 ? 'Tap to rate' : _ratingLabel(_riderRating), style: AppTypography.caption(colors.marigold)),
                  const SizedBox(height: 24),
                  // Feedback tags
                  Text('Feedback Tags', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _feedbackTags.map((tag) => FilterChip(
                      label: Text(tag, style: AppTypography.label(_selectedTags.contains(tag) ? Colors.white : theme.colorScheme.onSurface)),
                      selected: _selectedTags.contains(tag),
                      onSelected: (_) => setState(() => _selectedTags.contains(tag) ? _selectedTags.remove(tag) : _selectedTags.add(tag)),
                      selectedColor: colors.primary,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Comment
                  Text('Additional Comments (Optional)', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tell us more about your experience...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Submit
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: (_produceRating > 0 || _riderRating > 0) ? () => Navigator.pop(context, true) : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              child: const Text('Submit Feedback & Earn 20 Coins'),
            ),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Poor';
      case 2: return 'Below Average';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent';
      default: return '';
    }
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).freshColors;

    return Row(
      children: List.generate(5, (i) {
        final filled = i < rating;
        return IconButton(
          onPressed: () => onChanged(i + 1),
          icon: Icon(
            filled ? Icons.star : Icons.star_border,
            color: filled ? colors.marigold : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 32,
          ),
        );
      }),
    );
  }
}