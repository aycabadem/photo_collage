import 'package:flutter/material.dart';
import '../services/collage_manager.dart';

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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom - 16;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFAEE),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000), // ~10% black
            blurRadius: 10,
            offset: Offset(0, -2),
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
              _showSlider = !_showSlider; // toggle
            } else {
              _selectedEffect = key;
              _showSlider = true; // show for newly selected effect
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
        item('shadow', Icons.tonality, 'Shadow'),
        item('inner', Icons.border_inner, 'Inner'),
        item('outer', Icons.border_outer, 'Outer'),
        item('corner_radius', Icons.rounded_corner, 'Radius'),
      ],
    );
  }

  /// Compact slider area: label + slider stacked
  Widget _buildCompactSliderArea() {
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
    return _GradientSlider(
      value: widget.collageManager.shadowIntensity,
      min: 0.0,
      max: 14.0,
      onChanged: (v) {
        widget.collageManager.setShadowIntensity(v);
        setState(() {});
      },
      label:
          'Shadow: ${widget.collageManager.shadowIntensity.toStringAsFixed(1)}',
    );
  }

  /// Inner margin slider (space between photos)
  Widget _buildInnerMarginSlider() {
    final double value = widget.collageManager.innerMargin;
    return Row(
      children: [
        Expanded(
          child: _GradientSlider(
            value: value,
            min: 0.0,
            max: 60.0,
            onChanged: (v) {
              widget.collageManager.setInnerMargin(v);
              setState(() {});
            },
            label: 'Inner: ${value.toStringAsFixed(1)}px',
          ),
        ),
        const SizedBox(width: 12),
        _buildValueBadge(value),
      ],
    );
  }

  /// Outer margin slider (frame around collage)
  Widget _buildOuterMarginSlider() {
    final double value = widget.collageManager.outerMargin;
    return Row(
      children: [
        Expanded(
          child: _GradientSlider(
            value: value,
            min: 0.0,
            max: 120.0,
            onChanged: (v) {
              widget.collageManager.setOuterMargin(v);
              setState(() {});
            },
            label: 'Outer: ${value.toStringAsFixed(1)}px',
          ),
        ),
        const SizedBox(width: 12),
        _buildValueBadge(value),
      ],
    );
  }

  /// Corner radius slider
  Widget _buildCornerRadiusSlider() {
    final double value = widget.collageManager.cornerRadius;
    return Row(
      children: [
        Expanded(
          child: _GradientSlider(
            value: value,
            min: 0.0,
            max: 160.0,
            onChanged: (v) {
              widget.collageManager.setCornerRadius(v);
              setState(() {});
            },
            label: 'Corner Radius: ${value.toStringAsFixed(1)}px',
          ),
        ),
        const SizedBox(width: 12),
        _buildValueBadge(value),
      ],
    );
  }

  /// Get the title for the selected effect
  String _getEffectTitle() {
    switch (_selectedEffect) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Text(
        '${value.round()} px',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  // _selectEffect removed (not used)
}

/// A compact gradient slider with small label, matching the visual style
class _GradientSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String label;

  const _GradientSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
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
        ),
      ),
    );
  }
}
