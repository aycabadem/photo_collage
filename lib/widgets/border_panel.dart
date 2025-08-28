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
  String? _selectedEffect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Border Effects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Effect Buttons or Active Slider
          Expanded(
            child: SingleChildScrollView(
              child: _selectedEffect == null
                  ? _buildEffectButtons()
                  : _buildActiveSlider(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the 3 effect buttons
  Widget _buildEffectButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // First row: SHADOW and MARGIN
          Row(
            children: [
              Expanded(
                child: _buildEffectButton(
                  'SHADOW',
                  Icons.blur_on,
                  Colors.purple,
                  () => _selectEffect('shadow'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEffectButton(
                  'MARGIN',
                  Icons.margin,
                  Colors.blue,
                  () => _selectEffect('margin'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Second row: CORNER RADIUS
          Row(
            children: [
              Expanded(
                child: _buildEffectButton(
                  'CORNER RADIUS',
                  Icons.rounded_corner,
                  Colors.orange,
                  () => _selectEffect('corner_radius'),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()), // Empty space
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual effect button
  Widget _buildEffectButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the active slider for selected effect
  Widget _buildActiveSlider() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Effect title and back button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getEffectTitle(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedEffect = null),
                icon: const Icon(Icons.arrow_back),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Slider
          _buildSlider(),

          const SizedBox(height: 20),

          // Checkmark
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
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
    return Column(
      children: [
        Slider(
          value: widget.collageManager.shadowIntensity,
          min: 0.0,
          max: 20.0,
          divisions: 20,
          onChanged: (value) {
            widget.collageManager.setShadowIntensity(value);
            setState(() {}); // Force UI update
          },
        ),
        Text(
          'Shadow: ${widget.collageManager.shadowIntensity.toStringAsFixed(1)}',
        ),
      ],
    );
  }

  /// Margin slider (creates space between photos)
  Widget _buildMarginSlider() {
    return Column(
      children: [
        Slider(
          value: widget
              .collageManager
              .globalBorderWidth, // Using border width for margin
          min: 0.0,
          max: 50.0, // Reduced from 200 to 50 for easier movement
          divisions: 25, // Reduced from 100 to 25 for bigger steps
          onChanged: (value) {
            widget.collageManager.changeGlobalBorderWidth(value);
            setState(() {}); // Force UI update
          },
        ),
        Text(
          'Margin: ${widget.collageManager.globalBorderWidth.toStringAsFixed(1)}px',
        ),
      ],
    );
  }

  /// Corner radius slider
  Widget _buildCornerRadiusSlider() {
    return Column(
      children: [
        Slider(
          value: widget.collageManager.cornerRadius,
          min: 0.0,
          max: 50.0,
          divisions: 50,
          onChanged: (value) {
            widget.collageManager.setCornerRadius(value);
            setState(() {}); // Force UI update
          },
        ),
        Text(
          'Corner Radius: ${widget.collageManager.cornerRadius.toStringAsFixed(1)}',
        ),
      ],
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
        return 'CORNER RADIUS';
      default:
        return '';
    }
  }

  /// Select an effect to show its slider
  void _selectEffect(String effect) {
    setState(() {
      _selectedEffect = effect;
    });
  }
}
