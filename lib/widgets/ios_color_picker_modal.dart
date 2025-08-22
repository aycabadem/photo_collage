import 'package:flutter/material.dart';

class iOSColorPickerModal extends StatefulWidget {
  final Color currentColor;
  final double currentOpacity;
  final Function(Color color, double opacity) onColorChanged;

  const iOSColorPickerModal({
    super.key,
    required this.currentColor,
    required this.currentOpacity,
    required this.onColorChanged,
  });

  @override
  State<iOSColorPickerModal> createState() => _iOSColorPickerModalState();
}

class _iOSColorPickerModalState extends State<iOSColorPickerModal> {
  late Color _selectedColor;
  late double _selectedOpacity;
  late List<Color> _savedColors;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
    _selectedOpacity = widget.currentOpacity;
    _savedColors = [
      Colors.black,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.red,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildColorGrid()),
            _buildOpacitySlider(),
            _buildSavedColors(),
            const SizedBox(height: 12),
            _buildApplyButton(),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header content
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.colorize,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const Expanded(
                child: Text(
                  'Colours',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorGrid() {
    final colors = _generateColorGrid();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 12,
        childAspectRatio: 1.0,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = color == _selectedColor;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildOpacitySlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPACITY',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                  ),
                  child: Slider(
                    value: _selectedOpacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    onChanged: (value) {
                      setState(() {
                        _selectedOpacity = value;
                      });
                    },
                  ),
                ),
              ),
              Container(
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Text(
                    '${(_selectedOpacity * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedColors() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Current selected color (large)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _selectedColor.withValues(alpha: _selectedOpacity),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
          ),
          const SizedBox(height: 16),
          // Saved colors row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Saved colors
              ...(_savedColors.map(
                (color) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ),
              )),
              // Add color button
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (!_savedColors.contains(_selectedColor)) {
                        _savedColors.add(_selectedColor);
                      }
                    });
                  },
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Icon(Icons.add, color: Colors.grey[600], size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _generateColorGrid() {
    final colors = <Color>[];

    // First row: Grays
    for (int i = 0; i < 12; i++) {
      final grayValue = (255 * (i / 11)).round();
      colors.add(Color.fromRGBO(grayValue, grayValue, grayValue, 1));
    }

    // Next 6 rows: Color spectrum
    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 12; col++) {
        final hue = (col / 11) * 360;
        final saturation = 0.3 + (row / 5) * 0.7;
        final lightness = 0.2 + (row / 5) * 0.6;

        colors.add(
          HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor(),
        );
      }
    }

    return colors;
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _applyColor,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Text(
            'Apply',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _applyColor() {
    widget.onColorChanged(_selectedColor, _selectedOpacity);
    Navigator.of(context).pop();
  }
}
