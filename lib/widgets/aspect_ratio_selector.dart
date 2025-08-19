import 'package:flutter/material.dart';
import '../models/aspect_spec.dart';

/// Widget for selecting aspect ratios with preset options and custom input
class AspectRatioSelector extends StatelessWidget {
  /// Currently selected aspect ratio
  final AspectSpec selectedAspect;

  /// List of preset aspect ratios
  final List<AspectSpec> presets;

  /// Callback when aspect ratio changes
  final ValueChanged<AspectSpec> onAspectChanged;

  /// Callback to open custom aspect ratio dialog
  final VoidCallback onCustomRatioPressed;

  const AspectRatioSelector({
    super.key,
    required this.selectedAspect,
    required this.presets,
    required this.onAspectChanged,
    required this.onCustomRatioPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Aspect ratio dropdown
        DropdownButton<AspectSpec>(
          value: selectedAspect,
          underline: Container(), // Remove default underline
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).primaryColor,
          ),
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
          ),
          items: [
            // Preset ratios
            ...presets.map(
              (v) =>
                  DropdownMenuItem<AspectSpec>(value: v, child: Text(v.label)),
            ),
            // Custom ratio (only if not in presets and different from current)
            if (!presets.any(
              (p) => p.w == selectedAspect.w && p.h == selectedAspect.h,
            ))
              DropdownMenuItem<AspectSpec>(
                value: selectedAspect,
                child: Text('${selectedAspect.label} (Custom)'),
              ),
          ],
          onChanged: (v) {
            if (v != null) {
              onAspectChanged(v);
            }
          },
        ),
        Container(width: 1, height: 24, color: Colors.grey[300]),
        IconButton(
          tooltip: 'Custom ratio',
          onPressed: onCustomRatioPressed,
          icon: Icon(Icons.tune, color: Theme.of(context).primaryColor),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
