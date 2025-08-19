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
      title: const Text('Custom Ratio (Width:Height)'),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _widthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Width'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Height'),
            ),
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
            final w = int.tryParse(_widthController.text);
            final h = int.tryParse(_heightController.text);
            if (w != null && h != null && w > 0 && h > 0) {
              final customAspect = AspectSpec(w: w, h: h, label: '$w:$h');
              widget.onRatioApplied(customAspect);
              Navigator.pop(context, true);
            } else {
              // Show error for invalid input
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter valid positive numbers'),
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
