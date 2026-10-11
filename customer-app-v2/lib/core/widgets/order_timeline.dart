import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/tokens.dart';
import '../../models/order_models.dart';
import 'status_pill.dart';

/// DESIGN §11.4 — vertical status timeline. The current (last) node is
/// primary; cancelled / refunded nodes are muted.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.events});

  final List<OrderStatusEvent> events;

  static const _terminalMuted = {'CANCELLED', 'REFUNDED'};

  Color _nodeColor(int index, ColorScheme scheme, FreshMarketColorTokens colors) {
    final status = events[index].to;
    if (_terminalMuted.contains(status)) return colors.faint;
    if (index == events.length - 1) return scheme.primary;
    return colors.faint;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < events.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      key: Key('timeline-node-$i'),
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: _nodeColor(i, scheme, colors),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i != events.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: colors.sunken,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == events.length - 1 ? 0 : AppSpace.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          humanizeStatus(events[i].to),
                          style: AppTypography.bodyMedium(scheme.onSurface),
                        ),
                        if (events[i].note != null &&
                            events[i].note!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(events[i].note!,
                              style:
                                  AppTypography.caption(scheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}