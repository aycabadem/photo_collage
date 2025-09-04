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
  String _selectedEffect = 'corner_radius';
  bool _showSlider = false;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom - 16;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFAEE),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: const [
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
      return GestureDetector(
        onTap: () {
          setState(() {
            if (_selectedEffect == key) {
              _showSlider = !_showSlider; // toggle
            } else {
              _selectedEffect = key;
              _showSlider = true; // show for newly selected effect
            }
          });
          // Inform canvas to reserve more/less space based on slider visibility
        },
        child: Container(
          width: 64,
          height: 54,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.30)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.20),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.70),
                semanticLabel: label,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.80),
                  letterSpacing: 0.6,
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
        item('margin', Icons.open_in_full, 'Spacing'),
        item('corner_radius', Icons.rounded_corner, 'Radius'),
      ],
    );
  }

  /// Compact slider area: label + slider stacked
  Widget _buildCompactSliderArea() {
    return SizedBox(
      height: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getEffectTitle(),
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.0,
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
      case 'margin':
        return _buildMarginSlider();
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

  /// Margin slider (creates space between photos)
  Widget _buildMarginSlider() {
    return _GradientSlider(
      value: widget.collageManager.photoMargin,
      min: 0.0,
      max: 15.0,
      onChanged: (v) {
        widget.collageManager.setPhotoMargin(v);
        setState(() {});
      },
      label:
          'Margin: ${widget.collageManager.photoMargin.toStringAsFixed(1)}px',
    );
  }

  /// Corner radius slider
  Widget _buildCornerRadiusSlider() {
    return _GradientSlider(
      value: widget.collageManager.cornerRadius,
      min: 0.0,
      max: 40.0,
      onChanged: (v) {
        widget.collageManager.setCornerRadius(v);
        setState(() {});
      },
      label:
          'Corner Radius: ${widget.collageManager.cornerRadius.toStringAsFixed(1)}px',
    );
  }

  /// Get the title for the selected effect
  String _getEffectTitle() {
    switch (_selectedEffect) {
      case 'shadow':
        return 'SHADOW';
      case 'margin':
        return 'MARGIN';
      case 'corner_radius':
        return 'RADIUS';
      default:
        return '';
    }
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
    final start = Theme.of(context).colorScheme.primary;
    final end = Theme.of(context).colorScheme.secondary;

    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gradient bar behind the track
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(2)),
              gradient: LinearGradient(colors: [start, end]),
            ),
          ),
          // Transparent track slider on top
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
