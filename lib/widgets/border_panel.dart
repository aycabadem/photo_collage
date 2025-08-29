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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: bottomInset > 0 ? 6 : 0),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Minimal top bar with grabber and apply (check)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),

          // Compact slider area (shown above the icons)
          if (_showSlider)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
              child: _buildCompactSliderArea(),
            ),

          // Compact horizontal icon toolbar at the bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: _buildIconToolbar(),
          ),
        ],
      ),
    ),
    );
  }

  /// Minimal horizontal toolbar with small monochrome icons
  Widget _buildIconToolbar() {
    Widget item(String key, IconData icon, String tooltip) {
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
          widget.collageManager.setBottomUiInset(_showSlider ? 200 : 130);
        },
        child: Container(
          width: 40,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? Colors.black.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.black.withValues(alpha: active ? 0.85 : 0.6),
            semanticLabel: tooltip,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        item('shadow', Icons.blur_on, 'Shadow'),
        item('margin', Icons.margin, 'Margin'),
        item('corner_radius', Icons.rounded_corner, 'Corner radius'),
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
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
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
      label: 'Shadow: ${widget.collageManager.shadowIntensity.toStringAsFixed(1)}',
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
      label: 'Margin: ${widget.collageManager.photoMargin.toStringAsFixed(1)}px',
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

  /// Select an effect to show its slider
  void _selectEffect(String effect) {
    setState(() {
      _selectedEffect = effect;
      _showSlider = true;
    });
  }
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
    const start = Color(0xFFE91E63); // pink
    const end = Color(0xFF7C4DFF); // purple

    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gradient bar behind the track
          Container(
            height: 4,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(2)),
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
