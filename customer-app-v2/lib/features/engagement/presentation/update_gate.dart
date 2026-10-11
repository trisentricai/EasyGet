import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tokens.dart';
import '../data/app_update_repository.dart';

/// App version for the update check.
final packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

/// URL opening seam (faked in tests).
abstract class UrlOpener {
  Future<bool> open(String url);
}

class SystemUrlOpener implements UrlOpener {
  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final urlOpenerProvider = Provider<UrlOpener>((_) => SystemUrlOpener());

String _platform() {
  if (defaultTargetPlatform == TargetPlatform.iOS) return 'IOS';
  if (defaultTargetPlatform == TargetPlatform.android) return 'ANDROID';
  return 'WEB';
}

/// E3 · App-update gate: checks once per launch (post-frame), shows a
/// version dialog for optional updates (dismissible this launch) and a
/// blocking one for mandatory updates. Check failures stay silent.
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  bool _checked = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (_checked || !mounted) return;
    _checked = true;
    try {
      final package = await ref.read(packageInfoProvider.future);
      final info = await ref
          .read(appUpdateRepositoryProvider)
          .checkUpdate(
              platform: _platform(), version: package.version);
      if (!mounted || !info.updateAvailable || _dismissed) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: !info.isMandatory,
        builder: (_) => _UpdateDialog(infoVersion: info.version ?? '',
            notes: info.releaseNotes ?? '',
            mandatory: info.isMandatory,
            downloadUrl: info.downloadUrl,
            onLater: info.isMandatory
                ? null
                : () {
                    _dismissed = true;
                    Navigator.of(context).pop();
                  }),
      );
    } catch (_) {
      // Silent: update checks never break the launch.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _UpdateDialog extends ConsumerWidget {
  const _UpdateDialog({
    required this.infoVersion,
    required this.notes,
    required this.mandatory,
    required this.downloadUrl,
    required this.onLater,
  });

  final String infoVersion;
  final String notes;
  final bool mandatory;
  final String? downloadUrl;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final url = (downloadUrl ?? '').trim();
    return AlertDialog(
      title: Text(
          mandatory ? 'Update required' : 'Update available${infoVersion.isEmpty ? '' : ' · $infoVersion'}'),
      content: notes.isEmpty
          ? const Text('A newer EasyGet is ready.')
          : Text(notes),
      actions: [
        if (onLater != null)
          TextButton(
            onPressed: onLater,
            child: const Text('Later'),
          ),
        if (url.isNotEmpty)
          FilledButton(
            onPressed: () => ref.read(urlOpenerProvider).open(url),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppRadii.button),
              ),
            ),
            child: const Text('Update'),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
      ],
    );
  }
}
