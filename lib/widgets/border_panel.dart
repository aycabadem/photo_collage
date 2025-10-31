import 'package:flutter/material.dart';
import '../models/aspect_spec.dart';
import '../services/collage_manager.dart';
import 'aspect_ratio_selector.dart';

/// Border effects panel with SHADOW, BORDER, and CORNER RADIUS
class BorderPanel extends StatefulWidget {
  final CollageManager collageManager;
  final VoidCallback onClose;

  const BorderPanel({
    super.key,
    required this.collageManager,
    required this.onClose,
  });

  @override
  State<BorderPanel> createState() => _BorderPanelState();
}

class _BorderPanelState extends State<BorderPanel> {
  String _selectedEffect = 'inner';
  bool _showSlider = false;
  double? _shadowDraft;
  double? _innerDraft;
  double? _outerDraft;
  double? _cornerDraft;
  double _aspectScalar = 1.0;

  @override
  void initState() {
    super.initState();
    _aspectScalar = widget.collageManager.selectedAspect.ratio.clamp(0.5, 2.0);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom - 16;

    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact slider area (shown above the icons)
          if (_showSlider)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
              child: _buildCompactSliderArea(),
            ),

          // Compact horizontal icon toolbar at the bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: _buildIconToolbar(),
          ),
        ],
      ),
    );
  }

  /// Minimal horizontal toolbar with clearer icons and labels
  Widget _buildIconToolbar() {
    Widget item(String key, IconData icon, String label) {
      final bool active = _selectedEffect == key;
      final primary = Theme.of(context).colorScheme.primary;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            if (_selectedEffect == key) {
              final bool willShow = !_showSlider;
              _showSlider = willShow;
              if (willShow && key == 'aspect') {
                _aspectScalar =
                    widget.collageManager.selectedAspect.ratio.clamp(0.5, 2.0);
              }
            } else {
              _selectedEffect = key;
              _showSlider = true; // show for newly selected effect
              if (key == 'aspect') {
                _aspectScalar =
                    widget.collageManager.selectedAspect.ratio.clamp(0.5, 2.0);
              }
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: active ? primary : primary.withValues(alpha: 0.6),
                semanticLabel: label,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? primary : primary.withValues(alpha: 0.8),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        item('aspect', Icons.aspect_ratio, 'Aspect'),
        item('shadow', Icons.tonality, 'Shadow'),
        item('inner', Icons.border_inner, 'Inner'),
        item('outer', Icons.border_outer, 'Outer'),
        item('corner_radius', Icons.rounded_corner, 'Radius'),
      ],
    );
  }

  /// Compact slider area: label + slider stacked
  Widget _buildCompactSliderArea() {
    if (_selectedEffect == 'aspect') {
      return _buildAspectControls();
    }
    return SizedBox(
      height: 64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getEffectTitle(),
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          _buildSlider(),
        ],
      ),
    );
  }

  /// Build the appropriate slider based on selected effect
  Widget _buildSlider() {
    switch (_selectedEffect) {
      case 'aspect':
        return const SizedBox.shrink();
      case 'shadow':
        return _buildShadowSlider();
      case 'inner':
        return _buildInnerMarginSlider();
      case 'outer':
        return _buildOuterMarginSlider();
      case 'corner_radius':
        return _buildCornerRadiusSlider();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Shadow slider
  Widget _buildShadowSlider() {
    return StatefulBuilder(
      builder: (context, update) {
        final double value =
            _shadowDraft ?? widget.collageManager.shadowIntensity;
        return _GradientSlider(
          value: value,
          min: 0.0,
          max: 14.0,
          onChanged: (v) {
            update(() {
              _shadowDraft = v;
            });
          },
          onChangeEnd: (v) {
            widget.collageManager.setShadowIntensity(v);
            update(() {
              _shadowDraft = null;
            });
          },
          label: 'Shadow: ${value.toStringAsFixed(1)}',
        );
      },
    );
  }

  /// Inner margin slider (space between photos)
  Widget _buildInnerMarginSlider() {
    return StatefulBuilder(
      builder: (context, update) {
        final double value =
            (_innerDraft ?? widget.collageManager.innerMargin).clamp(0.0, 20.0);
        return Row(
          children: [
            Expanded(
              child: _GradientSlider(
                value: value,
                min: 0.0,
                max: 20.0,
                onChanged: (v) {
                  update(() {
                    _innerDraft = v;
                  });
                },
                onChangeEnd: (v) {
                  widget.collageManager.setInnerMargin(v);
                  update(() {
                    _innerDraft = null;
                  });
                },
                label: 'Inner: ${value.toStringAsFixed(1)}px',
              ),
            ),
            const SizedBox(width: 12),
            _buildValueBadge(value),
          ],
        );
      },
    );
  }

  /// Outer margin slider (frame around collage)
  Widget _buildOuterMarginSlider() {
    return StatefulBuilder(
      builder: (context, update) {
        final double value =
            (_outerDraft ?? widget.collageManager.outerMargin).clamp(0.0, 20.0);
        return Row(
          children: [
            Expanded(
              child: _GradientSlider(
                value: value,
                min: 0.0,
                max: 20.0,
                onChanged: (v) {
                  update(() {
                    _outerDraft = v;
                  });
                },
                onChangeEnd: (v) {
                  widget.collageManager.setOuterMargin(v);
                  update(() {
                    _outerDraft = null;
                  });
                },
                label: 'Outer: ${value.toStringAsFixed(1)}px',
              ),
            ),
            const SizedBox(width: 12),
            _buildValueBadge(value),
          ],
        );
      },
    );
  }

  /// Corner radius slider
  Widget _buildCornerRadiusSlider() {
    return StatefulBuilder(
      builder: (context, update) {
        final double value = (_cornerDraft ??
                widget.collageManager.cornerRadius)
            .clamp(0.0, 160.0);
        return Row(
          children: [
            Expanded(
              child: _GradientSlider(
                value: value,
                min: 0.0,
                max: 160.0,
                onChanged: (v) {
                  update(() {
                    _cornerDraft = v;
                  });
                },
                onChangeEnd: (v) {
                  widget.collageManager.setCornerRadius(v);
                  update(() {
                    _cornerDraft = null;
                  });
                },
                label: 'Corner Radius: ${value.toStringAsFixed(1)}px',
              ),
            ),
            const SizedBox(width: 12),
            _buildValueBadge(value),
          ],
        );
      },
    );
  }

  /// Get the title for the selected effect
  String _getEffectTitle() {
    switch (_selectedEffect) {
      case 'aspect':
        return 'Aspect Ratio';
      case 'shadow':
        return 'Shadow';
      case 'inner':
        return 'Inner Margin';
      case 'outer':
        return 'Outer Margin';
      case 'margin':
        return 'Margin';
      case 'corner_radius':
        return 'Radius';
      default:
        return '';
    }
  }

  Widget _buildValueBadge(double value) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        '${value.round()} px',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.primary,
        ),
      ),
    );
  }

  // _selectEffect removed (not used)

  Widget _buildAspectControls() {
    final theme = Theme.of(context);
    final manager = widget.collageManager;

    String fmt2(double v) {
      final s = v.toStringAsFixed(2);
      return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
    }

    String formatRatio(double r) =>
        r >= 1.0 ? '${fmt2(r)}:1' : '1:${fmt2(1.0 / r)}';

    AspectSpec buildSpec(double ratio) {
      if (ratio >= 1.0) {
        return AspectSpec(w: ratio, h: 1, label: formatRatio(ratio));
      } else {
        return AspectSpec(w: 1, h: 1 / ratio, label: formatRatio(ratio));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aspect Ratio',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
          AspectRatioSelector(
            selectedAspect: manager.selectedAspect,
            presets: manager.presetsWithCustom,
            onAspectChanged: (aspect) {
              setState(() {
                _aspectScalar = aspect.ratio.clamp(0.5, 2.0);
              });
              manager.applyAspect(aspect);
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor:
                      theme.colorScheme.primary.withOpacity(0.2),
                  thumbColor: theme.colorScheme.primary,
                  overlayColor:
                      theme.colorScheme.primary.withOpacity(0.12),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 18),
                  valueIndicatorColor: theme.colorScheme.primary,
                  valueIndicatorTextStyle: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  showValueIndicator: ShowValueIndicator.always,
                ),
                child: Slider(
                  value: _aspectScalar,
                  min: 0.5,
                  max: 2.0,
                  label: formatRatio(_aspectScalar),
                  onChanged: (v) {
                    setState(() {
                      _aspectScalar = v;
                    });
                    final spec = buildSpec(v);
                    manager.applyAspect(spec);
                    manager.setCustomAspect(spec);
                  },
                  onChangeEnd: (v) {
                    final spec = buildSpec(v);
                    manager.setCustomAspect(spec);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A compact gradient slider with small label, matching the visual style
class _GradientSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String label;

  const _GradientSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color inactive = primary.withValues(alpha: 0.25);

    return SizedBox(
      height: 36,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 4,
          activeTrackColor: primary,
          inactiveTrackColor: inactive,
          thumbColor: primary,
          overlayColor: primary.withValues(alpha: 0.12),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          valueIndicatorColor: primary,
        ),
        child: Slider(
          value: value,
          min: min,
          max: max,
          label: label,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ),
    );
  }
}
