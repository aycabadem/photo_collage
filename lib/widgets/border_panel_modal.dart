import 'package:flutter/material.dart';
import 'ios_color_picker_modal.dart';

/// Modal for selecting global border settings
class BorderPanelModal extends StatefulWidget {
  final double currentBorderWidth;
  final Color currentBorderColor;
  final Function(double, Color) onBorderChanged;

  const BorderPanelModal({
    super.key,
    required this.currentBorderWidth,
    required this.currentBorderColor,
    required this.onBorderChanged,
  });

  @override
  State<BorderPanelModal> createState() => _BorderPanelModalState();
}

class _BorderPanelModalState extends State<BorderPanelModal> {
  late double _borderWidth;
  late Color _borderColor;

  @override
  void initState() {
    super.initState();
    _borderWidth = widget.currentBorderWidth;
    _borderColor = widget.currentBorderColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400, // Increased height to prevent overflow
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Global Border Settings',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // Border width slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Border Width: ${_borderWidth.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _borderWidth,
                  min: 0.0,
                  max: 10.0,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      _borderWidth = value;
                    });
                  },
                ),
              ],
            ),
          ),

          // Border color picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Border Color:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showColorPicker(context),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.color_lens,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Apply button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  widget.onBorderChanged(_borderWidth, _borderColor);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Apply Border',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IOSColorPickerModal(
        currentColor: _borderColor,
        currentOpacity: 1.0,
        onColorChanged: (color, opacity) {
          setState(() {
            _borderColor = color;
          });
        },
      ),
    );
  }
}
