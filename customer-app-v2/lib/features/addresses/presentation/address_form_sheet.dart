import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../models/address_model.dart';
import '../data/address_repository.dart';

/// Shared add/edit address sheet (S9 checkout + S13 addresses): validated
/// fields, inline errors, v1 India-only (country is fixed, not a field).
/// Returns the saved [Address] on success, null on dismiss.
class AddressFormSheet extends ConsumerStatefulWidget {
  const AddressFormSheet({super.key, this.existing});

  final Address? existing;

  static Future<Address?> show(BuildContext context,
      {Address? existing}) {
    return showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (_) => AddressFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<AddressFormSheet> {
  late final TextEditingController _label =
      TextEditingController(text: widget.existing?.label ?? 'Home');
  late final TextEditingController _line1 =
      TextEditingController(text: widget.existing?.line1 ?? '');
  late final TextEditingController _line2 =
      TextEditingController(text: widget.existing?.line2 ?? '');
  late final TextEditingController _city =
      TextEditingController(text: widget.existing?.city ?? '');
  late final TextEditingController _state =
      TextEditingController(text: widget.existing?.state ?? '');
  late final TextEditingController _postal =
      TextEditingController(text: widget.existing?.postalCode ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.existing?.phone ?? '');

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    _phone.dispose();
    super.dispose();
  }

  AddressDraft? _draft() {
    if (_line1.text.trim().isEmpty) return _fail('House / street is required.');
    if (_city.text.trim().isEmpty) return _fail('City is required.');
    if (_state.text.trim().isEmpty) return _fail('State is required.');
    if (!RegExp(r'^\d{6}$').hasMatch(_postal.text.trim())) {
      return _fail('Enter a 6-digit pincode.');
    }
    if (!RegExp(r'^\d{10}$').hasMatch(_phone.text.trim())) {
      return _fail('Enter a 10-digit phone number.');
    }
    return AddressDraft(
      label: _label.text.trim().isEmpty ? 'Home' : _label.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      postalCode: _postal.text.trim(),
      country: 'India',
      phone: _phone.text.trim(),
    );
  }

  AddressDraft? _fail(String message) {
    setState(() => _error = message);
    return null;
  }

  Future<void> _save() async {
    final draft = _draft();
    if (draft == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(addressRepositoryProvider);
      final saved = widget.existing == null
          ? await repo.create(draft)
          : await repo.update(widget.existing!.id, draft);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is ApiException ? e.message : 'Could not save the address.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              AppSpace.lg + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.faint,
                    borderRadius:
                        BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                widget.existing == null ? 'Add address' : 'Edit address',
                style: AppTypography.screenTitle(scheme.onSurface),
              ),
              const SizedBox(height: AppSpace.md),
              _field(_label, 'Label (Home / Work)', key: const Key('addr-label')),
              const SizedBox(height: AppSpace.sm),
              _field(_line1, 'House / street *',
                  key: const Key('addr-line1')),
              const SizedBox(height: AppSpace.sm),
              _field(_line2, 'Landmark (optional)'),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                      child: _field(_city, 'City *',
                          key: const Key('addr-city'))),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                      child: _field(_state, 'State *',
                          key: const Key('addr-state'))),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                      child: _field(_postal, 'Pincode *',
                          key: const Key('addr-postal'),
                          keyboard: TextInputType.number)),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                      child: _field(_phone, 'Phone *',
                          key: const Key('addr-phone'),
                          keyboard: TextInputType.phone)),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpace.sm),
                Text(_error!,
                    key: const Key('addr-error'),
                    style: AppTypography.caption(scheme.error)),
              ],
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                height: 54,
                child: FilledButton(
                  key: const Key('addr-save'),
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : Text(widget.existing == null
                          ? 'Save address'
                          : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint,
      {Key? key, TextInputType? keyboard}) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return SizedBox(
      height: 52,
      child: TextField(
        key: key,
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: TextCapitalization.words,
        style: AppTypography.body(scheme.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.input),
            borderSide: BorderSide(color: colors.faint),
          ),
        ),
      ),
    );
  }
}