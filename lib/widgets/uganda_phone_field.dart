import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/uganda_phone_validator.dart';
import '../utils/app_theme.dart';

/// A text field specifically designed for Uganda phone number input
/// with built-in validation and formatting
class UgandaPhoneField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? initialValue;
  final bool required;
  final bool showOperatorIcon;
  final bool showFormatHelper;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? additionalValidator;
  final bool enabled;
  final InputDecoration? decoration;

  const UgandaPhoneField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.initialValue,
    this.required = true,
    this.showOperatorIcon = true,
    this.showFormatHelper = true,
    this.onChanged,
    this.additionalValidator,
    this.enabled = true,
    this.decoration,
  });

  @override
  State<UgandaPhoneField> createState() => _UgandaPhoneFieldState();
}

class _UgandaPhoneFieldState extends State<UgandaPhoneField> {
  late TextEditingController _controller;
  String? _operatorName;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(_onPhoneChanged);
    _onPhoneChanged(); // Initial validation
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onPhoneChanged() {
    final phone = _controller.text;
    setState(() {
      _isValid = UgandaPhoneValidator.isValid(phone);
      if (_isValid) {
        _operatorName = UgandaPhoneValidator.getOperatorName(phone);
      } else {
        _operatorName = null;
      }
    });
    
    if (widget.onChanged != null) {
      widget.onChanged!(phone);
    }
  }

  IconData _getOperatorIcon() {
    if (_operatorName == null) return Icons.phone;
    
    if (_operatorName!.contains('MTN')) {
      return Icons.phone_android;
    } else if (_operatorName!.contains('Airtel')) {
      return Icons.phone_iphone;
    } else if (_operatorName!.contains('Africell')) {
      return Icons.smartphone;
    }
    return Icons.phone;
  }

  Color _getOperatorColor() {
    if (!_isValid) return AppTheme.textSecondary;
    
    if (_operatorName == null) return AppTheme.primaryColor;
    
    if (_operatorName!.contains('MTN')) {
      return Colors.yellow.shade700; // MTN yellow
    } else if (_operatorName!.contains('Airtel')) {
      return Colors.red.shade700; // Airtel red
    } else if (_operatorName!.contains('Africell')) {
      return Colors.purple.shade700; // Africell purple
    }
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          decoration: widget.decoration ?? InputDecoration(
            labelText: widget.labelText ?? 'Phone Number${widget.required ? ' *' : ''}',
            hintText: widget.hintText ?? '+256 712 345 678 or 0712 345 678',
            prefixIcon: Icon(
              widget.showOperatorIcon ? _getOperatorIcon() : Icons.phone,
              color: widget.showOperatorIcon ? _getOperatorColor() : null,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? _isValid
                    ? Tooltip(
                        message: _operatorName ?? 'Valid Uganda number',
                        child: Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                        ),
                      )
                    : Tooltip(
                        message: 'Invalid Uganda phone number',
                        child: Icon(
                          Icons.error_outline,
                          color: AppTheme.errorColor,
                        ),
                      )
                : null,
            helperText: widget.helperText ?? 
                (widget.showFormatHelper
                    ? 'Format: +256 7XX XXX XXX or 07XX XXX XXX'
                    : null),
            helperMaxLines: 2,
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-\(\)]')),
            LengthLimitingTextInputFormatter(17), // Max length with formatting
          ],
          validator: (value) {
            // First, check if required
            if (widget.required && (value == null || value.trim().isEmpty)) {
              return 'Phone number is required';
            }

            // If not required and empty, it's okay
            if (!widget.required && (value == null || value.trim().isEmpty)) {
              return null;
            }

            // Validate Uganda phone format
            final ugandaError = UgandaPhoneValidator.validate(value);
            if (ugandaError != null) {
              return ugandaError;
            }

            // Run additional validator if provided
            if (widget.additionalValidator != null) {
              return widget.additionalValidator!(value);
            }

            return null;
          },
        ),
        
        // Show operator name if valid
        if (_isValid && _operatorName != null && widget.showOperatorIcon)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: _getOperatorColor(),
                ),
                const SizedBox(width: 4),
                Text(
                  _operatorName!,
                  style: TextStyle(
                    fontSize: 11,
                    color: _getOperatorColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A dialog to show Uganda phone number format help
class UgandaPhoneFormatHelpDialog extends StatelessWidget {
  const UgandaPhoneFormatHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.help_outline, color: AppTheme.primaryColor),
          SizedBox(width: 8),
          Text('Uganda Phone Number Format'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Valid Formats:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildFormatExamples(),
            const SizedBox(height: 16),
            const Text(
              'Mobile Operators:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildOperatorList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }

  List<Widget> _buildFormatExamples() {
    final examples = [
      '+256 712 345 678',
      '0712 345 678',
      '256712345678',
      '+256712345678',
    ];

    return examples.map((example) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            const Icon(Icons.check, size: 16, color: AppTheme.successColor),
            const SizedBox(width: 8),
            Text(
              example,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildOperatorList() {
    final operators = [
      {'name': 'MTN Uganda', 'prefixes': '76, 77, 78, 79', 'color': Colors.yellow.shade700},
      {'name': 'Airtel Uganda', 'prefixes': '70, 74, 75', 'color': Colors.red.shade700},
      {'name': 'Africell Uganda', 'prefixes': '73', 'color': Colors.purple.shade700},
      {'name': 'Uganda Telecom', 'prefixes': '71', 'color': Colors.blue.shade700},
      {'name': 'Lycamobile', 'prefixes': '72', 'color': Colors.green.shade700},
    ];

    return operators.map((op) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: op['color'] as Color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    op['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Prefixes: ${op['prefixes']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

/// Shows a help dialog about Uganda phone number format
void showUgandaPhoneFormatHelp(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const UgandaPhoneFormatHelpDialog(),
  );
}
