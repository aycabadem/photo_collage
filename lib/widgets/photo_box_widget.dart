import 'dart:io';

import 'package:flutter/material.dart';
import '../models/photo_box.dart';
import '../widgets/smart_border_overlay.dart';
import '../services/collage_manager.dart';

/// Widget for displaying a single photo box in the collage
class PhotoBoxWidget extends StatefulWidget {
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
  /// Callback when drag starts (used to auto-select)
  final VoidCallback? onPanStart;
  /// Callback when drag ends/cancels (used to auto-deselect)
  final VoidCallback? onPanEnd;

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
    this.onPanStart,
    this.onPanEnd,
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
  State<PhotoBoxWidget> createState() => _PhotoBoxWidgetState();
}

class _PhotoBoxWidgetState extends State<PhotoBoxWidget> {
  double _inlineScaleStart = 1.0;
  Size? _imagePixelSize;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  bool get _inlineEditing =>
      !widget.collageManager.isCustomMode &&
      widget.box.imageFile != null &&
      !widget.box.isLoading;

  @override
  void initState() {
    super.initState();
    _resolveImageMetrics();
  }

  @override
  void didUpdateWidget(PhotoBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? oldPath = oldWidget.box.imageFile?.path;
    final String? newPath = widget.box.imageFile?.path;
    if (oldPath != newPath) {
      _resolveImageMetrics();
    }
  }

  @override
  void dispose() {
    _disposeImageStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.box;
    final bool hasImage = box.imageFile != null;
    final bool isLoading = box.isLoading;
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
      onTap: () async {
        if (isLoading) return;
        widget.onTap();
        if (!hasImage && widget.onAddPhoto != null) {
          await widget.onAddPhoto!();
        }
      },
      onDoubleTap: isLoading ? null : widget.onBringToFront,
      onPanStart: widget.collageManager.isCustomMode && !isLoading
          ? (_) => widget.onPanStart?.call()
          : null,
      onPanUpdate: widget.collageManager.isCustomMode && widget.isSelected && !isLoading
          ? widget.onPanUpdate
          : null,
      onPanEnd: widget.collageManager.isCustomMode && !isLoading
          ? (_) => widget.onPanEnd?.call()
          : null,
      onScaleStart: _inlineEditing ? _handleInlineScaleStart : null,
      onScaleUpdate: _inlineEditing ? _handleInlineScaleUpdate : null,
      onScaleEnd: _inlineEditing ? _handleInlineScaleEnd : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: _frameDecoration(
          cornerRadius: widget.collageManager.cornerRadius,
          intensity: widget.collageManager.shadowIntensity,
          frameColor: frameColor,
          isDarkMode: isDarkMode,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                widget.collageManager.cornerRadius,
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
                              widget.collageManager.cornerRadius,
                            ),
                            border: Border.all(
                              color: placeholderBorderColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    if (!hasImage && !isLoading)
                      Center(
                        child: GestureDetector(
                          onTap: widget.onAddPhoto == null
                              ? null
                              : () async => await widget.onAddPhoto!(),
                          child: Icon(
                            Icons.add_a_photo,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                        ),
                      ),
                    if (!hasImage && isLoading)
                      const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      ),
                    if (hasImage && isLoading)
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.hasGlobalBorder && widget.globalBorderWidth > 0)
                      IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            widget.collageManager.cornerRadius,
                          ),
                          child: SmartBorderOverlay(
                            box: box,
                            borderWidth: widget.globalBorderWidth,
                            borderColor: widget.globalBorderColor,
                            otherBoxes: widget.otherBoxes,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.isSelected && hasImage)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: _SelectionButtons(
                    onEdit: hasImage ? widget.onEdit : null,
                    onDelete: widget.onDelete,
                    showEdit: widget.collageManager.isCustomMode,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleInlineScaleStart(ScaleStartDetails details) {
    _inlineScaleStart = widget.box.photoScale;
  }

  void _handleInlineScaleUpdate(ScaleUpdateDetails details) {
    if (!_inlineEditing) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size;
    if (size == null) return;

    final double nextScale =
        (_inlineScaleStart * details.scale).clamp(1.0, 8.0);

    final double dx = details.focalPointDelta.dx;
    final double dy = details.focalPointDelta.dy;

    final Alignment currentAlignment = widget.box.alignment;

    final double base =
        size.shortestSide > 0 ? size.shortestSide * nextScale : 1.0;

    const double speed = 1.0;

    final double normX = (dx / base) * speed;
    final double normY = (dy / base) * speed;

    final double nextAlignX =
        (currentAlignment.x - normX).clamp(-1.0, 1.0);
    final double nextAlignY =
        (currentAlignment.y - normY).clamp(-1.0, 1.0);

    setState(() {
      widget.box.photoScale = nextScale;
      widget.box.alignment = Alignment(nextAlignX, nextAlignY);
    });

    widget.collageManager.refresh();
  }

  void _resolveImageMetrics() {
    _disposeImageStream();
    final file = widget.box.imageFile;
    if (file == null) {
      if (_imagePixelSize != null) {
        setState(() {
          _imagePixelSize = null;
        });
      }
      return;
    }

    final ImageProvider provider = FileImage(file);
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    _imageStream = stream;
    _imageStreamListener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!mounted) return;
        final Size rawSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        if (_imagePixelSize == rawSize) return;
        setState(() {
          _imagePixelSize = rawSize;
        });
      },
      onError: (_, __) {
        if (!mounted) return;
        if (_imagePixelSize != null) {
          setState(() {
            _imagePixelSize = null;
          });
        }
      },
    );
    stream.addListener(_imageStreamListener!);
  }

  void _disposeImageStream() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  void _handleInlineScaleEnd(ScaleEndDetails details) {
    // Values already persisted via setState/manager refresh.
  }
}

class _SelectionButtons extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  final bool showEdit;

  const _SelectionButtons({
    required this.onEdit,
    required this.onDelete,
    this.showEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useColumn = constraints.maxWidth < 120;

        final Widget spacing = useColumn
            ? const SizedBox(height: 12)
            : const SizedBox(width: 14);

        final bool includeEdit = showEdit && onEdit != null;

        List<Widget> controls = [];
        if (includeEdit) {
          controls.add(_ToolbarIcon(icon: Icons.edit_outlined, onTap: onEdit));
        }
        if (includeEdit) {
          controls.add(spacing);
        }
        controls.add(_ToolbarIcon(icon: Icons.delete_outline, onTap: onDelete));

        final Widget content = useColumn
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: controls,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: controls,
              );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(useColumn ? 18 : 28),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: useColumn ? 6 : 8,
              vertical: useColumn ? 8 : 6,
            ),
            child: content,
          ),
        );
      },
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
