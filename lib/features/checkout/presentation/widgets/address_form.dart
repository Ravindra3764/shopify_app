import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/custom_text_box.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';

/// Validated delivery-address entry form (address fields only — buyer email is
/// collected separately on the checkout address step).
///
/// On valid submit, calls [onSubmit] with the assembled [MailingAddress]. When
/// [phoneRequired] is set the phone field must be filled. Pass [initialAddress]
/// to edit an existing entry (its id is preserved).
class AddressForm extends StatefulWidget {
  const AddressForm({
    required this.onSubmit,
    super.key,
    this.initialAddress,
    this.phoneRequired = false,
    this.submitLabel = 'Save address',
  });

  final ValueChanged<MailingAddress> onSubmit;
  final MailingAddress? initialAddress;
  final bool phoneRequired;
  final String submitLabel;

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();

  late final _firstName = TextEditingController(
    text: widget.initialAddress?.firstName,
  );
  late final _lastName = TextEditingController(
    text: widget.initialAddress?.lastName,
  );
  late final _address1 = TextEditingController(
    text: widget.initialAddress?.address1,
  );
  late final _address2 = TextEditingController(
    text: widget.initialAddress?.address2,
  );
  late final _city = TextEditingController(text: widget.initialAddress?.city);
  late final _province = TextEditingController(
    text: widget.initialAddress?.province,
  );
  late final _zip = TextEditingController(text: widget.initialAddress?.zip);
  late final _country = TextEditingController(
    text: widget.initialAddress?.country,
  );
  late final _phone = TextEditingController(text: widget.initialAddress?.phone);

  final _controllers = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _controllers.addAll([
      _firstName,
      _lastName,
      _address1,
      _address2,
      _city,
      _province,
      _zip,
      _country,
      _phone,
    ]);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _validateCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    if (v.length != 2) return 'Use a 2-letter code';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final address = MailingAddress(
      id:
          widget.initialAddress?.id ??
          'addr_${DateTime.now().microsecondsSinceEpoch}',
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      address1: _address1.text.trim(),
      address2: _address2.text.trim().isEmpty ? null : _address2.text.trim(),
      city: _city.text.trim(),
      province: _province.text.trim().toUpperCase(),
      zip: _zip.text.trim(),
      country: _country.text.trim().toUpperCase(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
    );
    widget.onSubmit(address);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextBox(
                  label: 'First name',
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomTextBox(
                  label: 'Last name',
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextBox(
            label: 'Address',
            hintText: 'Street address',
            controller: _address1,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: _required,
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextBox(
            label: 'Apartment, suite, etc. (optional)',
            controller: _address2,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextBox(
                  label: 'City',
                  controller: _city,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomTextBox(
                  label: 'State',
                  hintText: 'CA',
                  controller: _province,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [_UpperCaseFormatter()],
                  validator: _validateCode,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: CustomTextBox(
                  label: 'ZIP / Postal',
                  controller: _zip,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomTextBox(
                  label: 'Country',
                  hintText: 'US',
                  controller: _country,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [_UpperCaseFormatter()],
                  validator: _validateCode,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextBox(
            label: widget.phoneRequired ? 'Phone' : 'Phone (optional)',
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: widget.phoneRequired ? _required : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton.primary(label: widget.submitLabel, onPressed: _submit),
        ],
      ),
    );
  }
}

/// Uppercases text as it's typed — for ISO country/province codes.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => TextEditingValue(
    text: newValue.text.toUpperCase(),
    selection: newValue.selection,
  );
}
