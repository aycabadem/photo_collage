import 'package:flutter/material.dart';
import '../models/aspect_spec.dart';

/// Dialog for entering custom aspect ratio values
class CustomAspectRatioDialog extends StatefulWidget {
  /// Current aspect ratio to pre-fill the dialog
  final AspectSpec currentAspect;

  /// Callback when custom ratio is applied
  final ValueChanged<AspectSpec> onRatioApplied;

  const CustomAspectRatioDialog({
    super.key,
    required this.currentAspect,
    required this.onRatioApplied,
  });

  @override
  State<CustomAspectRatioDialog> createState() =>
      _CustomAspectRatioDialogState();
}

class _CustomAspectRatioDialogState extends State<CustomAspectRatioDialog> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(
      text: widget.currentAspect.w.toString(),
    );
    _heightController = TextEditingController(
      text: widget.currentAspect.h.toString(),
    );
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.aspect_ratio,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('Custom Aspect Ratio'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter width and height values between 1.0-9.99:',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _widthController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Width',
                    hintText: '1.2', // Updated hint
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Height',
                    hintText: '2.3', // Updated hint
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final w = double.tryParse(_widthController.text);
            final h = double.tryParse(_heightController.text);

            // Validate range (1-9.99) only
            if (w != null &&
                h != null &&
                w >= 1.0 &&
                w < 10.0 &&
                h >= 1.0 &&
                h < 10.0) {
              // Create AspectSpec directly with original decimal values
              final customAspect = AspectSpec(
                w: w,
                h: h,
                label: '$w:$h', // Direct label with original values
              );
              widget.onRatioApplied(customAspect);
              Navigator.pop(context, true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please enter valid numbers between 1.0 and 9.99 (decimals allowed like 1.2, 4.12, 9.9)',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
