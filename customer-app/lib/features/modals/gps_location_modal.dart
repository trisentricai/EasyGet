import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// GPS Location Map Picker modal.
class GpsLocationModal extends ConsumerStatefulWidget {
  const GpsLocationModal({super.key});

  @override
  ConsumerState<GpsLocationModal> createState() => _GpsLocationModalState();
}

class _GpsLocationModalState extends ConsumerState<GpsLocationModal> {
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
                Text('Set Delivery Location', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Map placeholder
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.sunken,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, size: 64, color: colors.faint),
                            const SizedBox(height: 16),
                            Text('Interactive Map', style: AppTypography.bodyMedium(theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('Tap "Locate Me" to pin your delivery location', style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Central pulsing pin indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primaryTint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.my_location, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Central Pulsing Pin', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                              Text('Visual location target with animated ripple', style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Locate me button
                  FilledButton.icon(
                    onPressed: () => _locateMe(),
                    icon: const Icon(Icons.gps_fixed),
                    label: const Text('Locate Me'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                  const SizedBox(height: 16),
                  // Serviceability status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: colors.success),
                        const SizedBox(width: 8),
                        Expanded(child: Text('12 Min Delivery Hub #04 · Doorstep coverage confirmed', style: AppTypography.body(colors.success))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Preset areas
                  Text('Popular Areas', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['HSR Layout', 'Indiranagar', 'Koramangala', 'Bellandur'].map((area) => ActionChip(
                      label: Text(area, style: AppTypography.body(theme.colorScheme.onSurface)),
                      onPressed: () => _selectArea(area),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Update location across app
                    },
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                    child: const Text('Confirm Delivery Location'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _locateMe() {
    // Simulate GPS location
  }

  void _selectArea(String area) {
    // Select preset area
  }
}