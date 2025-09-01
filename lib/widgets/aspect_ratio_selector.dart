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
    // Try to map the currently selected aspect to a known preset.
    // If not found, don't force a value into Dropdown to avoid duplicate/zero match asserts.
    const double eps = 1e-3;
    final AspectSpec matched = presets.firstWhere(
      (p) => (p.w - selectedAspect.w).abs() < eps && (p.h - selectedAspect.h).abs() < eps,
      orElse: () => const AspectSpec(w: -1, h: -1, label: ''),
    );
    final AspectSpec? dropdownValue = (matched.w > 0 && matched.h > 0) ? matched : null;

    return Row(
      children: [
        // Aspect ratio dropdown
        DropdownButton<AspectSpec>(
          value: dropdownValue,
          underline: Container(), // Remove default underline
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.primary,
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          items: presets
              .map((v) => DropdownMenuItem<AspectSpec>(value: v, child: Text(v.label)))
              .toList(),
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
          icon: Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
