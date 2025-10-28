import 'package:flutter/material.dart';
import '../models/photo_box.dart';
import '../widgets/smart_border_overlay.dart';
import '../services/collage_manager.dart';

/// Widget for displaying a single photo box in the collage
class PhotoBoxWidget extends StatelessWidget {
  /// The photo box data to display
  final PhotoBox box;

  /// Whether this box is currently selected
  final bool isSelected;

  /// Callback when the box is tapped
  final VoidCallback onTap;

  /// Callback when the box should move above others
  final VoidCallback onBringToFront;

  /// Callback when the box is dragged
  final void Function(DragUpdateDetails) onPanUpdate;

  /// Callback when the edit button is tapped
  final VoidCallback onEdit;

  /// Callback when the delete button is tapped
  final VoidCallback onDelete;

  /// Callback when add photo button is tapped
  final Future<void> Function()? onAddPhoto;

  /// Global border settings from CollageManager
  final double globalBorderWidth;
  final Color globalBorderColor;
  final bool hasGlobalBorder;

  /// Other photo boxes for smart border detection
  final List<PhotoBox> otherBoxes;

  /// CollageManager for accessing new border effects
  final CollageManager collageManager;

  const PhotoBoxWidget({
    super.key,
    required this.box,
    required this.isSelected,
    required this.onTap,
    required this.onBringToFront,
    required this.onPanUpdate,
    required this.onEdit,
    required this.onDelete,
    this.onAddPhoto,
    required this.globalBorderWidth,
    required this.globalBorderColor,
    required this.hasGlobalBorder,
    required this.otherBoxes,
    required this.collageManager,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = box.imageFile != null;
    final theme = Theme.of(context);
    final Color placeholderBorderColor =
        theme.colorScheme.primary.withValues(alpha: 0.65);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color frameColor = Color.alphaBlend(
      isDarkMode
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.85),
      theme.colorScheme.surface,
    );

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onBringToFront,
      onPanUpdate: isSelected ? onPanUpdate : null,
      behavior: HitTestBehavior.opaque, // Prevent background taps
      child: Container(
        decoration: _frameDecoration(
          cornerRadius: collageManager.cornerRadius,
          intensity: collageManager.shadowIntensity,
          frameColor: frameColor,
          isDarkMode: isDarkMode,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                collageManager.cornerRadius,
              ),
              child: ColoredBox(
                color: frameColor,
                child: Stack(
                  children: [
                    if (hasImage)
                      Transform.scale(
                        scale: box.photoScale,
                        alignment: box.alignment,
                        child: Image.file(
                          box.imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          alignment: box.alignment,
                        ),
                      ),
                    if (!hasImage)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              collageManager.cornerRadius,
                            ),
                            border: Border.all(
                              color: placeholderBorderColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    if (!hasImage)
                      Center(
                        child: GestureDetector(
                          onTap: onAddPhoto == null
                              ? null
                              : () async => await onAddPhoto!(),
                          child: Icon(
                            Icons.add_a_photo,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                        ),
                      ),
                    if (hasGlobalBorder && globalBorderWidth > 0)
                      IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            collageManager.cornerRadius,
                          ),
                          child: SmartBorderOverlay(
                            box: box,
                            borderWidth: globalBorderWidth,
                            borderColor: globalBorderColor,
                            otherBoxes: otherBoxes,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: _SelectionButtons(
                    onEdit: hasImage ? onEdit : null,
                    onDelete: onDelete,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectionButtons extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _SelectionButtons({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarIcon(
              icon: Icons.edit_outlined,
              onTap: onEdit,
            ),
            const SizedBox(width: 14),
            _ToolbarIcon(
              icon: Icons.delete_outline,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ToolbarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? activeColor : Colors.grey,
        ),
      ),
    );
  }
}

/// Decorates the photo box frame so the outer shadow respects rounded corners.
BoxDecoration _frameDecoration({
  required double cornerRadius,
  required double intensity,
  required Color frameColor,
  required bool isDarkMode,
}) {
  return BoxDecoration(
    color: frameColor,
    borderRadius: BorderRadius.circular(cornerRadius),
    boxShadow: _shadowLayers(
      intensity,
      isDarkMode: isDarkMode,
    ),
  );
}

/// Build layered shadows for a crisper 3D-like effect without a dull halo.
List<BoxShadow>? _shadowLayers(double intensity, {required bool isDarkMode}) {
  if (intensity <= 0) return null;

  // Normalize to 0..1 based on current slider range (0..14)
  final double t = (intensity.clamp(0.0, 14.0)) / 14.0;

  final double dropOpacity = isDarkMode
      ? 0.32 + 0.18 * t
      : 0.18 + 0.16 * t;
  final double dropBlur = 18 + 14 * t; // 18..32
  final double dropOffsetY = 8 + 6 * t; // 8..14

  final double rimOpacity = isDarkMode
      ? 0.22 + 0.12 * t
      : 0.10 + 0.05 * t;
  final double rimBlur = 10 + 8 * t; // 10..22
  final double rimOffsetY = 3 + 3 * t; // 3..6

  final double highlightOpacity = isDarkMode
      ? 0.16 + 0.08 * t
      : 0.35 + 0.25 * t;
  final double highlightBlur = 8 + 8 * t; // 8..22
  final double highlightOffsetY = -(2 + 2 * t); // -2..-4

  return [
    BoxShadow(
      color: Colors.white.withValues(alpha: highlightOpacity),
      blurRadius: highlightBlur,
      offset: Offset(0, highlightOffsetY),
      spreadRadius: -2 - t,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: rimOpacity),
      blurRadius: rimBlur,
      offset: Offset(0, rimOffsetY),
      spreadRadius: -1.5,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: dropOpacity),
      blurRadius: dropBlur,
      offset: Offset(0, dropOffsetY),
    ),
  ];
}
