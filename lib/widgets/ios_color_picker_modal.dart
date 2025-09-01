import 'package:flutter/material.dart';
import '../models/background.dart';

class IOSColorPickerModal extends StatefulWidget {
  final Color currentColor;
  final double currentOpacity;
  final Function(Color color, double opacity) onColorChanged;
  final BackgroundMode initialMode;
  final GradientSpec? initialGradient;
  final void Function(GradientSpec spec, double opacity)? onGradientChanged;

  const IOSColorPickerModal({
    super.key,
    required this.currentColor,
    required this.currentOpacity,
    required this.onColorChanged,
    this.initialMode = BackgroundMode.solid,
    this.initialGradient,
    this.onGradientChanged,
  });

  @override
  State<IOSColorPickerModal> createState() => _IOSColorPickerModalState();
}

class _IOSColorPickerModalState extends State<IOSColorPickerModal> {
  late Color _selectedColor;
  late double _selectedOpacity;
  late BackgroundMode _mode;
  late GradientSpec _gradient;
  late double _h; // 0..360
  late double _s; // 0..1
  late double _l; // 0..1

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
    _selectedOpacity = widget.currentOpacity;
    _mode = widget.initialMode;
    _gradient = widget.initialGradient ?? GradientSpec.presetPinkPurple();
    final hsl = HSLColor.fromColor(_selectedColor);
    _h = hsl.hue;
    _s = hsl.saturation;
    _l = hsl.lightness;
    // Başlangıç: ana rengi göstermek için L ve S değerlerini orta/yüksekten başlat
    bool adjusted = false;
    if (_l > 0.85 || _l < 0.15) {
      _l = 0.5;
      adjusted = true;
    }
    if (_s < 0.6) {
      _s = 0.9; // doygunluğu yüksekten başlat
      adjusted = true;
    }
    if (adjusted && _mode == BackgroundMode.solid) {
      // Canlı önizleme için ilk açılışta da uygula
      _selectedColor = HSLColor.fromAHSL(1.0, _h, _s, _l).toColor();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onColorChanged(_selectedColor, _selectedOpacity);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      constraints: BoxConstraints(maxHeight: size.height * 0.34),
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
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModeTabs(),
          const SizedBox(height: 4),
          _mode == BackgroundMode.solid
              ? _buildHslControls()
              : _buildGradientCompact(),
        ],
      ),
    );
  }

  // Header removed for compact design

  Widget _buildModeTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _tab('Color', _mode == BackgroundMode.solid, () {
            setState(() => _mode = BackgroundMode.solid);
            // Apply current solid as live preview
            widget.onColorChanged(_selectedColor, _selectedOpacity);
          }),
          const SizedBox(width: 8),
          _tab('Gradient', _mode == BackgroundMode.gradient, () {
            setState(() => _mode = BackgroundMode.gradient);
            // Apply current gradient as live preview
            if (widget.onGradientChanged != null) {
              widget.onGradientChanged!(_gradient, _selectedOpacity);
            }
          }),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.black.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.15),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildColorGrid() {
    // Replaced by HSL sliders. Keep method for compatibility if referenced.
    return _buildHslControls();
  }

  Widget _buildHslControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _hueSlider(),
          const SizedBox(height: 8),
          _saturationSlider(),
          const SizedBox(height: 8),
          _lightnessSlider(),
        ],
      ),
    );
  }

  Widget _hueSlider() {
    final colors = [
      for (int i = 0; i <= 12; i++)
        HSLColor.fromAHSL(1.0, i * 30.0, 1.0, 0.5).toColor(),
    ];
    return _gradientLineSlider(
      label: 'H',
      valueLabel: '${_h.round()}°',
      colors: colors,
      min: 0,
      max: 360,
      value: _h,
      onChanged: (v) {
        setState(() => _h = v);
        _applyHslLive();
      },
    );
  }

  Widget _saturationSlider() {
    final c0 = HSLColor.fromAHSL(1.0, _h, 0.0, _l).toColor();
    final c1 = HSLColor.fromAHSL(1.0, _h, 1.0, _l).toColor();
    return _gradientLineSlider(
      label: 'S',
      valueLabel: '${(_s * 100).round()}%',
      colors: [c0, c1],
      min: 0,
      max: 1,
      value: _s,
      onChanged: (v) {
        setState(() => _s = v);
        _applyHslLive();
      },
    );
  }

  Widget _lightnessSlider() {
    final mid = HSLColor.fromAHSL(1.0, _h, _s, 0.5).toColor();
    return _gradientLineSlider(
      label: 'L',
      valueLabel: '${(_l * 100).round()}%',
      colors: [Colors.black, mid, Colors.white],
      min: 0,
      max: 1,
      value: _l,
      onChanged: (v) {
        setState(() => _l = v);
        _applyHslLive();
      },
    );
  }

  Widget _gradientLineSlider({
    required String label,
    required String valueLabel,
    required List<Color> colors,
    required double min,
    required double max,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(valueLabel, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(colors: colors),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                ),
                child: Slider(min: min, max: max, value: value, onChanged: onChanged),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _applyHslLive() {
    final c = HSLColor.fromAHSL(1.0, _h, _s, _l).toColor();
    _selectedColor = c;
    if (_mode == BackgroundMode.solid) {
      widget.onColorChanged(_selectedColor, _selectedOpacity);
    }
  }

  Widget _buildOpacitySlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact: remove label to save space
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
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
                      // Live preview: apply immediately without closing
                      if (_mode == BackgroundMode.solid) {
                        widget.onColorChanged(_selectedColor, _selectedOpacity);
                      } else if (widget.onGradientChanged != null) {
                        widget.onGradientChanged!(_gradient, _selectedOpacity);
                      }
                    },
                  ),
                ),
              ),
              Container(
                width: 52,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Text(
                    '${(_selectedOpacity * 100).round()}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedColorPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Text(
            'SELECTED COLOR',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 50,
            decoration: BoxDecoration(
              color: _selectedColor.withValues(alpha: _selectedOpacity),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
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

  Widget _buildGradientCompact() {
    return Column(
      children: [
        // Presets row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _gradientPresetChip(GradientSpec.presetPinkPurple()),
              _gradientPresetChip(GradientSpec.presetTealBlue()),
              _gradientPresetChip(GradientSpec.presetSunset()),
              _gradientPresetChip(GradientSpec.presetLime()),
            ],
          ),
        ),
        // Angle slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              const Text('ANGLE', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _gradient.angleDeg,
                  min: 0,
                  max: 360,
                  divisions: 36,
                  onChanged: (v) {
                    setState(() => _gradient = _gradient.copyWith(angleDeg: v));
                    if (widget.onGradientChanged != null) {
                      widget.onGradientChanged!(_gradient, _selectedOpacity);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gradientPresetChip(GradientSpec spec) {
    return GestureDetector(
      onTap: () {
        setState(() => _gradient = spec);
        if (widget.onGradientChanged != null) {
          widget.onGradientChanged!(spec, _selectedOpacity);
        }
      },
      child: Container(
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: spec.stops.map((s) => s.color).toList(),
            stops: spec.stops.map((s) => s.offset).toList(),
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
      ),
    );
  }
}
