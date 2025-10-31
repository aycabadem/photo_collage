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

  const AspectRatioSelector({
    super.key,
    required this.selectedAspect,
    required this.presets,
    required this.onAspectChanged,
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

    return DropdownButton<AspectSpec>(
      value: dropdownValue,
      underline: Container(),
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
    );
  }
}
