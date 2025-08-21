import 'package:flutter/material.dart';

/// Floating color bar widget that shows current background color
class FloatingColorBar extends StatefulWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;

  const FloatingColorBar({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  State<FloatingColorBar> createState() => _FloatingColorBarState();
}

class _FloatingColorBarState extends State<FloatingColorBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color indicator
              GestureDetector(
                onTap: _toggleExpanded,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.currentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _getContrastColor(widget.currentColor),
                    size: 24,
                  ),
                ),
              ),
              // Expanded color picker
              if (_isExpanded)
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Current color preview
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: widget.currentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Preset colors grid
                        _buildPresetColors(),
                        const SizedBox(height: 16),
                        // Custom color input
                        _buildCustomColorInput(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetColors() {
    final presetColors = [
      Colors.white,
      Colors.black,
      Colors.grey[100]!,
      Colors.grey[300]!,
      Colors.grey[500]!,
      Colors.grey[700]!,
      Colors.grey[900]!,
      Colors.red[100]!,
      Colors.blue[100]!,
      Colors.green[100]!,
      Colors.yellow[100]!,
      Colors.purple[100]!,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: presetColors.length,
      itemBuilder: (context, index) {
        final color = presetColors[index];
        return GestureDetector(
          onTap: () {
            widget.onColorChanged(color);
            _toggleExpanded();
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: color == widget.currentColor
                    ? Colors.blue
                    : Colors.grey[300]!,
                width: color == widget.currentColor ? 3 : 1,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomColorInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Hex Color',
              hintText: '#F5F5F5',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              try {
                final color = _hexToColor(value);
                widget.onColorChanged(color);
                _toggleExpanded();
              } catch (e) {
                // Invalid hex color - ignore
              }
            },
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add alpha channel
    }
    return Color(int.parse(hex, radix: 16));
  }

  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
